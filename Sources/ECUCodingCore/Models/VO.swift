import Foundation

public struct VOEntry: Codable, Hashable {
    public let code: String   // e.g., 5AR
    public let description: String?

    public init(code: String, description: String? = nil) {
        self.code = code
        self.description = description
    }
}

public struct VOChange: Codable {
    public let add: [VOEntry]
    public let remove: [VOEntry]

    public init(add: [VOEntry] = [], remove: [VOEntry] = []) {
        self.add = add
        self.remove = remove
    }
}
