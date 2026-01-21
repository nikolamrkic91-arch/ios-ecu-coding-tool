import Foundation

/// Session logging for audit trail and debugging
public final class SessionLogger {
    public static let shared = SessionLogger()
    
    private var currentSession: Session?
    private let dateFormatter: ISO8601DateFormatter
    
    private init() {
        self.dateFormatter = ISO8601DateFormatter()
    }
    
    /// Start a new diagnostic session
    public func startSession(vehicle: Vehicle?, transport: String) -> Session {
        let session = Session(
            id: UUID(),
            startTime: Date(),
            vehicle: vehicle,
            transport: transport
        )
        currentSession = session
        log(.info, "Session started: \(session.id)")
        return session
    }
    
    /// End the current session
    public func endSession() {
        guard let session = currentSession else { return }
        currentSession?.endTime = Date()
        log(.info, "Session ended: \(session.id)")
        currentSession = nil
    }
    
    /// Log an operation in the current session
    public func logOperation(_ operation: SessionOperation) {
        currentSession?.operations.append(operation)
        log(.info, "Operation: \(operation.type.rawValue) - \(operation.description)")
    }
    
    /// Log a message with level
    public func log(_ level: LogLevel, _ message: String) {
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] [\(level.rawValue)] \(message)")
    }
    
    /// Get current session
    public func getCurrentSession() -> Session? {
        return currentSession
    }
}

public struct Session: Codable {
    public let id: UUID
    public let startTime: Date
    public var endTime: Date?
    public let vehicle: Vehicle?
    public let transport: String
    public var operations: [SessionOperation]
    
    public init(id: UUID, startTime: Date, vehicle: Vehicle?, transport: String) {
        self.id = id
        self.startTime = startTime
        self.vehicle = vehicle
        self.transport = transport
        self.operations = []
    }
}

public struct SessionOperation: Codable {
    public let type: OperationType
    public let timestamp: Date
    public let description: String
    public let success: Bool
    public let details: [String: String]?
    
    public init(type: OperationType, timestamp: Date = Date(), description: String, success: Bool, details: [String: String]? = nil) {
        self.type = type
        self.timestamp = timestamp
        self.description = description
        self.success = success
        self.details = details
    }
}

public enum OperationType: String, Codable {
    case connect
    case disconnect
    case readVIN
    case readDTC
    case clearDTC
    case readVO
    case writeVO
    case readFDL
    case writeFDL
    case backup
    case restore
    case moduleScan
}

public enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}
