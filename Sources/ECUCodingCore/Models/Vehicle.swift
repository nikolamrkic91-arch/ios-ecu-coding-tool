import Foundation

public enum SupportedChassis: String, Codable, CaseIterable {
    case fSeries = "F"
    case gSeries = "G"
    case iSeries = "I"
}

public struct ISTEP: Codable, Equatable {
    public let year: Int
    public let month: Int
    public let patch: Int

    public init(year: Int, month: Int, patch: Int) {
        self.year = year
        self.month = month
        self.patch = patch
    }

    public var asString: String { "\(year)-\(String(format: "%02d", month))-\(patch)" }
}

public struct Vehicle: Codable, Equatable, Identifiable {
    public var id: String { vin }
    public let vin: String
    public let chassis: SupportedChassis
    public let istep: ISTEP?
    public let options: [VOEntry]

    public init(vin: String, chassis: SupportedChassis, istep: ISTEP?, options: [VOEntry]) {
        self.vin = vin
        self.chassis = chassis
        self.istep = istep
        self.options = options
    }
}
