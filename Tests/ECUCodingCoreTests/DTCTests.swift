import XCTest
@testable import ECUCodingCore

final class DTCTests: XCTestCase {
    
    func testDTCParsing() {
        // Mock DTC data: P0420 with status 0x0F
        let data = Data([0x04, 0x20, 0x0F])
        let dtcs = DTC.parse(from: data)
        
        XCTAssertEqual(dtcs.count, 1)
        XCTAssertEqual(dtcs[0].code, "P0420")
        XCTAssertTrue(dtcs[0].status.isActive)
        XCTAssertTrue(dtcs[0].status.isStoredInMemory)
        XCTAssertEqual(dtcs[0].category, .powertrain)
    }
    
    func testMultipleDTCParsing() {
        // Two DTCs: P0420 and C1234
        let data = Data([
            0x04, 0x20, 0x0F,  // P0420
            0x51, 0x34, 0x08   // C1234
        ])
        let dtcs = DTC.parse(from: data)
        
        XCTAssertEqual(dtcs.count, 2)
        XCTAssertEqual(dtcs[0].code, "P0420")
        XCTAssertEqual(dtcs[1].code, "C5134")
        XCTAssertEqual(dtcs[0].category, .powertrain)
        XCTAssertEqual(dtcs[1].category, .chassis)
    }
    
    func testDTCStatus() {
        let activeStatus = DTCStatus(rawValue: 0x0F)
        XCTAssertTrue(activeStatus.isActive)
        XCTAssertTrue(activeStatus.isConfirmed)
        XCTAssertTrue(activeStatus.isPending)
        XCTAssertTrue(activeStatus.isStoredInMemory)
        
        let inactiveStatus = DTCStatus(rawValue: 0x00)
        XCTAssertFalse(inactiveStatus.isActive)
        XCTAssertFalse(inactiveStatus.isConfirmed)
        XCTAssertFalse(inactiveStatus.isPending)
        XCTAssertFalse(inactiveStatus.isStoredInMemory)
    }
    
    func testEmptyDTCData() {
        let emptyData = Data()
        let dtcs = DTC.parse(from: emptyData)
        XCTAssertEqual(dtcs.count, 0)
    }
    
    func testDTCCategories() {
        let powertrain = Data([0x04, 0x20, 0x00])
        let chassis = Data([0x51, 0x34, 0x00])
        let body = Data([0x90, 0x00, 0x00])
        let network = Data([0xD1, 0x00, 0x00])
        
        let powertrainDTC = DTC.parse(from: powertrain)[0]
        let chassisDTC = DTC.parse(from: chassis)[0]
        let bodyDTC = DTC.parse(from: body)[0]
        let networkDTC = DTC.parse(from: network)[0]
        
        XCTAssertEqual(powertrainDTC.category, .powertrain)
        XCTAssertEqual(chassisDTC.category, .chassis)
        XCTAssertEqual(bodyDTC.category, .body)
        XCTAssertEqual(networkDTC.category, .network)
    }
}
