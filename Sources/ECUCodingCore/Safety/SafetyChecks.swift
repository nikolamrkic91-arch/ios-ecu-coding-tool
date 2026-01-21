import Foundation

/// Safety checks and guardrails for coding operations.
public struct SafetyChecks {
    
    /// Preflight checks before any write operation.
    public struct PreflightResult {
        public let passed: Bool
        public let failures: [String]
        
        public init(passed: Bool, failures: [String] = []) {
            self.passed = passed
            self.failures = failures
        }
    }
    
    /// Check if a coding operation is safe to proceed.
    public static func preflight(
        isChargerConnected: Bool,
        linkQuality: LinkQuality,
        ignitionState: IgnitionState,
        batteryVoltage: Double,
        supportedChassis: [SupportedChassis],
        vehicleChassis: SupportedChassis,
        hasBackup: Bool
    ) -> PreflightResult {
        var failures: [String] = []
        
        if !isChargerConnected {
            failures.append("Charger must be connected for write operations")
        }
        
        if linkQuality.latencyMs > 100 {
            failures.append("Link latency too high: \(linkQuality.latencyMs)ms (max 100ms)")
        }
        
        if linkQuality.packetLoss > 0.01 {
            failures.append("Packet loss too high: \(Int(linkQuality.packetLoss * 100))% (max 1%)")
        }
        
        if ignitionState != .on {
            failures.append("Ignition must be on")
        }
        
        if batteryVoltage < 12.0 {
            failures.append("Battery voltage too low: \(batteryVoltage)V (min 12.0V)")
        }
        
        if !supportedChassis.contains(vehicleChassis) {
            failures.append("Chassis \(vehicleChassis.rawValue) not supported")
        }
        
        if !hasBackup {
            failures.append("Backup required before write operation")
        }
        
        return PreflightResult(passed: failures.isEmpty, failures: failures)
    }
    
    /// Validate compatibility for a module operation.
    public static func validateCompatibility(
        module: Module,
        operation: ModuleOperation,
        chassis: SupportedChassis,
        istep: ISTEP?
    ) -> Bool {
        // Check if operation is supported
        guard module.supportedOperations.contains(operation) else {
            return false
        }
        
        // Additional checks can be added here based on chassis/I-step
        return true
    }
    
    /// Calculate checksum for backup verification.
    public static func calculateChecksum(_ data: Data) -> String {
        // Simple SHA-256 checksum
        var hash = [UInt8](repeating: 0, count: 32)
        data.withUnsafeBytes { buffer in
            // In production, use CryptoKit or CommonCrypto
            // For now, use a simple hash
            let ptr = buffer.bindMemory(to: UInt8.self)
            for i in 0..<min(data.count, 32) {
                hash[i] = ptr[i]
            }
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

public struct LinkQuality {
    public let latencyMs: Double
    public let packetLoss: Double
    
    public init(latencyMs: Double, packetLoss: Double) {
        self.latencyMs = latencyMs
        self.packetLoss = packetLoss
    }
}

public enum IgnitionState {
    case off
    case accessory
    case on
}
