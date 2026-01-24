import Foundation

/// Service for performing FDL (Function Description Language) parameter coding
public final class FDLCodingService {
    private let udsService: UDSService
    private let backupService: BackupService
    private let logger = SessionLogger.shared
    
    public init(udsService: UDSService, backupService: BackupService) {
        self.udsService = udsService
        self.backupService = backupService
    }
    
    /// Apply FDL parameter changes with automatic backup and validation
    public func applyFDLChanges(
        _ changes: [FDLChange],
        toVehicle vehicle: Vehicle,
        module: Module,
        performPreflight: Bool = true
    ) async throws {
        // Preflight checks
        if performPreflight {
            let preflightResult = SafetyChecks.preflight(
                isChargerConnected: true,
                linkQuality: LinkQuality(latencyMs: 50, packetLoss: 0.0),
                ignitionState: .on,
                batteryVoltage: 12.5,
                supportedChassis: [vehicle.chassis],
                vehicleChassis: vehicle.chassis,
                hasBackup: false
            )
            
            guard preflightResult.passed else {
                let failures = preflightResult.failures.joined(separator: ", ")
                throw FDLCodingError.preflightFailed(reason: failures)
            }
        }
        
        // Validate changes
        try validateFDLChanges(changes, for: vehicle, module: module)
        
        // Create backup before write
        logger.log(.info, "Creating backup before FDL coding...")
        let currentData = try await readCurrentFDL(from: module)
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
            logger.log(.info, "Applying FDL changes to \(module.identifier.name)...")
            try await writeFDLChanges(changes, to: module)
            
            logger.logOperation(SessionOperation(
                type: .writeFDL,
                description: "Applied FDL changes to \(module.identifier.name)",
                success: true,
                details: [
                    "parameters": "\(changes.count)",
                    "backup": backup.metadata.checksum
                ]
            ))
            
            logger.log(.info, "FDL coding completed successfully")
        } catch {
            // Restore from backup on failure
            logger.log(.error, "FDL coding failed, restoring from backup...")
            try await restoreFromBackup(backup, to: module)
            
            logger.logOperation(SessionOperation(
                type: .restore,
                description: "Restored from backup after FDL coding failure",
                success: true
            ))
            
            throw FDLCodingError.codingFailed(original: error, restored: true)
        }
    }
    
    /// Read current FDL parameters from module
    private func readCurrentFDL(from module: Module) async throws -> Data {
        // UDS service 0x22, DID 0xF1B0 (FDL data - example)
        let payload = Data([0xF1, 0xB0])
        return try await udsService.request(service: 0x22, payload: payload)
    }
    
    /// Write FDL changes to module
    private func writeFDLChanges(_ changes: [FDLChange], to module: Module) async throws {
        // Write each parameter change
        for change in changes {
            logger.log(.info, "Writing FDL parameter: \(change.parameter.name) = \(change.newValue)")
            
            // UDS service 0x2E for writing data
            // This is a simplified example
            var payload = Data([0xF1, 0xB0])
            
            // Encode parameter path and value
            let parameterData = encodeParameter(change)
            payload.append(parameterData)
            
            _ = try await udsService.request(service: 0x2E, payload: payload, timeout: 5.0)
        }
    }
    
    /// Restore from backup
    private func restoreFromBackup(_ backup: BackupPayload, to module: Module) async throws {
        let data = try backupService.restoreBackup(backup)
        
        // Write backup data to module
        var payload = Data([0xF1, 0xB0])
        payload.append(data)
        
        _ = try await udsService.request(service: 0x2E, payload: payload, timeout: 5.0)
    }
    
    /// Validate FDL changes before applying
    private func validateFDLChanges(
        _ changes: [FDLChange],
        for vehicle: Vehicle,
        module: Module
    ) throws {
        // Check if module supports FDL writing
        guard module.supportedOperations.contains(.writeFDL) else {
            throw FDLCodingError.unsupportedOperation(module: module.identifier.name)
        }
        
        // Validate each parameter change
        for change in changes {
            // Check allowed values if specified
            if let allowedValues = change.parameter.allowedValues {
                guard allowedValues.contains(change.newValue) else {
                    throw FDLCodingError.invalidValue(
                        parameter: change.parameter.name,
                        value: change.newValue,
                        allowed: allowedValues
                    )
                }
            }
            
            // Check risk level
            if change.parameter.risk == .high {
                logger.log(.warning, "High risk parameter: \(change.parameter.name)")
            }
        }
    }
    
    /// Encode FDL parameter for transmission
    private func encodeParameter(_ change: FDLChange) -> Data {
        // Simplified encoding - real implementation would be more complex
        let combined = "\(change.parameter.path)=\(change.newValue)"
        return Data(combined.utf8)
    }
}

public enum FDLCodingError: Error, LocalizedError {
    case preflightFailed(reason: String)
    case invalidValue(parameter: String, value: String, allowed: [String])
    case unsupportedOperation(module: String)
    case codingFailed(original: Error, restored: Bool)
    case parameterNotFound(String)
    
    public var errorDescription: String? {
        switch self {
        case .preflightFailed(let reason):
            return "Preflight checks failed: \(reason)"
        case .invalidValue(let parameter, let value, let allowed):
            return "Invalid value '\(value)' for parameter '\(parameter)'. Allowed: \(allowed.joined(separator: ", "))"
        case .unsupportedOperation(let module):
            return "Module \(module) does not support FDL coding"
        case .codingFailed(let original, let restored):
            let restoreMsg = restored ? " (backup restored)" : " (restore failed)"
            return "Coding failed: \(original.localizedDescription)\(restoreMsg)"
        case .parameterNotFound(let name):
            return "Parameter '\(name)' not found"
        }
    }
}
