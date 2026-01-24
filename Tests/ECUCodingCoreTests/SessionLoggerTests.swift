import XCTest
@testable import ECUCodingCore

final class SessionLoggerTests: XCTestCase {
    
    func testStartSession() {
        let logger = SessionLogger.shared
        let vehicle = Vehicle(
            vin: "WBATEST123456789",
            chassis: .gSeries,
            istep: ISTEP(year: 2023, month: 7, patch: 1),
            options: []
        )
        
        let session = logger.startSession(vehicle: vehicle, transport: "SimulatedTransport")
        
        XCTAssertNotNil(session)
        XCTAssertEqual(session.vehicle?.vin, "WBATEST123456789")
        XCTAssertEqual(session.transport, "SimulatedTransport")
        XCTAssertEqual(session.operations.count, 0)
    }
    
    func testLogOperation() {
        let logger = SessionLogger.shared
        _ = logger.startSession(vehicle: nil, transport: "TestTransport")
        
        let operation = SessionOperation(
            type: .readDTC,
            description: "Read all DTCs",
            success: true
        )
        
        logger.logOperation(operation)
        
        let currentSession = logger.getCurrentSession()
        XCTAssertNotNil(currentSession)
        XCTAssertEqual(currentSession?.operations.count, 1)
        XCTAssertEqual(currentSession?.operations[0].type, .readDTC)
        XCTAssertTrue(currentSession?.operations[0].success ?? false)
        
        logger.endSession()
    }
    
    func testEndSession() {
        let logger = SessionLogger.shared
        _ = logger.startSession(vehicle: nil, transport: "TestTransport")
        
        logger.endSession()
        
        let currentSession = logger.getCurrentSession()
        XCTAssertNil(currentSession)
    }
}
