import { create } from 'zustand';
import AsyncStorage from '@react-native-async-storage/async-storage';

export interface Vehicle {
  series: string;
  model: string;
  year: string;
  vin?: string;
  ecuType?: string;
}

interface VehicleStore {
  selectedVehicle: Vehicle | null;
  setVehicle: (vehicle: Vehicle) => void;
  clearVehicle: () => void;
  loadVehicle: () => Promise<void>;
}

export const useVehicleStore = create<VehicleStore>((set) => ({
  selectedVehicle: null,
  
  setVehicle: async (vehicle: Vehicle) => {
    await AsyncStorage.setItem('selectedVehicle', JSON.stringify(vehicle));
    set({ selectedVehicle: vehicle });
  },
  
  clearVehicle: async () => {
    await AsyncStorage.removeItem('selectedVehicle');
    set({ selectedVehicle: null });
  },
  
  loadVehicle: async () => {
    try {
      const saved = await AsyncStorage.getItem('selectedVehicle');
      if (saved) {
        set({ selectedVehicle: JSON.parse(saved) });
      }
    } catch (error) {
      console.error('Failed to load vehicle:', error);
    }
  },
}));
