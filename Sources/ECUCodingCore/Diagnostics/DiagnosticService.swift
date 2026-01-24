import Foundation

/// Service for managing diagnostic operations including DTC reading and clearing
public final class DiagnosticService {
    private let udsService: UDSService
    
    public init(udsService: UDSService) {
        self.udsService = udsService
    }
    
    /// Read all DTCs from the ECU
    public func readDTCs() async throws -> [DTC] {
        // UDS service 0x19 - Read DTC Information
        // Sub-function 0x02 - Report DTC by status mask (all DTCs)
        let payload = Data([0x02, 0xFF])  // 0xFF = all DTCs
        let response = try await udsService.request(service: 0x19, payload: payload)
        
        // Skip sub-function echo and availability mask
        guard response.count > 2 else {
            return []
        }
        
        let dtcData = response.dropFirst(2)
        return DTC.parse(from: dtcData)
    }
    
    /// Read DTCs by specific status mask
    public func readDTCs(statusMask: UInt8) async throws -> [DTC] {
        let payload = Data([0x02, statusMask])
        let response = try await udsService.request(service: 0x19, payload: payload)
        
        guard response.count > 2 else {
            return []
        }
        
        let dtcData = response.dropFirst(2)
        return DTC.parse(from: dtcData)
    }
    
    /// Clear all DTCs
    public func clearAllDTCs() async throws {
        try await udsService.clearDTC()
    }
    
    /// Get DTC count without reading all details
    public func getDTCCount() async throws -> Int {
        // UDS service 0x19 sub-function 0x01 - Report Number of DTC by Status Mask
        let payload = Data([0x01, 0xFF])
        let response = try await udsService.request(service: 0x19, payload: payload)
        
        guard response.count >= 4 else {
            throw DiagnosticError.invalidResponse
        }
        
        // Bytes 2-3 contain the DTC count
        let count = (Int(response[2]) << 8) | Int(response[3])
        return count
    }
}

public enum DiagnosticError: Error, LocalizedError {
    case invalidResponse
    case unsupportedOperation
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid diagnostic response from ECU"
        case .unsupportedOperation:
            return "Diagnostic operation not supported by this ECU"
        }
    }
}
