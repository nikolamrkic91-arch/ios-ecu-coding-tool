import { create } from 'zustand';

export type ConnectionType = 'enet' | 'bluetooth' | 'wifi' | null;
export type ConnectionStatus = 'disconnected' | 'connecting' | 'connected' | 'error';

interface ConnectionStore {
  connectionType: ConnectionType;
  connectionStatus: ConnectionStatus;
  connectedDevice: string | null;
  ipAddress: string | null;
  setConnectionType: (type: ConnectionType) => void;
  setConnectionStatus: (status: ConnectionStatus) => void;
  setConnectedDevice: (device: string | null) => void;
  setIPAddress: (ip: string | null) => void;
  disconnect: () => void;
}

export const useConnectionStore = create<ConnectionStore>((set) => ({
  connectionType: null,
  connectionStatus: 'disconnected',
  connectedDevice: null,
  ipAddress: null,
  
  setConnectionType: (type) => set({ connectionType: type }),
  setConnectionStatus: (status) => set({ connectionStatus: status }),
  setConnectedDevice: (device) => set({ connectedDevice: device }),
  setIPAddress: (ip) => set({ ipAddress: ip }),
  
  disconnect: () => set({
    connectionType: null,
    connectionStatus: 'disconnected',
    connectedDevice: null,
    ipAddress: null,
  }),
}));
