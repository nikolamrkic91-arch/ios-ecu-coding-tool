import XCTest
@testable import ECUCodingCore

final class PlaceholderTests: XCTestCase {
    
    func testNamespaceExists() {
        // Verify that the ECUCodingCore namespace exists
        XCTAssertNotNil(ECUCodingCore.self)
    }
}
