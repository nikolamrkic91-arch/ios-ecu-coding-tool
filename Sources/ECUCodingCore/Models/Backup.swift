import Foundation

public struct BackupMetadata: Codable {
    public let vin: String
    public let chassis: SupportedChassis
    public let istep: ISTEP?
    public let module: ModuleIdentifier
    public let cafdVersion: String?
    public let createdAt: Date
    public let checksum: String

    public init(vin: String,
                chassis: SupportedChassis,
                istep: ISTEP?,
                module: ModuleIdentifier,
                cafdVersion: String?,
                createdAt: Date = Date(),
                checksum: String) {
        self.vin = vin
        self.chassis = chassis
        self.istep = istep
        self.module = module
        self.cafdVersion = cafdVersion
        self.createdAt = createdAt
        self.checksum = checksum
    }
}

public struct BackupPayload: Codable {
    public let metadata: BackupMetadata
    public let data: Data   // raw NCD/CAFD or packed archive

    public init(metadata: BackupMetadata, data: Data) {
        self.metadata = metadata
        self.data = data
    }
}
