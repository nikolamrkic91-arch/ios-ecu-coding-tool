import Foundation

public enum FDLValueType: Codable {
    case enumeration
    case boolean
    case integer
    case float
    case string
}

public struct FDLParameter: Codable, Hashable {
    public let path: String          // hierarchical path in NCD/CAFD
    public let name: String
    public let type: FDLValueType
    public let allowedValues: [String]?
    public let risk: ModuleRiskLevel

    public init(path: String,
                name: String,
                type: FDLValueType,
                allowedValues: [String]? = nil,
                risk: ModuleRiskLevel = .medium) {
        self.path = path
        self.name = name
        self.type = type
        self.allowedValues = allowedValues
        self.risk = risk
    }
}

public struct FDLChange: Codable {
    public let parameter: FDLParameter
    public let newValue: String
    public let oldValue: String?

    public init(parameter: FDLParameter, newValue: String, oldValue: String? = nil) {
        self.parameter = parameter
        self.newValue = newValue
        self.oldValue = oldValue
    }
}
