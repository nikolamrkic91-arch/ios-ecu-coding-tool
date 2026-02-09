import { View, Text, StyleSheet, TouchableOpacity, ScrollView, StatusBar, Alert } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useState } from 'react';
import axios from 'axios';
import { useVehicleStore } from '../store/vehicleStore';

const EXPO_PUBLIC_BACKEND_URL = process.env.EXPO_PUBLIC_BACKEND_URL;

interface CheatSheet {
  id: string;
  title: string;
  category: string;
  description: string;
  parameters: { name: string; value: string }[];
  series: string[];
  difficulty: 'Easy' | 'Medium' | 'Hard';
  icon: string;
}

const CHEAT_SHEETS: CheatSheet[] = [
  {
    id: 'scr1',
    title: 'SCR1 Remote Engine Start',
    category: 'Comfort',
    description: 'Enable remote engine start via key fob',
    parameters: [
      { name: 'CAFD: 3000_HU_CIC', value: 'SCR_VERBAU = aktiv' },
      { name: 'CAFD: 3000_HU_CIC', value: 'SCR_ANZEIGE = aktiv' },
    ],
    series: ['F-Series', 'G-Series'],
    difficulty: 'Easy',
    icon: 'key',
  },
  {
    id: 'angel_eyes',
    title: 'Angel Eyes Brightness',
    category: 'Lighting',
    description: 'Increase angel eyes LED brightness',
    parameters: [
      { name: 'CAFD: 3000_FRM', value: 'LICHT_HELLIGKEIT = 100' },
    ],
    series: ['F-Series'],
    difficulty: 'Easy',
    icon: 'bulb',
  },
  {
    id: 'exhaust_flaps',
    title: 'Exhaust Flaps Always Open',
    category: 'Performance',
    description: 'Keep exhaust flaps open for louder sound',
    parameters: [
      { name: 'CAFD: 3000_DME', value: 'KLAPPE_OFFEN = dauerhaft' },
    ],
    series: ['F-Series', 'G-Series'],
    difficulty: 'Medium',
    icon: 'speedometer',
  },
  {
    id: 'video_in_motion',
    title: 'Video in Motion',
    category: 'Infotainment',
    description: 'Allow video playback while driving',
    parameters: [
      { name: 'CAFD: 3000_HU_NBT', value: 'VIDEO_FREIGABE = aktiv' },
    ],
    series: ['F-Series', 'G-Series', 'E-Series'],
    difficulty: 'Easy',
    icon: 'videocam',
  },
  {
    id: 'needle_sweep',
    title: 'Needle Sweep Animation',
    category: 'Visual',
    description: 'Enable gauge needle sweep on startup',
    parameters: [
      { name: 'CAFD: 3000_KOMBI', value: 'NADELANZEIGE = aktiv' },
    ],
    series: ['F-Series'],
    difficulty: 'Easy',
    icon: 'speedometer-outline',
  },
  {
    id: 'drl_brightness',
    title: 'DRL Brightness',
    category: 'Lighting',
    description: 'Adjust daytime running lights brightness',
    parameters: [
      { name: 'CAFD: 3000_FRM', value: 'TFL_HELLIGKEIT = 100' },
    ],
    series: ['F-Series', 'G-Series'],
    difficulty: 'Easy',
    icon: 'sunny',
  },
];

export default function CheatSheetsScreen() {
  const router = useRouter();
  const { selectedVehicle } = useVehicleStore();
  const [selectedCategory, setSelectedCategory] = useState<string>('All');
  const [applyingId, setApplyingId] = useState<string | null>(null);

  const categories = ['All', 'Comfort', 'Lighting', 'Performance', 'Infotainment', 'Visual'];

  const filteredSheets = CHEAT_SHEETS.filter(sheet => {
    const categoryMatch = selectedCategory === 'All' || sheet.category === selectedCategory;
    // Show all if no vehicle selected, or if vehicle series matches
    const seriesMatch = !selectedVehicle || sheet.series.some(s => s.includes(selectedVehicle.series) || selectedVehicle.series.includes(s.split('-')[0]));
    return categoryMatch && seriesMatch;
  });

  const handleApply = async (sheet: CheatSheet) => {
    if (!selectedVehicle) {
      Alert.alert('No Vehicle', 'Please select a vehicle first');
      return;
    }

    Alert.alert(
      'Apply Coding',
      `Apply "${sheet.title}" to your ${selectedVehicle.series} ${selectedVehicle.model}?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Apply',
          onPress: async () => {
            setApplyingId(sheet.id);
            try {
              const response = await axios.post(
                `${EXPO_PUBLIC_BACKEND_URL}/api/coding/apply-cheatsheet`,
                {
                  sheetId: sheet.id,
                  vehicle: selectedVehicle,
                }
              );
              Alert.alert('Success', 'Coding applied successfully!');
            } catch (error: any) {
              Alert.alert('Error', error.response?.data?.message || 'Failed to apply coding');
            } finally {
              setApplyingId(null);
            }
          },
        },
      ]
    );
  };

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'Easy': return '#00FF00';
      case 'Medium': return '#FFD700';
      case 'Hard': return '#FF6347';
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
        <Text style={styles.headerTitle}>Cheat Sheets</Text>
        <View style={{ width: 48 }} />
      </View>

      {/* Category Filter */}
      <ScrollView 
        horizontal 
        showsHorizontalScrollIndicator={false}
        style={styles.categoryScroll}
        contentContainerStyle={styles.categoryContainer}
      >
        {categories.map((category) => (
          <TouchableOpacity
            key={category}
            style={[
              styles.categoryChip,
              selectedCategory === category && styles.categoryChipSelected,
            ]}
            onPress={() => setSelectedCategory(category)}
            activeOpacity={0.7}
          >
            <Text style={[
              styles.categoryText,
              selectedCategory === category && styles.categoryTextSelected,
            ]}>
              {category}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>

      {/* Cheat Sheets List */}
      <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
        {filteredSheets.map((sheet) => (
          <View key={sheet.id} style={styles.sheetCard}>
            <View style={styles.sheetHeader}>
              <View style={styles.iconBadge}>
                <Ionicons name={sheet.icon as any} size={24} color="#1E90FF" />
              </View>
              <View style={styles.sheetHeaderText}>
                <Text style={styles.sheetTitle}>{sheet.title}</Text>
                <View style={styles.metaRow}>
                  <View style={[styles.difficultyBadge, { backgroundColor: getDifficultyColor(sheet.difficulty) + '20' }]}>
                    <Text style={[styles.difficultyText, { color: getDifficultyColor(sheet.difficulty) }]}>
                      {sheet.difficulty}
                    </Text>
                  </View>
                  <Text style={styles.categoryLabel}>{sheet.category}</Text>
                </View>
              </View>
            </View>

            <Text style={styles.description}>{sheet.description}</Text>

            {/* Parameters */}
            <View style={styles.parametersContainer}>
              <Text style={styles.parametersTitle}>Parameters:</Text>
              {sheet.parameters.map((param, index) => (
                <View key={index} style={styles.parameterRow}>
                  <View style={styles.parameterDot} />
                  <Text style={styles.parameterText}>
                    <Text style={styles.parameterName}>{param.name}:</Text> {param.value}
                  </Text>
                </View>
              ))}
            </View>

            {/* Series Compatibility */}
            <View style={styles.seriesRow}>
              <Ionicons name="car-sport" size={16} color="#888" />
              <Text style={styles.seriesText}>{sheet.series.join(', ')}</Text>
            </View>

            {/* Apply Button */}
            <TouchableOpacity
              style={styles.applyButton}
              onPress={() => handleApply(sheet)}
              disabled={applyingId === sheet.id}
              activeOpacity={0.8}
            >
              <Text style={styles.applyButtonText}>
                {applyingId === sheet.id ? 'Applying...' : 'Apply Coding'}
              </Text>
              <Ionicons name="flash" size={20} color="#fff" />
            </TouchableOpacity>
          </View>
        ))}

        {filteredSheets.length === 0 && (
          <View style={styles.emptyState}>
            <Ionicons name="documents-outline" size={64} color="#333" />
            <Text style={styles.emptyText}>No cheat sheets found</Text>
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
  categoryScroll: {
    maxHeight: 60,
  },
  categoryContainer: {
    paddingHorizontal: 24,
    paddingVertical: 12,
    gap: 8,
  },
  categoryChip: {
    backgroundColor: '#111',
    borderRadius: 20,
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderWidth: 1,
    borderColor: '#222',
  },
  categoryChipSelected: {
    backgroundColor: '#1E90FF',
    borderColor: '#1E90FF',
  },
  categoryText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#888',
  },
  categoryTextSelected: {
    color: '#fff',
  },
  scrollView: {
    flex: 1,
    paddingHorizontal: 24,
  },
  sheetCard: {
    backgroundColor: '#111',
    borderRadius: 16,
    padding: 20,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#222',
  },
  sheetHeader: {
    flexDirection: 'row',
    marginBottom: 12,
  },
  iconBadge: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#1E90FF20',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  sheetHeaderText: {
    flex: 1,
  },
  sheetTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 6,
  },
  metaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  difficultyBadge: {
    borderRadius: 8,
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  difficultyText: {
    fontSize: 12,
    fontWeight: 'bold',
  },
  categoryLabel: {
    fontSize: 12,
    color: '#888',
  },
  description: {
    fontSize: 14,
    color: '#ccc',
    marginBottom: 16,
    lineHeight: 20,
  },
  parametersContainer: {
    backgroundColor: '#000',
    borderRadius: 12,
    padding: 12,
    marginBottom: 12,
  },
  parametersTitle: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#1E90FF',
    marginBottom: 8,
  },
  parameterRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 6,
  },
  parameterDot: {
    width: 4,
    height: 4,
    borderRadius: 2,
    backgroundColor: '#1E90FF',
    marginTop: 6,
    marginRight: 8,
  },
  parameterText: {
    flex: 1,
    fontSize: 13,
    color: '#888',
    lineHeight: 18,
  },
  parameterName: {
    color: '#ccc',
    fontWeight: '600',
  },
  seriesRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 16,
  },
  seriesText: {
    fontSize: 12,
    color: '#888',
  },
  applyButton: {
    backgroundColor: '#1E90FF',
    borderRadius: 12,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  applyButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  emptyState: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 60,
  },
  emptyText: {
    fontSize: 16,
    color: '#555',
    marginTop: 16,
  },
});
