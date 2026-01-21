import Foundation

/// Diagnostic Trouble Code representation with OEM-like descriptions
public struct DTC: Codable, Hashable, Identifiable {
    public var id: String { code }
    
    public let code: String          // e.g., "P0420", "C1234"
    public let status: DTCStatus
    public let description: String   // OEM-like description
    public let category: DTCCategory
    public let module: String?       // Module that reported the DTC
    
    public init(code: String, status: DTCStatus, description: String, category: DTCCategory, module: String? = nil) {
        self.code = code
        self.status = status
        self.description = description
        self.category = category
        self.module = module
    }
    
    /// Parse DTC from UDS response data
    public static func parse(from data: Data) -> [DTC] {
        var dtcs: [DTC] = []
        
        // UDS DTC format: 3 bytes per DTC
        // Byte 0-1: DTC number (high byte, low byte)
        // Byte 2: Status byte
        guard data.count >= 3 else { return dtcs }
        
        var offset = 0
        while offset + 2 < data.count {
            let highByte = data[offset]
            let lowByte = data[offset + 1]
            let statusByte = data[offset + 2]
            
            // Convert to DTC code
            let dtcNumber = (UInt16(highByte) << 8) | UInt16(lowByte)
            let code = formatDTCCode(dtcNumber)
            
            let status = DTCStatus(rawValue: statusByte)
            let category = categorize(code: code)
            let description = describeDTC(code: code)
            
            let dtc = DTC(
                code: code,
                status: status,
                description: description,
                category: category
            )
            dtcs.append(dtc)
            
            offset += 3
        }
        
        return dtcs
    }
    
    /// Format DTC number as standard code (P0420, C1234, etc.)
    private static func formatDTCCode(_ dtcNumber: UInt16) -> String {
        let prefix: String
        let firstDigit = (dtcNumber >> 14) & 0x03
        
        switch firstDigit {
        case 0: prefix = "P" // Powertrain
        case 1: prefix = "C" // Chassis
        case 2: prefix = "B" // Body
        case 3: prefix = "U" // Network
        default: prefix = "P"
        }
        
        let number = dtcNumber & 0x3FFF
        return String(format: "%@%04X", prefix, number)
    }
    
    /// Categorize DTC by code prefix and pattern
    private static func categorize(code: String) -> DTCCategory {
        guard let firstChar = code.first else { return .other }
        
        switch firstChar {
        case "P": return .powertrain
        case "C": return .chassis
        case "B": return .body
        case "U": return .network
        default: return .other
        }
    }
    
    /// Get OEM-like description for DTC
    private static func describeDTC(code: String) -> String {
        // Common BMW DTC descriptions
        let descriptions: [String: String] = [
            "P0420": "Catalyst System Efficiency Below Threshold (Bank 1)",
            "P0171": "System Too Lean (Bank 1)",
            "P0172": "System Too Rich (Bank 1)",
            "P0300": "Random/Multiple Cylinder Misfire Detected",
            "C1234": "ABS Wheel Speed Sensor Circuit Malfunction",
            "B1000": "Electronic Control Module Memory Performance",
            "U0100": "Lost Communication with ECM/PCM",
            "U0101": "Lost Communication with TCM"
        ]
        
        return descriptions[code] ?? "Unknown DTC - \(code)"
    }
}

public struct DTCStatus: Codable, Hashable {
    public let rawValue: UInt8
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    public var isActive: Bool {
        (rawValue & 0x01) != 0
    }
    
    public var isStoredInMemory: Bool {
        (rawValue & 0x08) != 0
    }
    
    public var isPending: Bool {
        (rawValue & 0x04) != 0
    }
    
    public var isConfirmed: Bool {
        (rawValue & 0x02) != 0
    }
}

public enum DTCCategory: String, Codable {
    case powertrain = "Powertrain"
    case chassis = "Chassis"
    case body = "Body"
    case network = "Network"
    case other = "Other"
}
