import Foundation

/// Preset coding configurations for common modifications
public struct CodingPreset: Codable, Identifiable {
    public var id: String { name }
    
    public let name: String
    public let description: String
    public let category: PresetCategory
    public let supportedChassis: [SupportedChassis]
    public let requiredIStep: ISTEP?
    public let riskLevel: ModuleRiskLevel
    public let voChanges: VOChange?
    public let fdlChanges: [FDLChange]?
    public let affectedModules: [String]
    public let reversible: Bool
    
    public init(
        name: String,
        description: String,
        category: PresetCategory,
        supportedChassis: [SupportedChassis],
        requiredIStep: ISTEP? = nil,
        riskLevel: ModuleRiskLevel,
        voChanges: VOChange? = nil,
        fdlChanges: [FDLChange]? = nil,
        affectedModules: [String],
        reversible: Bool = true
    ) {
        self.name = name
        self.description = description
        self.category = category
        self.supportedChassis = supportedChassis
        self.requiredIStep = requiredIStep
        self.riskLevel = riskLevel
        self.voChanges = voChanges
        self.fdlChanges = fdlChanges
        self.affectedModules = affectedModules
        self.reversible = reversible
    }
}

public enum PresetCategory: String, Codable {
    case comfort = "Comfort"
    case performance = "Performance"
    case lighting = "Lighting"
    case multimedia = "Multimedia"
    case safety = "Safety"
    case other = "Other"
}

/// Service for managing and applying coding presets
public final class PresetService {
    private let voCodingService: VOCodingService
    private let fdlCodingService: FDLCodingService
    private let logger = SessionLogger.shared
    
    public init(voCodingService: VOCodingService, fdlCodingService: FDLCodingService) {
        self.voCodingService = voCodingService
        self.fdlCodingService = fdlCodingService
    }
    
    /// Get all available presets
    public static func getAvailablePresets() -> [CodingPreset] {
        return [
            // Comfort presets
            CodingPreset(
                name: "Comfort Access+",
                description: "Enhanced comfort access with automatic trunk opening",
                category: .comfort,
                supportedChassis: [.gSeries, .iSeries],
                riskLevel: .low,
                voChanges: VOChange(add: [VOEntry(code: "2TB", description: "Comfort Access")], remove: []),
                affectedModules: ["CAS", "BDC", "FEM"],
                reversible: true
            ),
            
            CodingPreset(
                name: "Angel Eyes Always On",
                description: "Keep angel eyes/DRLs illuminated at all times",
                category: .lighting,
                supportedChassis: [.fSeries, .gSeries],
                riskLevel: .low,
                fdlChanges: [
                    FDLChange(
                        parameter: FDLParameter(path: "FEM/DRL/MODE", name: "DRL Mode", type: .enumeration, allowedValues: ["OFF", "ON", "ALWAYS"], risk: .low),
                        newValue: "ALWAYS"
                    )
                ],
                affectedModules: ["FEM"],
                reversible: true
            ),
            
            CodingPreset(
                name: "Sport Display",
                description: "Enable sport display in instrument cluster",
                category: .performance,
                supportedChassis: [.fSeries, .gSeries],
                riskLevel: .low,
                fdlChanges: [
                    FDLChange(
                        parameter: FDLParameter(path: "KOMBI/DISPLAY/SPORT", name: "Sport Display", type: .boolean, risk: .low),
                        newValue: "true"
                    )
                ],
                affectedModules: ["KOMBI"],
                reversible: true
            ),
            
            CodingPreset(
                name: "Video in Motion",
                description: "Enable video playback while driving (use responsibly)",
                category: .multimedia,
                supportedChassis: [.fSeries, .gSeries, .iSeries],
                riskLevel: .medium,
                fdlChanges: [
                    FDLChange(
                        parameter: FDLParameter(path: "CID/VIDEO/LOCK", name: "Video Lock", type: .boolean, risk: .medium),
                        newValue: "false"
                    )
                ],
                affectedModules: ["CID", "HU"],
                reversible: true
            ),
            
            CodingPreset(
                name: "Digital Speed Limit",
                description: "Show digital speed limit in HUD and cluster",
                category: .safety,
                supportedChassis: [.gSeries, .iSeries],
                riskLevel: .low,
                voChanges: VOChange(add: [VOEntry(code: "8TH", description: "Speed Limit Info")], remove: []),
                affectedModules: ["KOMBI", "HU"],
                reversible: true
            )
        ]
    }
    
    /// Validate preset compatibility with vehicle
    public func validatePreset(_ preset: CodingPreset, for vehicle: Vehicle) -> ValidationResult {
        // Check chassis compatibility
        guard preset.supportedChassis.contains(vehicle.chassis) else {
            return .incompatible(reason: "Preset not supported for \(vehicle.chassis.rawValue)-series")
        }
        
        // Check I-step requirement
        if let requiredIStep = preset.requiredIStep,
           let vehicleIStep = vehicle.istep {
            if !isIStepCompatible(current: vehicleIStep, required: requiredIStep) {
                return .incompatible(reason: "Requires I-step \(requiredIStep.asString) or later")
            }
        }
        
        return .valid
    }
    
    /// Apply a preset with full safety checks
    public func applyPreset(
        _ preset: CodingPreset,
        toVehicle vehicle: Vehicle,
        module: Module
    ) async throws {
        logger.log(.info, "Applying preset: \(preset.name)")
        
        // Validate compatibility
        let validationResult = validatePreset(preset, for: vehicle)
        guard case .valid = validationResult else {
            if case .incompatible(let reason) = validationResult {
                throw PresetError.incompatible(preset: preset.name, reason: reason)
            }
            throw PresetError.validationFailed
        }
        
        // Apply VO changes if present
        if let voChanges = preset.voChanges {
            try await voCodingService.applyVOChanges(voChanges, toVehicle: vehicle, module: module)
        }
        
        // Apply FDL changes if present
        if let fdlChanges = preset.fdlChanges {
            try await fdlCodingService.applyFDLChanges(fdlChanges, toVehicle: vehicle, module: module)
        }
        
        logger.logOperation(SessionOperation(
            type: .writeVO,  // Generic type for preset application
            description: "Applied preset: \(preset.name)",
            success: true,
            details: [
                "preset": preset.name,
                "category": preset.category.rawValue,
                "risk": preset.riskLevel.rawValue
            ]
        ))
        
        logger.log(.info, "Preset applied successfully: \(preset.name)")
    }
    
    /// Get presets filtered by category
    public static func getPresets(category: PresetCategory) -> [CodingPreset] {
        return getAvailablePresets().filter { $0.category == category }
    }
    
    /// Get presets filtered by risk level
    public static func getPresets(maxRisk: ModuleRiskLevel) -> [CodingPreset] {
        let riskOrder: [ModuleRiskLevel: Int] = [.low: 0, .medium: 1, .high: 2]
        let maxRiskLevel = riskOrder[maxRisk] ?? 0
        
        return getAvailablePresets().filter { preset in
            (riskOrder[preset.riskLevel] ?? 0) <= maxRiskLevel
        }
    }
    
    private func isIStepCompatible(current: ISTEP, required: ISTEP) -> Bool {
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

public enum PresetError: Error, LocalizedError {
    case incompatible(preset: String, reason: String)
    case validationFailed
    case applicationFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .incompatible(let preset, let reason):
            return "Preset '\(preset)' is incompatible: \(reason)"
        case .validationFailed:
            return "Preset validation failed"
        case .applicationFailed(let error):
            return "Failed to apply preset: \(error.localizedDescription)"
        }
    }
}
