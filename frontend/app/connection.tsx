import { View, Text, StyleSheet, TouchableOpacity, ScrollView, TextInput, ActivityIndicator, StatusBar, Alert } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useState } from 'react';
import { useConnectionStore } from '../store/connectionStore';
import axios from 'axios';

const EXPO_PUBLIC_BACKEND_URL = process.env.EXPO_PUBLIC_BACKEND_URL;

const CONNECTION_TYPES = [
  {
    id: 'enet',
    name: 'ENET Cable',
    icon: 'wifi',
    description: 'Direct Ethernet connection',
    defaultIP: '192.168.0.10',
    port: 6801,
  },
  {
    id: 'bluetooth',
    name: 'Bluetooth OBD',
    icon: 'bluetooth',
    description: 'Wireless OBD adapter',
    defaultIP: null,
    port: null,
  },
  {
    id: 'wifi',
    name: 'WiFi OBD',
    icon: 'cloud',
    description: 'WiFi-enabled OBD adapter',
    defaultIP: '192.168.0.1',
    port: 35000,
  },
];

export default function ConnectionScreen() {
  const router = useRouter();
  const { 
    connectionType, 
    connectionStatus, 
    setConnectionType, 
    setConnectionStatus, 
    setConnectedDevice,
    setIPAddress,
    disconnect 
  } = useConnectionStore();
  
  const [selectedType, setSelectedType] = useState<string | null>(null);
  const [ipAddress, setIP] = useState('');
  const [isConnecting, setIsConnecting] = useState(false);

  const handleSelectType = (type: string) => {
    const connType = CONNECTION_TYPES.find(t => t.id === type);
    setSelectedType(type);
    if (connType?.defaultIP) {
      setIP(connType.defaultIP);
    }
  };

  const handleConnect = async () => {
    if (!selectedType) return;
    
    setIsConnecting(true);
    setConnectionStatus('connecting');
    
    try {
      // Call backend to establish connection
      const response = await axios.post(`${EXPO_PUBLIC_BACKEND_URL}/api/connection/connect`, {
        type: selectedType,
        ipAddress: ipAddress || undefined,
      });
      
      if (response.data.success) {
        setConnectionType(selectedType as any);
        setConnectionStatus('connected');
        setConnectedDevice(response.data.deviceName || selectedType.toUpperCase());
        setIPAddress(ipAddress || null);
        
        Alert.alert('Connected', `Successfully connected via ${selectedType.toUpperCase()}`);
        router.back();
      } else {
        throw new Error(response.data.message || 'Connection failed');
      }
    } catch (error: any) {
      console.error('Connection error:', error);
      setConnectionStatus('error');
      Alert.alert('Connection Failed', error.message || 'Could not connect to device');
    } finally {
      setIsConnecting(false);
    }
  };

  const handleDisconnect = () => {
    disconnect();
    setSelectedType(null);
    setIP('');
    Alert.alert('Disconnected', 'Device connection closed');
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" />
      
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
          <Ionicons name="arrow-back" size={24} color="#fff" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Connection Manager</Text>
        <View style={{ width: 48 }} />
      </View>

      <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
        {/* Current Status */}
        <View style={styles.statusCard}>
          <View style={styles.statusHeader}>
            <View style={[styles.statusDot, { 
              backgroundColor: connectionStatus === 'connected' ? '#00FF00' : '#FF6347' 
            }]} />
            <Text style={styles.statusText}>
              {connectionStatus === 'connected' ? 'Connected' : 'Disconnected'}
            </Text>
          </View>
          {connectionStatus === 'connected' && (
            <TouchableOpacity 
              style={styles.disconnectButton}
              onPress={handleDisconnect}
            >
              <Text style={styles.disconnectButtonText}>Disconnect</Text>
            </TouchableOpacity>
          )}
        </View>

        {/* Connection Types */}
        <Text style={styles.sectionTitle}>Select Connection Type</Text>
        {CONNECTION_TYPES.map((type) => (
          <TouchableOpacity
            key={type.id}
            style={[
              styles.typeCard,
              selectedType === type.id && styles.typeCardSelected,
            ]}
            onPress={() => handleSelectType(type.id)}
            activeOpacity={0.7}
            disabled={connectionStatus === 'connected'}
          >
            <View style={[styles.iconContainer, selectedType === type.id && styles.iconContainerSelected]}>
              <Ionicons 
                name={type.icon as any} 
                size={28} 
                color={selectedType === type.id ? '#1E90FF' : '#888'} 
              />
            </View>
            <View style={styles.typeInfo}>
              <Text style={[styles.typeName, selectedType === type.id && styles.typeNameSelected]}>
                {type.name}
              </Text>
              <Text style={styles.typeDescription}>{type.description}</Text>
            </View>
            {selectedType === type.id && (
              <Ionicons name="checkmark-circle" size={24} color="#1E90FF" />
            )}
          </TouchableOpacity>
        ))}

        {/* IP Address Input for ENET/WiFi */}
        {selectedType && (selectedType === 'enet' || selectedType === 'wifi') && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>IP Address</Text>
            <TextInput
              style={styles.input}
              placeholder="Enter IP address"
              placeholderTextColor="#555"
              value={ipAddress}
              onChangeText={setIP}
              keyboardType="numeric"
              editable={connectionStatus !== 'connected'}
            />
            <Text style={styles.hint}>
              Default: {CONNECTION_TYPES.find(t => t.id === selectedType)?.defaultIP}
            </Text>
          </View>
        )}

        {/* Connect Button */}
        {selectedType && connectionStatus !== 'connected' && (
          <TouchableOpacity
            style={[styles.connectButton, isConnecting && styles.connectButtonDisabled]}
            onPress={handleConnect}
            disabled={isConnecting}
            activeOpacity={0.8}
          >
            {isConnecting ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <>
                <Text style={styles.connectButtonText}>Connect</Text>
                <Ionicons name="link" size={24} color="#fff" />
              </>
            )}
          </TouchableOpacity>
        )}

        {/* Info Panel */}
        <View style={styles.infoPanel}>
          <Ionicons name="information-circle" size={24} color="#1E90FF" />
          <View style={styles.infoTextContainer}>
            <Text style={styles.infoTitle}>Connection Tips</Text>
            <Text style={styles.infoText}>
              • ENET: Connect device to ENET cable WiFi network{"\n"}
              • Bluetooth: Pair OBD adapter in device settings first{"\n"}
              • WiFi: Connect to OBD adapter's WiFi network
            </Text>
          </View>
        </View>

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
  scrollView: {
    flex: 1,
    paddingHorizontal: 24,
  },
  statusCard: {
    backgroundColor: '#111',
    borderRadius: 16,
    padding: 20,
    marginBottom: 24,
    borderWidth: 1,
    borderColor: '#222',
  },
  statusHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 12,
  },
  statusDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
  },
  statusText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#fff',
  },
  disconnectButton: {
    backgroundColor: '#FF6347',
    borderRadius: 12,
    padding: 12,
    alignItems: 'center',
  },
  disconnectButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 16,
  },
  typeCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#111',
    borderRadius: 16,
    padding: 20,
    marginBottom: 12,
    borderWidth: 2,
    borderColor: '#222',
  },
  typeCardSelected: {
    borderColor: '#1E90FF',
    backgroundColor: '#1E90FF10',
  },
  iconContainer: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: '#222',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 16,
  },
  iconContainerSelected: {
    backgroundColor: '#1E90FF20',
  },
  typeInfo: {
    flex: 1,
  },
  typeName: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#888',
    marginBottom: 4,
  },
  typeNameSelected: {
    color: '#fff',
  },
  typeDescription: {
    fontSize: 14,
    color: '#666',
  },
  section: {
    marginTop: 24,
    marginBottom: 16,
  },
  input: {
    backgroundColor: '#111',
    borderRadius: 12,
    padding: 16,
    fontSize: 16,
    color: '#fff',
    borderWidth: 1,
    borderColor: '#222',
  },
  hint: {
    fontSize: 12,
    color: '#666',
    marginTop: 8,
  },
  connectButton: {
    backgroundColor: '#1E90FF',
    borderRadius: 16,
    padding: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
    marginTop: 24,
  },
  connectButtonDisabled: {
    opacity: 0.6,
  },
  connectButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
  },
  infoPanel: {
    flexDirection: 'row',
    backgroundColor: '#1E90FF10',
    borderRadius: 12,
    padding: 16,
    marginTop: 24,
    borderWidth: 1,
    borderColor: '#1E90FF30',
  },
  infoTextContainer: {
    flex: 1,
    marginLeft: 12,
  },
  infoTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1E90FF',
    marginBottom: 8,
  },
  infoText: {
    fontSize: 14,
    color: '#888',
    lineHeight: 20,
  },
});
