import Foundation

public enum TransportState: Equatable {
    case disconnected
    case connecting
    case connected
    case failed(Error)

    public static func == (lhs: TransportState, rhs: TransportState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected), (.connecting, .connecting), (.connected, .connected):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

public protocol Transport {
    var state: TransportState { get }
    var host: String { get }
    var port: UInt16 { get }

    func connect() async throws
    func disconnect()
    func roundTrip(_ payload: Data, timeout: TimeInterval) async throws -> Data
}

public enum TransportError: Error {
    case notConnected
    case timedOut
    case underlying(Error)
    case invalidResponse
}
