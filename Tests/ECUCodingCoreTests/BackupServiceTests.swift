import XCTest
@testable import ECUCodingCore

final class BackupServiceTests: XCTestCase {
    var backupService: BackupService!
    var tempURL: URL!
    
    override func setUp() {
        super.setUp()
        // Use temporary directory for tests
        tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        backupService = BackupService(storageURL: tempURL)
    }
    
    override func tearDown() {
        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
        super.tearDown()
    }
    
    func testCreateBackup() throws {
        let vin = "WBATEST123456789"
        let chassis = SupportedChassis.gSeries
        let istep = ISTEP(year: 2023, month: 7, patch: 1)
        let module = ModuleIdentifier(name: "FEM", address: "0x32", cafdVersion: nil)
        let testData = Data("Test backup data".utf8)
        
        let backup = try backupService.createBackup(
            vin: vin,
            chassis: chassis,
            istep: istep,
            module: module,
            data: testData
        )
        
        XCTAssertEqual(backup.metadata.vin, vin)
        XCTAssertEqual(backup.metadata.chassis, chassis)
        XCTAssertEqual(backup.data, testData)
        XCTAssertFalse(backup.metadata.checksum.isEmpty)
    }
    
    func testRestoreBackup() throws {
        let vin = "WBATEST123456789"
        let chassis = SupportedChassis.gSeries
        let module = ModuleIdentifier(name: "FEM", address: "0x32", cafdVersion: nil)
        let testData = Data("Test backup data".utf8)
        
        let backup = try backupService.createBackup(
            vin: vin,
            chassis: chassis,
            istep: nil,
            module: module,
            data: testData
        )
        
        let restoredData = try backupService.restoreBackup(backup)
        XCTAssertEqual(restoredData, testData)
    }
    
    func testListBackups() throws {
        let vin1 = "WBATEST123456789"
        let vin2 = "WBATEST987654321"
        let chassis = SupportedChassis.gSeries
        let module = ModuleIdentifier(name: "FEM", address: "0x32", cafdVersion: nil)
        
        _ = try backupService.createBackup(
            vin: vin1,
            chassis: chassis,
            istep: nil,
            module: module,
            data: Data("Data 1".utf8)
        )
        
        _ = try backupService.createBackup(
            vin: vin2,
            chassis: chassis,
            istep: nil,
            module: module,
            data: Data("Data 2".utf8)
        )
        
        let backupsForVin1 = try backupService.listBackups(forVIN: vin1)
        XCTAssertEqual(backupsForVin1.count, 1)
        XCTAssertEqual(backupsForVin1[0].metadata.vin, vin1)
    }
    
    func testGetLatestBackup() throws {
        let vin = "WBATEST123456789"
        let chassis = SupportedChassis.gSeries
        let module = ModuleIdentifier(name: "FEM", address: "0x32", cafdVersion: nil)
        
        _ = try backupService.createBackup(
            vin: vin,
            chassis: chassis,
            istep: nil,
            module: module,
            data: Data("Data 1".utf8)
        )
        
        // Small delay to ensure different timestamps
        Thread.sleep(forTimeInterval: 0.1)
        
        _ = try backupService.createBackup(
            vin: vin,
            chassis: chassis,
            istep: nil,
            module: module,
            data: Data("Data 2".utf8)
        )
        
        let latest = try backupService.getLatestBackup(forVIN: vin, module: module)
        XCTAssertNotNil(latest)
        XCTAssertEqual(latest?.data, Data("Data 2".utf8))
    }
    
    func testChecksumVerification() throws {
        let vin = "WBATEST123456789"
        let chassis = SupportedChassis.gSeries
        let module = ModuleIdentifier(name: "FEM", address: "0x32", cafdVersion: nil)
        let testData = Data("Test data".utf8)
        
        var backup = try backupService.createBackup(
            vin: vin,
            chassis: chassis,
            istep: nil,
            module: module,
            data: testData
        )
        
        // Corrupt the data
        backup = BackupPayload(
            metadata: backup.metadata,
            data: Data("Corrupted data".utf8)
        )
        
        XCTAssertThrowsError(try backupService.restoreBackup(backup)) { error in
            XCTAssertTrue(error is BackupError)
            if case BackupError.checksumMismatch = error {
                // Expected error
            } else {
                XCTFail("Expected checksumMismatch error")
            }
        }
    }
}
