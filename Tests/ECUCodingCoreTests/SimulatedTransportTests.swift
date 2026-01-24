import XCTest
@testable import ECUCodingCore

final class SimulatedTransportTests: XCTestCase {
    
    func testInitialState() {
        let transport = SimulatedTransport()
        XCTAssertEqual(transport.state, .disconnected)
        XCTAssertEqual(transport.host, "simulated")
        XCTAssertEqual(transport.port, 0)
    }
    
    func testConnect() async throws {
        let transport = SimulatedTransport(responseDelay: 0.01)
        XCTAssertEqual(transport.state, .disconnected)
        
        try await transport.connect()
        XCTAssertEqual(transport.state, .connected)
    }
    
    func testDisconnect() async throws {
        let transport = SimulatedTransport(responseDelay: 0.01)
        try await transport.connect()
        XCTAssertEqual(transport.state, .connected)
        
        transport.disconnect()
        XCTAssertEqual(transport.state, .disconnected)
    }
    
    func testRoundTripWithPredefinedResponse() async throws {
        let transport = SimulatedTransport(responseDelay: 0.01)
        try await transport.connect()
        
        // Test VIN request
        let vinRequest = Data([0x22, 0xF1, 0x90])
        let response = try await transport.roundTrip(vinRequest, timeout: 1.0)
        
        XCTAssertFalse(response.isEmpty)
        XCTAssertEqual(response[0], 0x62) // Positive response
        XCTAssertEqual(response[1], 0xF1)
        XCTAssertEqual(response[2], 0x90)
    }
    
    func testRoundTripWithCustomResponse() async throws {
        let transport = SimulatedTransport(responseDelay: 0.01)
        try await transport.connect()
        
        let customRequest = Data([0x11, 0x22, 0x33])
        let customResponse = Data([0xAA, 0xBB, 0xCC])
        transport.setResponse(for: customRequest, response: customResponse)
        
        let response = try await transport.roundTrip(customRequest, timeout: 1.0)
        XCTAssertEqual(response, customResponse)
    }
    
    func testRoundTripNotConnected() async {
        let transport = SimulatedTransport(responseDelay: 0.01)
        
        do {
            _ = try await transport.roundTrip(Data([0x10, 0x01]), timeout: 1.0)
            XCTFail("Should throw notConnected error")
        } catch TransportError.notConnected {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
