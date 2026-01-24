import Foundation

/// Service for creating and managing ECU backups
public final class BackupService {
    private let storageURL: URL
    
    public init(storageURL: URL? = nil) {
        if let storageURL = storageURL {
            self.storageURL = storageURL
        } else {
            // Default to Documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            self.storageURL = documentsPath.appendingPathComponent("ECUBackups")
        }
        
        // Create storage directory if it doesn't exist
        try? FileManager.default.createDirectory(at: self.storageURL, withIntermediateDirectories: true)
    }
    
    /// Create a backup of module data
    public func createBackup(
        vin: String,
        chassis: SupportedChassis,
        istep: ISTEP?,
        module: ModuleIdentifier,
        data: Data
    ) throws -> BackupPayload {
        // Calculate checksum
        let checksum = calculateChecksum(data)
        
        let metadata = BackupMetadata(
            vin: vin,
            chassis: chassis,
            istep: istep,
            module: module,
            cafdVersion: module.cafdVersion,
            createdAt: Date(),
            checksum: checksum
        )
        
        let backup = BackupPayload(metadata: metadata, data: data)
        
        // Save to storage
        try saveBackup(backup)
        
        return backup
    }
    
    /// Restore from a backup
    public func restoreBackup(_ backup: BackupPayload) throws -> Data {
        // Verify integrity
        let calculatedChecksum = calculateChecksum(backup.data)
        guard calculatedChecksum == backup.metadata.checksum else {
            throw BackupError.checksumMismatch
        }
        
        return backup.data
    }
    
    /// List all backups for a vehicle
    public func listBackups(forVIN vin: String) throws -> [BackupPayload] {
        let backups = try loadAllBackups()
        return backups.filter { $0.metadata.vin == vin }
    }
    
    /// Get latest backup for a specific module
    public func getLatestBackup(
        forVIN vin: String,
        module: ModuleIdentifier
    ) throws -> BackupPayload? {
        let backups = try listBackups(forVIN: vin)
        return backups
            .filter { $0.metadata.module.name == module.name }
            .sorted { $0.metadata.createdAt > $1.metadata.createdAt }
            .first
    }
    
    /// Delete a backup
    public func deleteBackup(_ backup: BackupPayload) throws {
        let filename = backupFilename(backup.metadata)
        let fileURL = storageURL.appendingPathComponent(filename)
        try FileManager.default.removeItem(at: fileURL)
    }
    
    /// Export backup to external file
    public func exportBackup(_ backup: BackupPayload, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(backup)
        try data.write(to: url)
    }
    
    /// Import backup from external file
    public func importBackup(from url: URL) throws -> BackupPayload {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let backup = try decoder.decode(BackupPayload.self, from: data)
        
        // Verify integrity
        _ = try restoreBackup(backup)
        
        // Save to storage
        try saveBackup(backup)
        
        return backup
    }
    
    // MARK: - Private Helpers
    
    private func saveBackup(_ backup: BackupPayload) throws {
        let filename = backupFilename(backup.metadata)
        let fileURL = storageURL.appendingPathComponent(filename)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(backup)
        try data.write(to: fileURL)
    }
    
    private func loadAllBackups() throws -> [BackupPayload] {
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: storageURL,
            includingPropertiesForKeys: nil
        )
        
        var backups: [BackupPayload] = []
        let decoder = JSONDecoder()
        
        for fileURL in fileURLs where fileURL.pathExtension == "backup" {
            if let data = try? Data(contentsOf: fileURL),
               let backup = try? decoder.decode(BackupPayload.self, from: data) {
                backups.append(backup)
            }
        }
        
        return backups
    }
    
    private func backupFilename(_ metadata: BackupMetadata) -> String {
        let dateFormatter = ISO8601DateFormatter()
        let timestamp = dateFormatter.string(from: metadata.createdAt)
        return "\(metadata.vin)_\(metadata.module.name)_\(timestamp).backup"
    }
    
    private func calculateChecksum(_ data: Data) -> String {
        // Simple hash function compatible with all platforms
        var hash: UInt64 = 5381
        for byte in data {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        return String(format: "%016llx", hash)
    }
}

public enum BackupError: Error, LocalizedError {
    case checksumMismatch
    case backupNotFound
    case invalidBackupData
    case storageError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .checksumMismatch:
            return "Backup integrity check failed - checksum mismatch"
        case .backupNotFound:
            return "Backup not found"
        case .invalidBackupData:
            return "Invalid backup data format"
        case .storageError(let error):
            return "Storage error: \(error.localizedDescription)"
        }
    }
}
