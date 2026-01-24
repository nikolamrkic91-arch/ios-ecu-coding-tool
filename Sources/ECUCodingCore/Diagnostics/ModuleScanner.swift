import Foundation

/// Service for scanning and detecting vehicle modules
public final class ModuleScanner {
    private let udsService: UDSService
    
    // Common BMW module addresses
    private static let commonModuleAddresses: [String: String] = [
        "0x00": "ZGW (Central Gateway)",
        "0x08": "SZL (Steering Column Switch Cluster)",
        "0x10": "DME (Engine Control)",
        "0x12": "EGS (Transmission Control)",
        "0x18": "CAS (Car Access System)",
        "0x28": "IHKA (Climate Control)",
        "0x32": "FEM (Front Electronic Module)",
        "0x36": "BDC (Body Domain Controller)",
        "0x50": "KOM (Instrument Cluster)",
        "0x60": "KOMBI (Combined Instrument)",
        "0x68": "CID (Central Information Display)",
        "0x6F": "HU (Head Unit)",
        "0x80": "DSC (Dynamic Stability Control)",
        "0xA0": "TPMS (Tire Pressure Monitoring)",
        "0xB8": "PDC (Park Distance Control)"
    ]
    
    public init(udsService: UDSService) {
        self.udsService = udsService
    }
    
    /// Scan for all responsive modules on the vehicle
    public func scanModules() async -> [Module] {
        var modules: [Module] = []
        
        for (address, name) in Self.commonModuleAddresses {
            if let module = await probeModule(address: address, name: name) {
                modules.append(module)
            }
        }
        
        return modules
    }
    
    /// Probe a specific module address to check if it responds
    private func probeModule(address: String, name: String) async -> Module? {
        do {
            // Try to read identification from module
            // Service 0x22, DID 0xF187 (VIN or module ID)
            let payload = Data([0xF1, 0x87])
            _ = try await udsService.request(service: 0x22, payload: payload, timeout: 0.5)
            
            // Module responded, create module entry
            let identifier = ModuleIdentifier(
                name: name,
                address: address,
                cafdVersion: nil
            )
            
            let module = Module(
                identifier: identifier,
                risk: determineRisk(for: name),
                supportedOperations: determineSupportedOperations(for: name)
            )
            
            return module
        } catch {
            // Module didn't respond or error occurred
            return nil
        }
    }
    
    /// Read detailed information from a specific module
    public func readModuleInfo(address: String) async throws -> ModuleInfo {
        // Read various DIDs for module information
        let vinData = try? await udsService.readDataByIdentifier(0xF190)
        let swVersion = try? await udsService.readDataByIdentifier(0xF189)
        let hwVersion = try? await udsService.readDataByIdentifier(0xF191)
        
        return ModuleInfo(
            address: address,
            vin: vinData.flatMap { String(data: $0, encoding: .utf8) },
            softwareVersion: swVersion.flatMap { String(data: $0, encoding: .utf8) },
            hardwareVersion: hwVersion.flatMap { String(data: $0, encoding: .utf8) }
        )
    }
    
    private func determineRisk(for moduleName: String) -> ModuleRiskLevel {
        let highRiskModules = ["DME", "EGS", "CAS", "ZGW"]
        let lowRiskModules = ["IHKA", "PDC", "TPMS", "CID", "HU"]
        
        if highRiskModules.contains(where: { moduleName.contains($0) }) {
            return .high
        } else if lowRiskModules.contains(where: { moduleName.contains($0) }) {
            return .low
        }
        return .medium
    }
    
    private func determineSupportedOperations(for moduleName: String) -> [ModuleOperation] {
        // All modules support basic diagnostics
        var operations: [ModuleOperation] = [.readDTC, .clearDTC]
        
        // Most modules support VO reading
        operations.append(.readVO)
        
        // Only certain modules support writing operations
        let writeableModules = ["FEM", "BDC", "KOMBI", "CID"]
        if writeableModules.contains(where: { moduleName.contains($0) }) {
            operations.append(.writeVO)
            operations.append(.readFDL)
            operations.append(.writeFDL)
        }
        
        return operations
    }
}

public struct ModuleInfo: Codable {
    public let address: String
    public let vin: String?
    public let softwareVersion: String?
    public let hardwareVersion: String?
    
    public init(address: String, vin: String?, softwareVersion: String?, hardwareVersion: String?) {
        self.address = address
        self.vin = vin
        self.softwareVersion = softwareVersion
        self.hardwareVersion = hardwareVersion
    }
}
