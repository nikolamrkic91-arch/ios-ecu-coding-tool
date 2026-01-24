import Foundation

/// Simulated transport for offline testing and development.
public final class SimulatedTransport: Transport {
    public private(set) var state: TransportState = .disconnected
    public let host: String = "simulated"
    public let port: UInt16 = 0

    private var responseDelay: TimeInterval
    private var simulatedResponses: [Data: Data]

    public init(responseDelay: TimeInterval = 0.05) {
        self.responseDelay = responseDelay
        self.simulatedResponses = [:]
        setupDefaultResponses()
    }

    private func setupDefaultResponses() {
        // Example: VIN request (0x22 0xF1 0x90) -> mock VIN response
        let vinRequest = Data([0x22, 0xF1, 0x90])
        let vinResponse = Data([0x62, 0xF1, 0x90]) + "WBAXXXXXXXX123456".data(using: .utf8)!
        simulatedResponses[vinRequest] = vinResponse

        // Example: Session control (0x10 0x01) -> positive response
        let sessionRequest = Data([0x10, 0x01])
        let sessionResponse = Data([0x50, 0x01])
        simulatedResponses[sessionRequest] = sessionResponse
    }

    public func connect() async throws {
        state = .connecting
        try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        state = .connected
    }

    public func disconnect() {
        state = .disconnected
    }

    public func roundTrip(_ payload: Data, timeout: TimeInterval) async throws -> Data {
        guard state == .connected else {
            throw TransportError.notConnected
        }

        try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))

        if let response = simulatedResponses[payload] {
            return response
        }

        // Default: echo back with positive response prefix
        return Data([0x7F]) + payload
    }

    public func setResponse(for request: Data, response: Data) {
        simulatedResponses[request] = response
    }
}
