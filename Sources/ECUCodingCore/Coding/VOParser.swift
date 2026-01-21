import Foundation

/// Parser and validator for BMW VO (Vehicle Order) and FA (Factory Assembly) codes
public final class VOParser {
    
    /// Parse VO/FA string into individual option entries
    public static func parse(voString: String) -> [VOEntry] {
        // VO/FA format examples:
        // "5AR,6AC,423,2TB"
        // Split by comma and trim whitespace
        let codes = voString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        return codes.map { code in
            VOEntry(
                code: String(code),
                description: descriptionForCode(String(code))
            )
        }
    }
    
    /// Parse from binary VO data (as read from ECU)
    public static func parse(voData: Data) -> [VOEntry] {
        // Convert data to string and parse
        guard let voString = String(data: voData, encoding: .utf8) else {
            return []
        }
        return parse(voString: voString)
    }
    
    /// Validate VO entry compatibility with chassis and I-step
    public static func validate(
        entry: VOEntry,
        chassis: SupportedChassis,
        istep: ISTEP?
    ) -> ValidationResult {
        // Check if option is supported for this chassis
        let supportedChassis = getSupportedChassis(for: entry.code)
        guard supportedChassis.contains(chassis) else {
            return .incompatible(reason: "Option \(entry.code) not supported for \(chassis.rawValue)-series")
        }
        
        // Check I-step requirements if available
        if let istep = istep,
           let requiredIStep = getRequiredIStep(for: entry.code) {
            if !isIStepCompatible(current: istep, required: requiredIStep) {
                return .incompatible(reason: "Option \(entry.code) requires I-step \(requiredIStep.asString) or later")
            }
        }
        
        return .valid
    }
    
    /// Get affected modules for a VO option
    public static func getAffectedModules(for voEntry: VOEntry) -> [String] {
        // Common option to module mappings
        let mappings: [String: [String]] = [
            "5AR": ["FEM", "BDC", "KOMBI"],              // Automatic climate control
            "6AC": ["CID", "HU", "BDC"],                  // Navigation system
            "423": ["DME", "DSC", "BDC"],                 // Sport package
            "2TB": ["CAS", "BDC", "FEM"],                 // Comfort access
            "609": ["CID", "HU"],                         // Head-up display
            "430": ["DSC", "DME"],                        // M Sport differential
        ]
        
        return mappings[voEntry.code] ?? []
    }
    
    /// Merge VO changes into current VO
    public static func merge(current: [VOEntry], changes: VOChange) -> [VOEntry] {
        var result = current
        
        // Remove entries
        result.removeAll { entry in
            changes.remove.contains(where: { $0.code == entry.code })
        }
        
        // Add new entries (avoiding duplicates)
        for newEntry in changes.add {
            if !result.contains(where: { $0.code == newEntry.code }) {
                result.append(newEntry)
            }
        }
        
        return result.sorted { $0.code < $1.code }
    }
    
    // MARK: - Private Helpers
    
    private static func descriptionForCode(_ code: String) -> String? {
        // Common BMW option codes
        let descriptions: [String: String] = [
            "5AR": "Automatic Climate Control",
            "6AC": "Navigation System Professional",
            "423": "M Sport Package",
            "2TB": "Comfort Access",
            "609": "Head-Up Display",
            "430": "M Sport Differential",
            "6WD": "Driving Assistant Professional",
            "3AG": "Parking Assistant Plus",
            "302": "M Sport Brakes",
            "322": "Adaptive LED Headlights",
            "494": "Harmon Kardon Sound System",
            "3MB": "Wireless Charging",
            "6U3": "BMW Live Cockpit Professional"
        ]
        
        return descriptions[code]
    }
    
    private static func getSupportedChassis(for code: String) -> [SupportedChassis] {
        // Most options support G and I series
        // F series has more limited option support
        let fSeriesOnly = ["302"]  // Some options F-series specific
        let gSeriesAndNewer = ["6U3", "3MB", "6WD"]  // Newer options
        
        if fSeriesOnly.contains(code) {
            return [.fSeries]
        } else if gSeriesAndNewer.contains(code) {
            return [.gSeries, .iSeries]
        }
        
        // Default: all chassis
        return [.fSeries, .gSeries, .iSeries]
    }
    
    private static func getRequiredIStep(for code: String) -> ISTEP? {
        // Some options require minimum I-step
        let requirements: [String: ISTEP] = [
            "6U3": ISTEP(year: 2020, month: 3, patch: 0),
            "3MB": ISTEP(year: 2019, month: 7, patch: 0),
            "6WD": ISTEP(year: 2020, month: 11, patch: 0)
        ]
        
        return requirements[code]
    }
    
    private static func isIStepCompatible(current: ISTEP, required: ISTEP) -> Bool {
        if current.year > required.year {
            return true
        } else if current.year == required.year {
            if current.month > required.month {
                return true
            } else if current.month == required.month {
                return current.patch >= required.patch
            }
        }
        return false
    }
}

public enum ValidationResult {
    case valid
    case incompatible(reason: String)
    case warning(reason: String)
}
