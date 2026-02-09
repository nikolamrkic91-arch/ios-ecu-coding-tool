import { View, Text, StyleSheet, TouchableOpacity, ScrollView, StatusBar } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useVehicleStore } from '../store/vehicleStore';
import { useConnectionStore } from '../store/connectionStore';

export default function HomeScreen() {
  const router = useRouter();
  const { selectedVehicle } = useVehicleStore();
  const { connectionStatus, connectedDevice } = useConnectionStore();

  const menuItems = [
    {
      id: 'vehicle',
      title: 'Vehicle Selection',
      subtitle: selectedVehicle ? `${selectedVehicle.series} ${selectedVehicle.model}` : 'Select vehicle',
      icon: 'car-sport',
      route: '/vehicle-select',
      color: '#1E90FF',
    },
    {
      id: 'connection',
      title: 'Connection Manager',
      subtitle: connectionStatus === 'connected' ? connectedDevice : 'Not connected',
      icon: 'wifi',
      route: '/connection',
      color: connectionStatus === 'connected' ? '#00FF00' : '#FF6347',
    },
    {
      id: 'coding',
      title: 'ECU Coding',
      subtitle: 'Parameter editing & validation',
      icon: 'code-slash',
      route: '/coding',
      color: '#9370DB',
    },
    {
      id: 'flash',
      title: 'Flash ECU',
      subtitle: 'Stage tuning & flashing',
      icon: 'flash',
      route: '/flash',
      color: '#FFD700',
    },
    {
      id: 'cheatsheets',
      title: 'Cheat Sheets',
      subtitle: 'Popular modifications',
      icon: 'documents',
      route: '/cheat-sheets',
      color: '#FF8C00',
    },
    {
      id: 'history',
      title: 'Transaction History',
      subtitle: 'VIN-based logging',
      icon: 'time',
      route: '/history',
      color: '#00CED1',
    },
  ];

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" />
      
      {/* Header */}
      <View style={styles.header}>
        <View>
          <Text style={styles.headerTitle}>BMW Coding</Text>
          <Text style={styles.headerSubtitle}>Professional Tool</Text>
        </View>
        <TouchableOpacity style={styles.settingsButton}>
          <Ionicons name="settings-outline" size={24} color="#fff" />
        </TouchableOpacity>
      </View>

      {/* Status Bar */}
      <View style={styles.statusBar}>
        <View style={styles.statusItem}>
          <View style={[styles.statusDot, { backgroundColor: connectionStatus === 'connected' ? '#00FF00' : '#FF6347' }]} />
          <Text style={styles.statusText}>
            {connectionStatus === 'connected' ? 'Connected' : 'Disconnected'}
          </Text>
        </View>
        {selectedVehicle && (
          <Text style={styles.vinText}>VIN: {selectedVehicle.vin || 'Not set'}</Text>
        )}
      </View>

      {/* Menu Grid */}
      <ScrollView 
        style={styles.scrollView}
        contentContainerStyle={styles.menuGrid}
        showsVerticalScrollIndicator={false}
      >
        {menuItems.map((item) => (
          <TouchableOpacity
            key={item.id}
            style={styles.menuCard}
            onPress={() => router.push(item.route as any)}
            activeOpacity={0.7}
          >
            <View style={[styles.iconContainer, { backgroundColor: item.color + '20' }]}>
              <Ionicons name={item.icon as any} size={32} color={item.color} />
            </View>
            <View style={styles.menuTextContainer}>
              <Text style={styles.menuTitle}>{item.title}</Text>
              <Text style={styles.menuSubtitle}>{item.subtitle}</Text>
            </View>
            <Ionicons name="chevron-forward" size={20} color="#555" />
          </TouchableOpacity>
        ))}
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
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 24,
    paddingTop: 60,
    paddingBottom: 20,
  },
  headerTitle: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#fff',
  },
  headerSubtitle: {
    fontSize: 14,
    color: '#888',
    marginTop: 4,
  },
  settingsButton: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#111',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: '#222',
  },
  statusBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 24,
    paddingVertical: 16,
    backgroundColor: '#111',
    marginHorizontal: 24,
    borderRadius: 12,
    marginBottom: 24,
  },
  statusItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  statusText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
  },
  vinText: {
    color: '#888',
    fontSize: 12,
  },
  scrollView: {
    flex: 1,
  },
  menuGrid: {
    paddingHorizontal: 24,
    paddingBottom: 40,
  },
  menuCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#111',
    borderRadius: 16,
    padding: 20,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#222',
  },
  iconContainer: {
    width: 64,
    height: 64,
    borderRadius: 32,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 16,
  },
  menuTextContainer: {
    flex: 1,
  },
  menuTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 4,
  },
  menuSubtitle: {
    fontSize: 14,
    color: '#888',
  },
});
