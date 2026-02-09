import { View, Text, StyleSheet, TouchableOpacity, ScrollView, TextInput, StatusBar, Alert, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useState, useEffect } from 'react';
import axios from 'axios';
import { useVehicleStore } from '../store/vehicleStore';
import { useConnectionStore } from '../store/connectionStore';

const EXPO_PUBLIC_BACKEND_URL = process.env.EXPO_PUBLIC_BACKEND_URL;

interface Parameter {
  id: string;
  name: string;
  currentValue: string;
  newValue?: string;
  unit?: string;
  min?: number;
  max?: number;
  type: 'string' | 'number' | 'boolean';
}

export default function CodingScreen() {
  const router = useRouter();
  const { selectedVehicle } = useVehicleStore();
  const { connectionStatus } = useConnectionStore();
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCAFD, setSelectedCAFD] = useState<string | null>(null);
  const [parameters, setParameters] = useState<Parameter[]>([]);
  const [loading, setLoading] = useState(false);
  const [applying, setApplying] = useState(false);

  const mockCAFDs = [
    { id: '0000000f', name: 'DME - Engine Control (B48)', module: 'Powertrain' },
    { id: '000000b5', name: 'FEM - Front Electronic Module', module: 'Body' },
    { id: '0000003f', name: 'KOMBI - Instrument Cluster', module: 'Display' },
    { id: '00000a07', name: 'HU - Head Unit (iDrive)', module: 'Infotainment' },
    { id: '00000160', name: 'IHKA - Climate Control', module: 'Comfort' },
    { id: '00000f9b', name: 'TCU - Transmission Control', module: 'Powertrain' },
  ];

  const loadParameters = async (cafdId: string) => {
    setLoading(true);
    try {
      const response = await axios.get(
        `${EXPO_PUBLIC_BACKEND_URL}/api/coding/parameters/${cafdId}`,
        { params: { vin: selectedVehicle?.vin } }
      );
      
      // Set parameters with real names and current values
      const realParams = response.data.parameters || [];
      if (realParams.length > 0) {
        setParameters(realParams);
      } else {
        // Use proper named parameters based on CAFD
        const cafdParams = getParametersForCAFD(cafdId);
        setParameters(cafdParams);
      }
    } catch (error: any) {
      console.error('Load parameters error:', error);
      // Use fallback with proper names
      const cafdParams = getParametersForCAFD(cafdId);
      setParameters(cafdParams);
    } finally {
      setLoading(false);
    }
  };

  const getParametersForCAFD = (cafdId: string): Parameter[] => {
    // Map CAFD to real parameters
    const paramMap: Record<string, Parameter[]> = {
      '0000000f': [ // DME - Engine
        { id: '1', name: 'Exhaust Flaps', currentValue: 'normal', type: 'string', unit: '', options: ['normal', 'always_open'] },
        { id: '2', name: 'Launch Control', currentValue: 'not_active', type: 'string', options: ['not_active', 'active'] },
        { id: '3', name: 'Rev Limiter', currentValue: '6500', type: 'number', unit: 'RPM', min: 6000, max: 7200 },
      ],
      '000000b5': [ // FEM
        { id: '1', name: 'SCR1 Remote Start', currentValue: 'not_active', type: 'string', options: ['not_active', 'active'] },
        { id: '2', name: 'Angel Eyes Brightness', currentValue: '50', type: 'number', unit: '%', min: 0, max: 100 },
        { id: '3', name: 'DRL Brightness', currentValue: '80', type: 'number', unit: '%', min: 0, max: 100 },
      ],
      '0000003f': [ // KOMBI - Instrument Cluster
        { id: '1', name: 'Needle Sweep Animation', currentValue: 'not_active', type: 'string', options: ['not_active', 'active'] },
        { id: '2', name: 'Digital Speed Display', currentValue: 'not_active', type: 'string', options: ['not_active', 'active'] },
        { id: '3', name: 'Extended Menu Items', currentValue: 'not_active', type: 'string', options: ['not_active', 'active'] },
      ],
      '00000a07': [ // Head Unit
        { id: '1', name: 'Video In Motion', currentValue: 'not_active', type: 'string', options: ['not_active', 'active'] },
        { id: '2', name: 'DVD Region Lock', currentValue: 'locked', type: 'string', options: ['locked', 'region_free'] },
        { id: '3', name: 'USB Video Playback', currentValue: 'not_active', type: 'string', options: ['not_active', 'active'] },
      ],
      '00000160': [ // IHKA Climate
        { id: '1', name: 'Auto Climate on Start', currentValue: 'not_active', type: 'string', options: ['not_active', 'active'] },
        { id: '2', name: 'Max Cooling on Start', currentValue: 'not_active', type: 'string', options: ['not_active', 'active'] },
      ],
      '00000f9b': [ // TCU Transmission
        { id: '1', name: 'Sport Mode Default', currentValue: 'not_active', type: 'string', options: ['not_active', 'active'] },
        { id: '2', name: 'Shift Speed', currentValue: 'normal', type: 'string', options: ['normal', 'fast', 'very_fast'] },
      ],
    };

    return paramMap[cafdId] || [
      { id: '1', name: 'Parameter 1', currentValue: 'unknown', type: 'string' },
      { id: '2', name: 'Parameter 2', currentValue: 'unknown', type: 'string' },
    ];
  };

  const handleSelectCAFD = (cafd: any) => {
    setSelectedCAFD(cafd.id);
    loadParameters(cafd.id);
  };

  const handleApply = async () => {
    if (connectionStatus !== 'connected') {
      Alert.alert('Not Connected', 'Please connect to vehicle first');
      return;
    }

    const modifiedParams = parameters.filter(p => p.newValue && p.newValue !== p.currentValue);
    if (modifiedParams.length === 0) {
      Alert.alert('No Changes', 'No parameters have been modified');
      return;
    }

    Alert.alert(
      'Apply Coding',
      `Apply ${modifiedParams.length} parameter change(s)?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Apply',
          onPress: async () => {
            setApplying(true);
            try {
              const response = await axios.post(
                `${EXPO_PUBLIC_BACKEND_URL}/api/coding/apply`,
                {
                  cafd: selectedCAFD,
                  parameters: modifiedParams,
                  vehicle: selectedVehicle,
                }
              );
              Alert.alert('Success', 'Coding applied successfully!');
              loadParameters(selectedCAFD!);
            } catch (error: any) {
              Alert.alert('Error', error.response?.data?.message || 'Failed to apply coding');
            } finally {
              setApplying(false);
            }
          },
        },
      ]
    );
  };

  const updateParameter = (id: string, newValue: string) => {
    setParameters(prev => 
      prev.map(p => p.id === id ? { ...p, newValue } : p)
    );
  };

  const filteredCAFDs = mockCAFDs.filter(cafd => 
    cafd.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    cafd.id.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" />
      
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
          <Ionicons name="arrow-back" size={24} color="#fff" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>ECU Coding</Text>
        <View style={{ width: 48 }} />
      </View>

      {/* Search Bar */}
      <View style={styles.searchContainer}>
        <Ionicons name="search" size={20} color="#888" />
        <TextInput
          style={styles.searchInput}
          placeholder="Search CAFD..."
          placeholderTextColor="#555"
          value={searchQuery}
          onChangeText={setSearchQuery}
        />
      </View>

      <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
        {/* CAFD Selection */}
        {!selectedCAFD && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Select CAFD</Text>
            {filteredCAFDs.map((cafd) => (
              <TouchableOpacity
                key={cafd.id}
                style={styles.cafdCard}
                onPress={() => handleSelectCAFD(cafd)}
                activeOpacity={0.7}
              >
                <View style={styles.cafdIcon}>
                  <Ionicons name="document-text" size={24} color="#1E90FF" />
                </View>
                <View style={styles.cafdInfo}>
                  <Text style={styles.cafdName}>{cafd.name}</Text>
                  <Text style={styles.cafdModule}>{cafd.module} • {cafd.id}</Text>
                </View>
                <Ionicons name="chevron-forward" size={20} color="#555" />
              </TouchableOpacity>
            ))}
          </View>
        )}

        {/* Parameters Editing */}
        {selectedCAFD && (
          <View style={styles.section}>
            <View style={styles.cafdHeader}>
              <TouchableOpacity
                onPress={() => {
                  setSelectedCAFD(null);
                  setParameters([]);
                }}
                style={styles.backToListButton}
              >
                <Ionicons name="arrow-back" size={20} color="#1E90FF" />
                <Text style={styles.backToListText}>Back to list</Text>
              </TouchableOpacity>
              <Text style={styles.selectedCAFD}>{selectedCAFD}</Text>
            </View>

            {loading ? (
              <ActivityIndicator size="large" color="#1E90FF" style={{ marginTop: 40 }} />
            ) : (
              <>
                {parameters.map((param) => (
                  <View key={param.id} style={styles.paramCard}>
                    <Text style={styles.paramName}>{param.name}</Text>
                    {param.unit && (
                      <Text style={styles.paramUnit}>Unit: {param.unit}</Text>
                    )}
                    <View style={styles.paramValues}>
                      <View style={styles.valueBox}>
                        <Text style={styles.valueLabel}>Current</Text>
                        <Text style={styles.currentValue}>{param.currentValue}</Text>
                      </View>
                      <Ionicons name="arrow-forward" size={20} color="#555" />
                      <View style={styles.valueBox}>
                        <Text style={styles.valueLabel}>New</Text>
                        {param.options && param.options.length > 0 ? (
                          <View style={styles.optionsContainer}>
                            {param.options.map((option) => (
                              <TouchableOpacity
                                key={option}
                                style={[
                                  styles.optionChip,
                                  param.newValue === option && styles.optionChipSelected,
                                ]}
                                onPress={() => updateParameter(param.id, option)}
                                activeOpacity={0.7}
                              >
                                <Text style={[
                                  styles.optionText,
                                  param.newValue === option && styles.optionTextSelected,
                                ]}>
                                  {option.replace(/_/g, ' ')}
                                </Text>
                              </TouchableOpacity>
                            ))}
                          </View>
                        ) : (
                          <TextInput
                            style={styles.newValueInput}
                            placeholder="Enter value"
                            placeholderTextColor="#555"
                            value={param.newValue || ''}
                            onChangeText={(value) => updateParameter(param.id, value)}
                            keyboardType={param.type === 'number' ? 'numeric' : 'default'}
                          />
                        )}
                      </View>
                    </View>
                  </View>
                ))}

                <TouchableOpacity
                  style={[styles.applyButton, applying && styles.applyButtonDisabled]}
                  onPress={handleApply}
                  disabled={applying}
                  activeOpacity={0.8}
                >
                  {applying ? (
                    <ActivityIndicator color="#fff" />
                  ) : (
                    <>
                      <Text style={styles.applyButtonText}>Apply Changes</Text>
                      <Ionicons name="checkmark" size={24} color="#fff" />
                    </>
                  )}
                </TouchableOpacity>
              </>
            )}
          </View>
        )}

        <View style={{ height: 40 }} />
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingTop: 60,
    paddingBottom: 20,
  },
  backButton: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#111',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: '#222',
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#fff',
  },
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#111',
    borderRadius: 12,
    paddingHorizontal: 16,
    marginHorizontal: 24,
    marginBottom: 24,
    borderWidth: 1,
    borderColor: '#222',
  },
  searchInput: {
    flex: 1,
    fontSize: 16,
    color: '#fff',
    paddingVertical: 12,
    marginLeft: 12,
  },
  scrollView: {
    flex: 1,
    paddingHorizontal: 24,
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 16,
  },
  cafdCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#111',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#222',
  },
  cafdIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#1E90FF20',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  cafdInfo: {
    flex: 1,
  },
  cafdName: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 4,
  },
  cafdModule: {
    fontSize: 14,
    color: '#888',
  },
  cafdHeader: {
    marginBottom: 20,
  },
  backToListButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 12,
  },
  backToListText: {
    fontSize: 14,
    color: '#1E90FF',
    fontWeight: '600',
  },
  selectedCAFD: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#fff',
  },
  paramCard: {
    backgroundColor: '#111',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#222',
  },
  paramName: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1E90FF',
    marginBottom: 8,
  },
  paramUnit: {
    fontSize: 12,
    color: '#888',
    marginBottom: 12,
  },
  paramValues: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  valueBox: {
    flex: 1,
  },
  valueLabel: {
    fontSize: 12,
    color: '#888',
    marginBottom: 8,
  },
  currentValue: {
    fontSize: 16,
    color: '#ccc',
    fontWeight: '600',
  },
  optionsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  optionChip: {
    backgroundColor: '#000',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderWidth: 1,
    borderColor: '#333',
  },
  optionChipSelected: {
    backgroundColor: '#1E90FF',
    borderColor: '#1E90FF',
  },
  optionText: {
    fontSize: 13,
    color: '#888',
    textTransform: 'capitalize',
  },
  optionTextSelected: {
    color: '#fff',
    fontWeight: '600',
  },
  newValueInput: {
    backgroundColor: '#000',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    color: '#fff',
    borderWidth: 1,
    borderColor: '#1E90FF',
  },
  applyButton: {
    backgroundColor: '#1E90FF',
    borderRadius: 12,
    padding: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
    marginTop: 24,
  },
  applyButtonDisabled: {
    opacity: 0.6,
  },
  applyButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
  },
});
