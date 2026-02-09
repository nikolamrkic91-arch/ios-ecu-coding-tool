//
//  BMWDoIPModule.swift
//  BMW ECU Coding Tool
//
//  Native iOS DoIP Implementation
//

import Foundation
import Network
import NetworkExtension

@objc(BMWDoIPModule)
class BMWDoIPModule: NSObject {
    
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.bmw.doip", qos: .userInitiated)
    
    // BMW ZGM Gateway Configuration
    private let zgmIP = NWEndpoint.Host("169.254.0.8")
    private let zgmPort = NWEndpoint.Port(integerLiteral: 13400)
    private let localIP = "169.254.250.250"
    
    private var isConnected = false
    private var currentVIN: String?
    
    // MARK: - React Native Bridge
    
    @objc
    static func requiresMainQueueSetup() -> Bool {
        return false
    }
    
    // MARK: - Network Configuration
    
    @objc
    func configureStaticIP(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        // iOS 14+: Use NEHotspotConfiguration
        // For ENET cable connection (acts as WiFi network)
        
        let config = NEHotspotConfiguration(ssid: "BMW_ENET")
        config.joinOnce = false
        
        NEHotspotConfigurationManager.shared.apply(config) { error in
            if let error = error {
                reject("NETWORK_ERROR", "Failed to configure network: \(error.localizedDescription)", error)
            } else {
                // Network configured - now set static IP
                self.setStaticIPAddress(resolve: resolve, rejecter: reject)
            }
        }
    }
    
    private func setStaticIPAddress(resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        // Note: iOS doesn't allow programmatic static IP without MDM/enterprise profile
        // User must manually set in Settings > WiFi > Configure IP > Manual
        // OR we bind to specific local address in socket
        
        // Verify we're on correct network
        if let interfaces = getNetworkInterfaces() {
            let hasCorrectIP = interfaces.contains { $0.contains("169.254") }
            if hasCorrectIP {
                resolve(["success": true, "ip": localIP])
            } else {
                reject("IP_ERROR", "Device must be on 169.254.x.x network. Please configure manually in Settings.", nil)
            }
        } else {
            reject("IP_ERROR", "Cannot detect network interfaces", nil)
        }
    }
    
    private func getNetworkInterfaces() -> [String]? {
        var addresses = [String]()
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee
            
            if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                if addr.sa_family == UInt8(AF_INET) {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len),
                                   &hostname, socklen_t(hostname.count),
                                   nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                        let address = String(cString: hostname)
                        addresses.append(address)
                    }
                }
            }
        }
        freeifaddrs(ifaddr)
        return addresses
    }
    
    // MARK: - DoIP Connection
    
    @objc
    func connect(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        
        // Create TCP connection parameters
        let params = NWParameters.tcp
        params.requiredLocalEndpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(localIP), port: .any)
        
        // Create connection to ZGM
        connection = NWConnection(host: zgmIP, port: zgmPort, using: params)
        
        connection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("✅ DoIP: Socket connected to ZGM")
                self?.sendRoutingActivation(resolve: resolve, rejecter: reject)
                
            case .waiting(let error):
                reject("CONN_WAITING", "Connection waiting: \(error.localizedDescription)", error)
                
            case .failed(let error):
                reject("CONN_FAILED", "Connection failed: \(error.localizedDescription)", error)
                
            case .cancelled:
                reject("CONN_CANCELLED", "Connection cancelled", nil)
                
            default:
                break
            }
        }
        
        connection?.start(queue: queue)
    }
    
    private func sendRoutingActivation(resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        // DoIP Routing Activation Request
        // Header: 0x02 0xFD 0x0005 + length 0x00000007
        var packet = Data([0x02, 0xFD, 0x00, 0x05, 0x00, 0x00, 0x00, 0x07])
        
        // Payload: SA (0x0E00) + Activation Type (0x00) + Reserved (0x00000000)
        packet.append(contentsOf: [0x0E, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        
        send(data: packet) { [weak self] response in
            guard let data = response, data.count > 8 else {
                reject("ROUTING_FAILED", "Invalid routing response", nil)
                return
            }
            
            // Check payload type (0x0006) and response code (0x10 = success)
            let payloadType = (UInt16(data[2]) << 8) | UInt16(data[3])
            let responseCode = data.count > 13 ? data[13] : 0x00
            
            if payloadType == 0x0006 && responseCode == 0x10 {
                self?.isConnected = true
                print("✅ DoIP: Routing activated")
                resolve(["success": true, "message": "Routing activated"])
            } else {
                reject("ROUTING_FAILED", "Routing activation rejected by ZGM (code: \(String(format: "%02X", responseCode)))", nil)
            }
        }
    }
    
    // MARK: - UDS Diagnostics
    
    @objc
    func readVIN(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        guard isConnected else {
            reject("NOT_CONNECTED", "Not connected to vehicle", nil)
            return
        }
        
        // UDS Request: Service 0x22 (Read Data By Identifier) + DID 0xF190 (VIN)
        let udsRequest = Data([0x22, 0xF1, 0x90])
        
        sendDiagnosticRequest(targetECU: 0x0012, udsData: udsRequest) { [weak self] response in
            guard let data = response, data.count >= 20 else {
                reject("VIN_READ_FAILED", "Invalid VIN response", nil)
                return
            }
            
            // Check for positive response (0x62)
            if data[0] == 0x62 {
                let vinData = data[3..<20]
                if let vin = String(data: vinData, encoding: .ascii) {
                    self?.currentVIN = vin
                    print("✅ VIN: \(vin)")
                    resolve(["vin": vin])
                } else {
                    reject("VIN_DECODE_FAILED", "Failed to decode VIN", nil)
                }
            } else {
                // Negative response (0x7F)
                let nrc = data.count > 2 ? data[2] : 0x00
                reject("VIN_READ_FAILED", "VIN request rejected (NRC: \(String(format: "%02X", nrc)))", nil)
            }
        }
    }
    
    @objc
    func readParameter(_ ecuAddress: NSNumber, did: NSNumber, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        guard isConnected else {
            reject("NOT_CONNECTED", "Not connected to vehicle", nil)
            return
        }
        
        let didValue = did.uint16Value
        var udsRequest = Data([0x22])
        udsRequest.append(contentsOf: withUnsafeBytes(of: didValue.bigEndian, Array.init))
        
        sendDiagnosticRequest(targetECU: ecuAddress.uint16Value, udsData: udsRequest) { response in
            guard let data = response, data[0] == 0x62 else {
                reject("READ_FAILED", "Parameter read failed", nil)
                return
            }
            
            let paramData = data.dropFirst(3)
            resolve(["data": paramData.hexString])
        }
    }
    
    @objc
    func writeParameter(_ ecuAddress: NSNumber, did: NSNumber, value: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        guard isConnected else {
            reject("NOT_CONNECTED", "Not connected to vehicle", nil)
            return
        }
        
        let didValue = did.uint16Value
        var udsRequest = Data([0x2E])
        udsRequest.append(contentsOf: withUnsafeBytes(of: didValue.bigEndian, Array.init))
        
        if let valueData = Data(hexString: value) {
            udsRequest.append(valueData)
        } else {
            udsRequest.append(value.data(using: .utf8) ?? Data())
        }
        
        sendDiagnosticRequest(targetECU: ecuAddress.uint16Value, udsData: udsRequest) { response in
            if let data = response, data[0] == 0x6E {
                resolve(["success": true])
            } else {
                reject("WRITE_FAILED", "Parameter write failed", nil)
            }
        }
    }
    
    // MARK: - Security Access
    
    @objc
    func unlockECU(_ ecuAddress: NSNumber, level: NSNumber, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        guard isConnected else {
            reject("NOT_CONNECTED", "Not connected to vehicle", nil)
            return
        }
        
        let secLevel = level.uint8Value
        
        // Request Seed
        let seedRequest = Data([0x27, secLevel])
        
        sendDiagnosticRequest(targetECU: ecuAddress.uint16Value, udsData: seedRequest) { [weak self] response in
            guard let data = response, data[0] == 0x67 else {
                reject("SEED_FAILED", "Seed request failed", nil)
                return
            }
            
            let seed = data[2..<6]
            print("🔑 Seed: \(seed.hexString)")
            
            // Calculate key (call backend API)
            self?.calculateKey(seed: seed, ecuAddress: ecuAddress.uint16Value, level: secLevel) { key in
                guard let keyData = key else {
                    reject("KEY_CALC_FAILED", "Key calculation failed", nil)
                    return
                }
                
                // Send Key
                var keyRequest = Data([0x27, secLevel + 1])
                keyRequest.append(keyData)
                
                self?.sendDiagnosticRequest(targetECU: ecuAddress.uint16Value, udsData: keyRequest) { keyResponse in
                    if let respData = keyResponse, respData[0] == 0x67 {
                        print("🔓 ECU unlocked")
                        resolve(["success": true])
                    } else {
                        reject("KEY_REJECTED", "Key rejected by ECU", nil)
                    }
                }
            }
        }
    }
    
    private func calculateKey(seed: Data, ecuAddress: UInt16, level: UInt8, completion: @escaping (Data?) -> Void) {
        // Call backend API to calculate key
        guard let url = URL(string: "YOUR_BACKEND_URL/api/calculate-key") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "seed": seed.hexString,
            "ecu": ecuAddress,
            "level": level,
            "vin": currentVIN ?? ""
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let keyHex = json["key"] as? String,
                  let keyData = Data(hexString: keyHex) else {
                completion(nil)
                return
            }
            completion(keyData)
        }.resume()
    }
    
    // MARK: - DoIP Low-Level Functions
    
    private func sendDiagnosticRequest(targetECU: UInt16, udsData: Data, completion: @escaping (Data?) -> Void) {
        // Build DoIP Diagnostic Message (0x8001)
        let sourceAddress: UInt16 = 0x0E00
        let payloadLength = UInt32(4 + udsData.count)
        
        var packet = Data()
        
        // DoIP Header
        packet.append(contentsOf: [0x02, 0xFD, 0x80, 0x01])
        packet.append(contentsOf: withUnsafeBytes(of: payloadLength.bigEndian, Array.init))
        
        // Addresses
        packet.append(contentsOf: withUnsafeBytes(of: sourceAddress.bigEndian, Array.init))
        packet.append(contentsOf: withUnsafeBytes(of: targetECU.bigEndian, Array.init))
        
        // UDS Data
        packet.append(udsData)
        
        send(data: packet) { response in
            guard let data = response, data.count > 12 else {
                completion(nil)
                return
            }
            
            // Strip DoIP header (8 bytes) + SA/TA (4 bytes) to get UDS response
            let udsResponse = data.dropFirst(12)
            completion(Data(udsResponse))
        }
    }
    
    private func send(data: Data, completion: @escaping (Data?) -> Void) {
        connection?.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                print("❌ Send error: \(error)")
                completion(nil)
                return
            }
            
            // Receive response
            self?.connection?.receive(minimumIncompleteLength: 8, maximumLength: 4096) { content, _, isComplete, error in
                if let error = error {
                    print("❌ Receive error: \(error)")
                    completion(nil)
                    return
                }
                
                completion(content)
            }
        })
    }
    
    // MARK: - Disconnect
    
    @objc
    func disconnect(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        connection?.cancel()
        connection = nil
        isConnected = false
        resolve(["success": true])
    }
}

// MARK: - Extensions

extension Data {
    var hexString: String {
        return map { String(format: "%02X", $0) }.joined()
    }
    
    init?(hexString: String) {
        let length = hexString.count / 2
        var data = Data(capacity: length)
        for i in 0..<length {
            let start = hexString.index(hexString.startIndex, offsetBy: i * 2)
            let end = hexString.index(start, offsetBy: 2)
            let bytes = hexString[start..<end]
            if let byte = UInt8(bytes, radix: 16) {
                data.append(byte)
            } else {
                return nil
            }
        }
        self = data
    }
}
