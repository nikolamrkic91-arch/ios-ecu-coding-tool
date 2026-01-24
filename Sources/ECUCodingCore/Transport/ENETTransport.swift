import Foundation
#if canImport(Network)
import Network
#endif

/// ENET transport over TCP (common for Wi-Fi ENET adapters).
public final class ENETTransport: Transport {
    public private(set) var state: TransportState = .disconnected
    public let host: String
    public let port: UInt16

    #if canImport(Network)
    private var connection: NWConnection?
    #endif

    public init(host: String, port: UInt16 = 6801) {
        self.host = host
        self.port = port
    }

    public func connect() async throws {
        #if canImport(Network)
        state = .connecting
        let nwHost = NWEndpoint.Host(host)
        let nwPort = NWEndpoint.Port(rawValue: port) ?? 6801
        let params = NWParameters.tcp
        let conn = NWConnection(host: nwHost, port: nwPort, using: params)
        connection = conn

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            conn.stateUpdateHandler = { [weak self] newState in
                switch newState {
                case .ready:
                    self?.state = .connected
                    cont.resume()
                case .failed(let error):
                    self?.state = .failed(error)
                    cont.resume(throwing: TransportError.underlying(error))
                case .waiting(let error):
                    self?.state = .failed(error)
                    cont.resume(throwing: TransportError.underlying(error))
                default:
                    break
                }
            }
            conn.start(queue: .global())
        }
        #else
        throw TransportError.underlying(NSError(domain: "ENETTransport", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network framework not available"]))
        #endif
    }

    public func disconnect() {
        #if canImport(Network)
        connection?.cancel()
        connection = nil
        #endif
        state = .disconnected
    }

    public func roundTrip(_ payload: Data, timeout: TimeInterval) async throws -> Data {
        #if canImport(Network)
        guard state == .connected, let conn = connection else {
            throw TransportError.notConnected
        }

        // Send
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            conn.send(content: payload, completion: .contentProcessed { error in
                if let error = error {
                    cont.resume(throwing: TransportError.underlying(error))
                } else {
                    cont.resume()
                }
            })
        }

        // Receive with timeout
        return try await withThrowingTaskGroup(of: Data.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Data, Error>) in
                    conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
                        if let error = error {
                            cont.resume(throwing: TransportError.underlying(error))
                        } else if let data = data {
                            cont.resume(returning: data)
                        } else {
                            cont.resume(throwing: TransportError.invalidResponse)
                        }
                    }
                }
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TransportError.timedOut
            }

            guard let result = try await group.next() else {
                throw TransportError.invalidResponse
            }
            group.cancelAll()
            return result
        }
        #else
        throw TransportError.underlying(NSError(domain: "ENETTransport", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network framework not available"]))
        #endif
    }
}
