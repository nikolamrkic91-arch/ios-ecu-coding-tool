import { View, Text, StyleSheet, TouchableOpacity, ScrollView, StatusBar, RefreshControl } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useState, useEffect } from 'react';
import axios from 'axios';
import { format } from 'date-fns';

const EXPO_PUBLIC_BACKEND_URL = process.env.EXPO_PUBLIC_BACKEND_URL;

interface Transaction {
  id: string;
  type: 'coding' | 'flash' | 'cheatsheet';
  vin: string;
  vehicle: string;
  description: string;
  timestamp: string;
  status: 'success' | 'failed';
  details?: any;
}

export default function HistoryScreen() {
  const router = useRouter();
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadTransactions = async () => {
    try {
      const response = await axios.get(`${EXPO_PUBLIC_BACKEND_URL}/api/history/transactions`);
      setTransactions(response.data.transactions || []);
    } catch (error) {
      console.error('Load transactions error:', error);
      // Mock data for demo
      setTransactions([
        {
          id: '1',
          type: 'flash',
          vin: 'WBADT43452G123456',
          vehicle: 'F30 335i',
          description: 'Stage 1 Flash Applied',
          timestamp: new Date().toISOString(),
          status: 'success',
        },
        {
          id: '2',
          type: 'cheatsheet',
          vin: 'WBADT43452G123456',
          vehicle: 'F30 335i',
          description: 'SCR1 Remote Engine Start',
          timestamp: new Date(Date.now() - 3600000).toISOString(),
          status: 'success',
        },
        {
          id: '3',
          type: 'coding',
          vin: 'WBADT43452G123456',
          vehicle: 'F30 335i',
          description: 'CAFD 3000_HU_CIC Parameter Edit',
          timestamp: new Date(Date.now() - 7200000).toISOString(),
          status: 'success',
        },
      ]);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadTransactions();
  }, []);

  const onRefresh = () => {
    setRefreshing(true);
    loadTransactions();
  };

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'flash': return 'flash';
      case 'coding': return 'code-slash';
      case 'cheatsheet': return 'documents';
      default: return 'document';
    }
  };

  const getTypeColor = (type: string) => {
    switch (type) {
      case 'flash': return '#FFD700';
      case 'coding': return '#9370DB';
      case 'cheatsheet': return '#FF8C00';
      default: return '#888';
    }
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" />
      
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
          <Ionicons name="arrow-back" size={24} color="#fff" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Transaction History</Text>
        <View style={{ width: 48 }} />
      </View>

      <ScrollView 
        style={styles.scrollView} 
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl 
            refreshing={refreshing} 
            onRefresh={onRefresh}
            tintColor="#1E90FF"
          />
        }
      >
        {loading ? (
          <View style={styles.loadingContainer}>
            <Text style={styles.loadingText}>Loading transactions...</Text>
          </View>
        ) : transactions.length === 0 ? (
          <View style={styles.emptyState}>
            <Ionicons name="time-outline" size={64} color="#333" />
            <Text style={styles.emptyText}>No transactions yet</Text>
            <Text style={styles.emptySubtext}>Start coding to see history here</Text>
          </View>
        ) : (
          transactions.map((transaction) => (
            <View key={transaction.id} style={styles.transactionCard}>
              <View style={styles.transactionHeader}>
                <View style={[styles.typeIcon, { backgroundColor: getTypeColor(transaction.type) + '20' }]}>
                  <Ionicons 
                    name={getTypeIcon(transaction.type) as any} 
                    size={24} 
                    color={getTypeColor(transaction.type)} 
                  />
                </View>
                <View style={styles.transactionInfo}>
                  <Text style={styles.transactionDescription}>{transaction.description}</Text>
                  <Text style={styles.transactionVehicle}>
                    {transaction.vehicle} • {transaction.vin}
                  </Text>
                </View>
                <View style={[
                  styles.statusBadge, 
                  { backgroundColor: transaction.status === 'success' ? '#00FF0020' : '#FF634720' }
                ]}>
                  <Ionicons 
                    name={transaction.status === 'success' ? 'checkmark-circle' : 'close-circle'} 
                    size={20} 
                    color={transaction.status === 'success' ? '#00FF00' : '#FF6347'} 
                  />
                </View>
              </View>

              <View style={styles.transactionFooter}>
                <View style={styles.timestampContainer}>
                  <Ionicons name="time" size={14} color="#888" />
                  <Text style={styles.timestamp}>
                    {format(new Date(transaction.timestamp), 'MMM dd, yyyy • HH:mm')}
                  </Text>
                </View>
                <TouchableOpacity style={styles.detailsButton}>
                  <Text style={styles.detailsButtonText}>Details</Text>
                  <Ionicons name="chevron-forward" size={16} color="#1E90FF" />
                </TouchableOpacity>
              </View>
            </View>
          ))
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
  scrollView: {
    flex: 1,
    paddingHorizontal: 24,
  },
  loadingContainer: {
    paddingVertical: 60,
    alignItems: 'center',
  },
  loadingText: {
    fontSize: 16,
    color: '#888',
  },
  emptyState: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 80,
  },
  emptyText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#555',
    marginTop: 16,
  },
  emptySubtext: {
    fontSize: 14,
    color: '#444',
    marginTop: 8,
  },
  transactionCard: {
    backgroundColor: '#111',
    borderRadius: 16,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#222',
  },
  transactionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  typeIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  transactionInfo: {
    flex: 1,
  },
  transactionDescription: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 4,
  },
  transactionVehicle: {
    fontSize: 13,
    color: '#888',
  },
  statusBadge: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  transactionFooter: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#222',
  },
  timestampContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  timestamp: {
    fontSize: 12,
    color: '#888',
  },
  detailsButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  detailsButtonText: {
    fontSize: 14,
    color: '#1E90FF',
    fontWeight: '600',
  },
});
