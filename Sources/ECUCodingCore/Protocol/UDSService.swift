import Foundation

/// UDS (Unified Diagnostic Services) protocol implementation.
public final class UDSService {
    private let transport: Transport
    private let defaultTimeout: TimeInterval

    public init(transport: Transport, defaultTimeout: TimeInterval = 2.0) {
        self.transport = transport
        self.defaultTimeout = defaultTimeout
    }

    /// Send a UDS request and return the response payload.
    public func request(service: UInt8, payload: Data, timeout: TimeInterval? = nil) async throws -> Data {
        var fullPayload = Data([service])
        fullPayload.append(payload)

        let response = try await transport.roundTrip(fullPayload, timeout: timeout ?? defaultTimeout)

        // Basic UDS response validation
        guard !response.isEmpty else {
            throw UDSError.emptyResponse
        }

        // Check for negative response (0x7F)
        if response[0] == 0x7F {
            let serviceId = response.count > 1 ? response[1] : 0x00
            let nrc = response.count > 2 ? response[2] : 0x00
            throw UDSError.negativeResponse(service: serviceId, nrc: nrc)
        }

        // Check for positive response (service ID + 0x40)
        guard response[0] == service + 0x40 else {
            throw UDSError.invalidResponse
        }

        // Return payload without service ID
        return response.dropFirst()
    }

    /// Start a diagnostic session.
    public func startSession(_ sessionType: UInt8 = 0x01) async throws {
        _ = try await request(service: 0x10, payload: Data([sessionType]))
    }

    /// Read data by identifier (e.g., VIN, software version).
    public func readDataByIdentifier(_ did: UInt16) async throws -> Data {
        let didBytes = Data([UInt8(did >> 8), UInt8(did & 0xFF)])
        return try await request(service: 0x22, payload: didBytes)
    }

    /// Clear diagnostic trouble codes.
    public func clearDTC(group: UInt32 = 0xFFFFFF) async throws {
        let groupBytes = Data([
            UInt8((group >> 16) & 0xFF),
            UInt8((group >> 8) & 0xFF),
            UInt8(group & 0xFF)
        ])
        _ = try await request(service: 0x14, payload: groupBytes)
    }
}

public enum UDSError: Error, LocalizedError {
    case emptyResponse
    case invalidResponse
    case negativeResponse(service: UInt8, nrc: UInt8)
    case transportError(Error)

    public var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "Empty response from ECU"
        case .invalidResponse:
            return "Invalid UDS response format"
        case .negativeResponse(let service, let nrc):
            return "Negative response for service 0x\(String(format: "%02X", service)), NRC: 0x\(String(format: "%02X", nrc))"
        case .transportError(let error):
            return "Transport error: \(error.localizedDescription)"
        }
    }
}
