/**
 * BMW DoIP Native Module - TypeScript Wrapper
 * Direct TCP communication with BMW ZGM (169.254.0.8:13400)
 */

import { NativeModules, Platform } from 'react-native';

const { BMWDoIPModule } = NativeModules;

export interface DoIPResponse {
  success: boolean;
  message?: string;
  vin?: string;
  data?: string;
}

class BMWDoIP {
  /**
   * Configure static IP (169.254.250.250)
   * Note: On iOS, user may need to manually configure in Settings
   */
  async configureNetwork(): Promise<DoIPResponse> {
    if (Platform.OS !== 'ios') {
      throw new Error('DoIP module only supported on iOS');
    }
    
    try {
      const result = await BMWDoIPModule.configureStaticIP();
      return result;
    } catch (error: any) {
      console.error('Network configuration failed:', error);
      throw error;
    }
  }

  /**
   * Connect to BMW ZGM via DoIP
   * Automatically sends routing activation
   */
  async connect(): Promise<DoIPResponse> {
    try {
      const result = await BMWDoIPModule.connect();
      console.log('✅ DoIP Connected:', result);
      return result;
    } catch (error: any) {
      console.error('❌ DoIP Connection failed:', error);
      throw error;
    }
  }

  /**
   * Read VIN from DME using UDS Service 0x22
   */
  async readVIN(): Promise<string> {
    try {
      const result = await BMWDoIPModule.readVIN();
      return result.vin;
    } catch (error: any) {
      console.error('VIN read failed:', error);
      throw error;
    }
  }

  /**
   * Read parameter from ECU
   * 
   * @param ecuAddress - ECU address (e.g., 0x0012 for DME)
   * @param did - Data Identifier
   */
  async readParameter(ecuAddress: number, did: number): Promise<string> {
    try {
      const result = await BMWDoIPModule.readParameter(ecuAddress, did);
      return result.data;
    } catch (error: any) {
      console.error('Parameter read failed:', error);
      throw error;
    }
  }

  /**
   * Write parameter to ECU
   * 
   * @param ecuAddress - ECU address
   * @param did - Data Identifier
   * @param value - Parameter value (hex string or plain text)
   */
  async writeParameter(ecuAddress: number, did: number, value: string): Promise<boolean> {
    try {
      const result = await BMWDoIPModule.writeParameter(ecuAddress, did, value);
      return result.success;
    } catch (error: any) {
      console.error('Parameter write failed:', error);
      throw error;
    }
  }

  /**
   * Unlock ECU using security access (seed/key)
   * 
   * @param ecuAddress - ECU address
   * @param level - Security level (typically 0x01 or 0x03)
   */
  async unlockECU(ecuAddress: number, level: number = 0x01): Promise<boolean> {
    try {
      const result = await BMWDoIPModule.unlockECU(ecuAddress, level);
      return result.success;
    } catch (error: any) {
      console.error('ECU unlock failed:', error);
      throw error;
    }
  }

  /**
   * Disconnect from ZGM
   */
  async disconnect(): Promise<void> {
    try {
      await BMWDoIPModule.disconnect();
      console.log('DoIP disconnected');
    } catch (error: any) {
      console.error('Disconnect error:', error);
    }
  }
}

// ECU Addresses for G01 X3
export const ECU_ADDRESSES = {
  DME: 0x0012,      // Engine Control
  KOMBI: 0x0061,    // Instrument Cluster
  FEM: 0x00B0,      // Front Electronic Module
  REM: 0x00B1,      // Rear Electronic Module
  BDC: 0x00F1,      // Body Domain Controller
  HU: 0x0063,       // Head Unit
  ZGM: 0x00A4,      // Central Gateway
  IHKA: 0x009B,     // Climate Control
  PDC: 0x0060,      // Park Distance Control
  TCU: 0x0018,      // Transmission
};

// Common Data Identifiers (DIDs)
export const DIDS = {
  VIN: 0xF190,
  SCR1_CONFIG: 0x3000,
  ANGEL_EYES: 0x3001,
  EXHAUST_FLAPS: 0x5000,
  VIDEO_IN_MOTION: 0x6000,
};

export default new BMWDoIP();
