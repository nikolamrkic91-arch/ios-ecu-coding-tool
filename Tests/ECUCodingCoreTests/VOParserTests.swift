import XCTest
@testable import ECUCodingCore

final class VOParserTests: XCTestCase {
    
    func testParseVOString() {
        let voString = "5AR,6AC,423,2TB"
        let entries = VOParser.parse(voString: voString)
        
        XCTAssertEqual(entries.count, 4)
        XCTAssertEqual(entries[0].code, "5AR")
        XCTAssertEqual(entries[1].code, "6AC")
        XCTAssertEqual(entries[2].code, "423")
        XCTAssertEqual(entries[3].code, "2TB")
        
        // Check descriptions are populated
        XCTAssertNotNil(entries[0].description)
        XCTAssertEqual(entries[0].description, "Automatic Climate Control")
    }
    
    func testParseVOData() {
        let voString = "609,430,6WD"
        let voData = voString.data(using: .utf8)!
        let entries = VOParser.parse(voData: voData)
        
        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(entries[0].code, "609")
        XCTAssertEqual(entries[1].code, "430")
        XCTAssertEqual(entries[2].code, "6WD")
    }
    
    func testValidateCompatibleOption() {
        let entry = VOEntry(code: "5AR", description: "Automatic Climate Control")
        let chassis = SupportedChassis.gSeries
        let istep = ISTEP(year: 2021, month: 3, patch: 0)
        
        let result = VOParser.validate(entry: entry, chassis: chassis, istep: istep)
        
        switch result {
        case .valid:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected valid result")
        }
    }
    
    func testValidateIncompatibleChassis() {
        let entry = VOEntry(code: "6U3", description: "BMW Live Cockpit Professional")
        let chassis = SupportedChassis.fSeries  // Only for G/I series
        let istep = ISTEP(year: 2021, month: 3, patch: 0)
        
        let result = VOParser.validate(entry: entry, chassis: chassis, istep: istep)
        
        switch result {
        case .incompatible(let reason):
            XCTAssertTrue(reason.contains("not supported"))
        default:
            XCTFail("Expected incompatible result")
        }
    }
    
    func testValidateIncompatibleIStep() {
        let entry = VOEntry(code: "6WD", description: "Driving Assistant Professional")
        let chassis = SupportedChassis.gSeries
        let istep = ISTEP(year: 2019, month: 1, patch: 0)  // Too old
        
        let result = VOParser.validate(entry: entry, chassis: chassis, istep: istep)
        
        switch result {
        case .incompatible(let reason):
            XCTAssertTrue(reason.contains("I-step"))
        default:
            XCTFail("Expected incompatible result for old I-step")
        }
    }
    
    func testGetAffectedModules() {
        let entry = VOEntry(code: "5AR", description: "Automatic Climate Control")
        let modules = VOParser.getAffectedModules(for: entry)
        
        XCTAssertTrue(modules.contains("FEM"))
        XCTAssertTrue(modules.contains("BDC"))
        XCTAssertTrue(modules.contains("KOMBI"))
    }
    
    func testMergeVOChanges() {
        let current = [
            VOEntry(code: "5AR", description: "Automatic Climate Control"),
            VOEntry(code: "423", description: "M Sport Package")
        ]
        
        let changes = VOChange(
            add: [VOEntry(code: "6AC", description: "Navigation System")],
            remove: [VOEntry(code: "423", description: "M Sport Package")]
        )
        
        let result = VOParser.merge(current: current, changes: changes)
        
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains(where: { $0.code == "5AR" }))
        XCTAssertTrue(result.contains(where: { $0.code == "6AC" }))
        XCTAssertFalse(result.contains(where: { $0.code == "423" }))
    }
    
    func testParseEmptyString() {
        let voString = ""
        let entries = VOParser.parse(voString: voString)
        
        XCTAssertEqual(entries.count, 0)
    }
    
    func testParseWhitespace() {
        let voString = "  5AR  ,  6AC  ,  423  "
        let entries = VOParser.parse(voString: voString)
        
        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(entries[0].code, "5AR")
        XCTAssertEqual(entries[1].code, "6AC")
        XCTAssertEqual(entries[2].code, "423")
    }
}
