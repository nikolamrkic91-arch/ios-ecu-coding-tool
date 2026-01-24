import Foundation

public enum ModuleRiskLevel: String, Codable {
    case low
    case medium
    case high
}

public struct ModuleIdentifier: Codable, Hashable {
    public let name: String          // e.g., FEM, BDC
    public let address: String       // e.g., 0xF020
    public let cafdVersion: String?  // e.g., CAFD_00004567_010_002_003

    public init(name: String, address: String, cafdVersion: String?) {
        self.name = name
        self.address = address
        self.cafdVersion = cafdVersion
    }
}

public struct Module: Codable, Identifiable {
    public var id: String { identifier.name }
    public let identifier: ModuleIdentifier
    public let risk: ModuleRiskLevel
    public let supportedOperations: [ModuleOperation]

    public init(identifier: ModuleIdentifier,
                risk: ModuleRiskLevel = .medium,
                supportedOperations: [ModuleOperation] = []) {
        self.identifier = identifier
        self.risk = risk
        self.supportedOperations = supportedOperations
    }
}

public enum ModuleOperation: String, Codable {
    case readDTC
    case clearDTC
    case readVO
    case writeVO
    case readFDL
    case writeFDL
}
