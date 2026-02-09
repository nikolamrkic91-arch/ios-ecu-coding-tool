import { View, Text, StyleSheet, TouchableOpacity, ScrollView, TextInput, StatusBar } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useState } from 'react';
import { useVehicleStore } from '../store/vehicleStore';

const BMW_SERIES = [
  { id: 'f-series', name: 'F-Series', models: ['F10', 'F20', 'F30', 'F32', 'F80', 'F82'] },
  { id: 'g-series', name: 'G-Series', models: ['G01', 'G05', 'G07', 'G20', 'G30', 'G80', 'G82'] },
  { id: 'e-series', name: 'E-Series', models: ['E60', 'E90', 'E92', 'E70', 'E71'] },
];

export default function VehicleSelectScreen() {
  const router = useRouter();
  const { setVehicle } = useVehicleStore();
  const [selectedSeries, setSelectedSeries] = useState<string | null>(null);
  const [selectedModel, setSelectedModel] = useState<string | null>(null);
  const [year, setYear] = useState('');
  const [vin, setVin] = useState('');

  const handleContinue = () => {
    if (selectedSeries && selectedModel && year) {
      setVehicle({
        series: selectedSeries,
        model: selectedModel,
        year,
        vin: vin || undefined,
      });
      router.back();
    }
  };

  const selectedSeriesData = BMW_SERIES.find(s => s.id === selectedSeries);

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" />
      
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
          <Ionicons name="arrow-back" size={24} color="#fff" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Vehicle Selection</Text>
        <View style={{ width: 48 }} />
      </View>

      <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
        {/* Series Selection */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Select Series</Text>
          <View style={styles.seriesGrid}>
            {BMW_SERIES.map((series) => (
              <TouchableOpacity
                key={series.id}
                style={[
                  styles.seriesCard,
                  selectedSeries === series.id && styles.seriesCardSelected,
                ]}
                onPress={() => {
                  setSelectedSeries(series.id);
                  setSelectedModel(null);
                }}
                activeOpacity={0.7}
              >
                <Ionicons 
                  name="car-sport" 
                  size={32} 
                  color={selectedSeries === series.id ? '#1E90FF' : '#888'} 
                />
                <Text style={[
                  styles.seriesName,
                  selectedSeries === series.id && styles.seriesNameSelected,
                ]}>
                  {series.name}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* Model Selection */}
        {selectedSeriesData && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Select Model</Text>
            <View style={styles.modelGrid}>
              {selectedSeriesData.models.map((model) => (
                <TouchableOpacity
                  key={model}
                  style={[
                    styles.modelChip,
                    selectedModel === model && styles.modelChipSelected,
                  ]}
                  onPress={() => setSelectedModel(model)}
                  activeOpacity={0.7}
                >
                  <Text style={[
                    styles.modelText,
                    selectedModel === model && styles.modelTextSelected,
                  ]}>
                    {model}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>
        )}

        {/* Year Input */}
        {selectedModel && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Production Year</Text>
            <TextInput
              style={styles.input}
              placeholder="e.g., 2020"
              placeholderTextColor="#555"
              value={year}
              onChangeText={setYear}
              keyboardType="numeric"
              maxLength={4}
            />
          </View>
        )}

        {/* VIN Input */}
        {year && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>VIN (Optional)</Text>
            <TextInput
              style={styles.input}
              placeholder="17-character VIN"
              placeholderTextColor="#555"
              value={vin}
              onChangeText={(text) => setVin(text.toUpperCase())}
              maxLength={17}
              autoCapitalize="characters"
            />
          </View>
        )}

        {/* Continue Button */}
        {selectedModel && year && (
          <TouchableOpacity
            style={styles.continueButton}
            onPress={handleContinue}
            activeOpacity={0.8}
          >
            <Text style={styles.continueButtonText}>Continue</Text>
            <Ionicons name="checkmark" size={24} color="#fff" />
          </TouchableOpacity>
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
  section: {
    marginBottom: 32,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 16,
  },
  seriesGrid: {
    flexDirection: 'row',
    gap: 12,
  },
  seriesCard: {
    flex: 1,
    backgroundColor: '#111',
    borderRadius: 16,
    padding: 24,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#222',
  },
  seriesCardSelected: {
    borderColor: '#1E90FF',
    backgroundColor: '#1E90FF10',
  },
  seriesName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#888',
    marginTop: 12,
  },
  seriesNameSelected: {
    color: '#1E90FF',
  },
  modelGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  modelChip: {
    backgroundColor: '#111',
    borderRadius: 12,
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderWidth: 1,
    borderColor: '#222',
  },
  modelChipSelected: {
    backgroundColor: '#1E90FF',
    borderColor: '#1E90FF',
  },
  modelText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#888',
  },
  modelTextSelected: {
    color: '#fff',
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
  continueButton: {
    backgroundColor: '#1E90FF',
    borderRadius: 16,
    padding: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
    marginTop: 16,
  },
  continueButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
  },
});
