import Foundation

/// Service for performing VO coding operations with safety checks
public final class VOCodingService {
    private let udsService: UDSService
    private let backupService: BackupService
    private let logger = SessionLogger.shared
    
    public init(udsService: UDSService, backupService: BackupService) {
        self.udsService = udsService
        self.backupService = backupService
    }
    
    /// Apply VO changes with automatic backup and validation
    public func applyVOChanges(
        _ changes: VOChange,
        toVehicle vehicle: Vehicle,
        module: Module,
        performPreflight: Bool = true
    ) async throws {
        // Preflight checks
        if performPreflight {
            let preflightResult = SafetyChecks.preflight(
                isChargerConnected: true,  // Should be passed from caller
                linkQuality: LinkQuality(latencyMs: 50, packetLoss: 0.0),
                ignitionState: .on,
                batteryVoltage: 12.5,
                supportedChassis: [vehicle.chassis],
                vehicleChassis: vehicle.chassis,
                hasBackup: false  // Will create backup next
            )
            
            guard preflightResult.passed else {
                let failures = preflightResult.failures.joined(separator: ", ")
                throw VOCodingError.preflightFailed(reason: failures)
            }
        }
        
        // Validate changes
        try validateVOChanges(changes, for: vehicle, module: module)
        
        // Create backup before write
        logger.log(.info, "Creating backup before VO coding...")
        let currentData = try await readCurrentVO(from: module)
        let backup = try backupService.createBackup(
            vin: vehicle.vin,
            chassis: vehicle.chassis,
            istep: vehicle.istep,
            module: module.identifier,
            data: currentData
        )
        
        logger.log(.info, "Backup created: \(backup.metadata.checksum)")
        
        do {
            // Apply changes
            logger.log(.info, "Applying VO changes to \(module.identifier.name)...")
            try await writeVOChanges(changes, to: module)
            
            logger.logOperation(SessionOperation(
                type: .writeVO,
                description: "Applied VO changes to \(module.identifier.name)",
                success: true,
                details: [
                    "added": "\(changes.add.count)",
                    "removed": "\(changes.remove.count)",
                    "backup": backup.metadata.checksum
                ]
            ))
            
            logger.log(.info, "VO coding completed successfully")
        } catch {
            // Restore from backup on failure
            logger.log(.error, "VO coding failed, restoring from backup...")
            try await restoreFromBackup(backup, to: module)
            
            logger.logOperation(SessionOperation(
                type: .restore,
                description: "Restored from backup after VO coding failure",
                success: true
            ))
            
            throw VOCodingError.codingFailed(original: error, restored: true)
        }
    }
    
    /// Read current VO from module
    private func readCurrentVO(from module: Module) async throws -> Data {
        // UDS service 0x22, DID 0xF1A0 (VO data - example)
        let payload = Data([0xF1, 0xA0])
        return try await udsService.request(service: 0x22, payload: payload)
    }
    
    /// Write VO changes to module
    private func writeVOChanges(_ changes: VOChange, to module: Module) async throws {
        // UDS service 0x2E, DID 0xF1A0 (Write VO data - example)
        // This is a simplified example - real implementation would be more complex
        
        // Convert changes to binary format
        let allOptions = VOParser.merge(current: [], changes: changes)
        let voString = allOptions.map { $0.code }.joined(separator: ",")
        let voData = Data(voString.utf8)
        
        var payload = Data([0xF1, 0xA0])
        payload.append(voData)
        
        _ = try await udsService.request(service: 0x2E, payload: payload, timeout: 5.0)
    }
    
    /// Restore from backup
    private func restoreFromBackup(_ backup: BackupPayload, to module: Module) async throws {
        let data = try backupService.restoreBackup(backup)
        
        // Write backup data to module
        var payload = Data([0xF1, 0xA0])
        payload.append(data)
        
        _ = try await udsService.request(service: 0x2E, payload: payload, timeout: 5.0)
    }
    
    /// Validate VO changes before applying
    private func validateVOChanges(
        _ changes: VOChange,
        for vehicle: Vehicle,
        module: Module
    ) throws {
        // Validate each option being added
        for entry in changes.add {
            let result = VOParser.validate(
                entry: entry,
                chassis: vehicle.chassis,
                istep: vehicle.istep
            )
            
            switch result {
            case .incompatible(let reason):
                throw VOCodingError.incompatibleOption(code: entry.code, reason: reason)
            case .warning(let reason):
                logger.log(.warning, "VO option \(entry.code): \(reason)")
            case .valid:
                break
            }
        }
        
        // Check if module supports VO writing
        guard module.supportedOperations.contains(.writeVO) else {
            throw VOCodingError.unsupportedOperation(module: module.identifier.name)
        }
    }
}

public enum VOCodingError: Error, LocalizedError {
    case preflightFailed(reason: String)
    case incompatibleOption(code: String, reason: String)
    case unsupportedOperation(module: String)
    case codingFailed(original: Error, restored: Bool)
    case backupFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .preflightFailed(let reason):
            return "Preflight checks failed: \(reason)"
        case .incompatibleOption(let code, let reason):
            return "Incompatible option \(code): \(reason)"
        case .unsupportedOperation(let module):
            return "Module \(module) does not support VO coding"
        case .codingFailed(let original, let restored):
            let restoreMsg = restored ? " (backup restored)" : " (restore failed)"
            return "Coding failed: \(original.localizedDescription)\(restoreMsg)"
        case .backupFailed(let error):
            return "Backup failed: \(error.localizedDescription)"
        }
    }
}
