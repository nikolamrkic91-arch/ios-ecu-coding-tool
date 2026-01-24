import XCTest
@testable import ECUCodingCore

final class DiagnosticServiceTests: XCTestCase {
    
    func testReadDTCs() async throws {
        let transport = SimulatedTransport()
        let uds = UDSService(transport: transport)
        let diagnostic = DiagnosticService(udsService: uds)
        
        // Set up simulated response for DTC read
        let request = Data([0x19, 0x02, 0xFF])
        // Response: sub-function echo, availability mask, then DTC data
        let response = Data([0x02, 0xFF, 0x04, 0x20, 0x0F])
        transport.setResponse(for: request, response: Data([0x59]) + response)
        
        try await transport.connect()
        let dtcs = try await diagnostic.readDTCs()
        
        XCTAssertEqual(dtcs.count, 1)
        XCTAssertEqual(dtcs[0].code, "P0420")
    }
    
    func testGetDTCCount() async throws {
        let transport = SimulatedTransport()
        let uds = UDSService(transport: transport)
        let diagnostic = DiagnosticService(udsService: uds)
        
        // Set up simulated response for DTC count
        let request = Data([0x19, 0x01, 0xFF])
        // Response: sub-function echo, status mask, count high, count low
        let response = Data([0x01, 0xFF, 0x00, 0x03])  // 3 DTCs
        transport.setResponse(for: request, response: Data([0x59]) + response)
        
        try await transport.connect()
        let count = try await diagnostic.getDTCCount()
        
        XCTAssertEqual(count, 3)
    }
}
