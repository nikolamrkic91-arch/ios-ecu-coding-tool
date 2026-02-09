import { View, Text, StyleSheet, TouchableOpacity, ScrollView, StatusBar, Alert, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useState } from 'react';
import axios from 'axios';
import { useVehicleStore } from '../store/vehicleStore';
import { useConnectionStore } from '../store/connectionStore';

const EXPO_PUBLIC_BACKEND_URL = process.env.EXPO_PUBLIC_BACKEND_URL;

interface FlashStage {
  id: string;
  name: string;
  description: string;
  power: string;
  torque: string;
  changes: string[];
  difficulty: 'Easy' | 'Medium' | 'Hard';
  duration: string;
}

const FLASH_STAGES: FlashStage[] = [
  {
    id: 'stage1',
    name: 'Stage 1',
    description: 'ECU remap with stock hardware',
    power: '+30-50 HP',
    torque: '+60-80 Nm',
    changes: [
      'Fuel mapping optimization',
      'Ignition timing adjustment',
      'Boost pressure increase',
      'Rev limiter modification',
    ],
    difficulty: 'Easy',
    duration: '15-20 min',
  },
  {
    id: 'stage2',
    name: 'Stage 2',
    description: 'Requires exhaust/intake upgrades',
    power: '+60-100 HP',
    torque: '+100-130 Nm',
    changes: [
      'Aggressive fuel mapping',
      'Advanced timing tables',
      'Higher boost levels',
      'Turbo spool optimization',
    ],
    difficulty: 'Medium',
    duration: '20-30 min',
  },
  {
    id: 'stage3',
    name: 'Stage 3',
    description: 'Full turbo upgrade required',
    power: '+100-150 HP',
    torque: '+150-200 Nm',
    changes: [
      'Custom turbo mapping',
      'Race fuel calibration',
      'Launch control activation',
      'Pops & bangs (optional)',
    ],
    difficulty: 'Hard',
    duration: '30-45 min',
  },
];

export default function FlashScreen() {
  const router = useRouter();
  const { selectedVehicle } = useVehicleStore();
  const { connectionStatus } = useConnectionStore();
  const [selectedStage, setSelectedStage] = useState<string | null>(null);
  const [flashing, setFlashing] = useState(false);
  const [progress, setProgress] = useState(0);
  const [currentStep, setCurrentStep] = useState('');

  const handleFlash = async (stage: FlashStage) => {
    if (connectionStatus !== 'connected') {
      Alert.alert('Not Connected', 'Please connect to vehicle first');
      return;
    }

    if (!selectedVehicle) {
      Alert.alert('No Vehicle', 'Please select a vehicle first');
      return;
    }

    Alert.alert(
      'Confirm Flash',
      `Flash ${stage.name} to your ${selectedVehicle.series} ${selectedVehicle.model}?\n\nWARNING: This will modify your ECU. Ensure proper modifications are installed.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Flash',
          style: 'destructive',
          onPress: () => performFlash(stage),
        },
      ]
    );
  };

  const performFlash = async (stage: FlashStage) => {
    setFlashing(true);
    setSelectedStage(stage.id);
    setProgress(0);

    const steps = [
      { step: 'Reading ECU...', duration: 3000, progress: 20 },
      { step: 'Backing up original...', duration: 2000, progress: 40 },
      { step: 'Preparing flash file...', duration: 2000, progress: 60 },
      { step: 'Writing to ECU...', duration: 4000, progress: 85 },
      { step: 'Verifying...', duration: 2000, progress: 100 },
    ];

    try {
      for (const { step, duration, progress: stepProgress } of steps) {
        setCurrentStep(step);
        await new Promise(resolve => setTimeout(resolve, duration));
        setProgress(stepProgress);
      }

      // Call backend API
      const response = await axios.post(
        `${EXPO_PUBLIC_BACKEND_URL}/api/flash/apply`,
        {
          stageId: stage.id,
          vehicle: selectedVehicle,
        }
      );

      Alert.alert(
        'Flash Complete',
        `${stage.name} successfully applied!\n\nNew power: ${stage.power}\nNew torque: ${stage.torque}`
      );
    } catch (error: any) {
      Alert.alert('Flash Failed', error.response?.data?.message || 'Failed to flash ECU');
    } finally {
      setFlashing(false);
      setSelectedStage(null);
      setProgress(0);
      setCurrentStep('');
    }
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
        <Text style={styles.headerTitle}>Flash ECU</Text>
        <View style={{ width: 48 }} />
      </View>

      {flashing ? (
        <View style={styles.flashingContainer}>
          <View style={styles.flashingContent}>
            <Ionicons name="flash" size={64} color="#FFD700" />
            <Text style={styles.flashingTitle}>Flashing ECU...</Text>
            <Text style={styles.flashingStep}>{currentStep}</Text>
            
            <View style={styles.progressBarContainer}>
              <View style={[styles.progressBar, { width: `${progress}%` }]} />
            </View>
            <Text style={styles.progressText}>{progress}%</Text>

            <View style={styles.warningBox}>
              <Ionicons name="warning" size={24} color="#FFD700" />
              <Text style={styles.warningText}>
                Do not disconnect or turn off vehicle during flashing
              </Text>
            </View>
          </View>
        </View>
      ) : (
        <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
          {/* Warning Banner */}
          <View style={styles.warningBanner}>
            <Ionicons name="warning" size={28} color="#FFD700" />
            <View style={styles.warningTextContainer}>
              <Text style={styles.warningTitle}>Safety Notice</Text>
              <Text style={styles.warningDescription}>
                ECU flashing modifies engine parameters. Ensure vehicle has proper modifications installed.
              </Text>
            </View>
          </View>

          {/* Stage Cards */}
          {FLASH_STAGES.map((stage) => (
            <View key={stage.id} style={styles.stageCard}>
              <View style={styles.stageHeader}>
                <View style={styles.stageIconContainer}>
                  <Ionicons name="flash" size={32} color="#FFD700" />
                </View>
                <View style={styles.stageHeaderText}>
                  <Text style={styles.stageName}>{stage.name}</Text>
                  <Text style={styles.stageDescription}>{stage.description}</Text>
                </View>
              </View>

              {/* Stats */}
              <View style={styles.statsRow}>
                <View style={styles.statBox}>
                  <Ionicons name="speedometer" size={24} color="#1E90FF" />
                  <Text style={styles.statValue}>{stage.power}</Text>
                  <Text style={styles.statLabel}>Power</Text>
                </View>
                <View style={styles.statBox}>
                  <Ionicons name="flash" size={24} color="#9370DB" />
                  <Text style={styles.statValue}>{stage.torque}</Text>
                  <Text style={styles.statLabel}>Torque</Text>
                </View>
                <View style={styles.statBox}>
                  <Ionicons name="time" size={24} color="#00CED1" />
                  <Text style={styles.statValue}>{stage.duration}</Text>
                  <Text style={styles.statLabel}>Duration</Text>
                </View>
              </View>

              {/* Changes List */}
              <View style={styles.changesContainer}>
                <Text style={styles.changesTitle}>Modifications:</Text>
                {stage.changes.map((change, index) => (
                  <View key={index} style={styles.changeRow}>
                    <Ionicons name="checkmark-circle" size={18} color="#1E90FF" />
                    <Text style={styles.changeText}>{change}</Text>
                  </View>
                ))}
              </View>

              {/* Difficulty Badge */}
              <View style={styles.metaRow}>
                <View style={[styles.difficultyBadge, { backgroundColor: getDifficultyColor(stage.difficulty) + '20' }]}>
                  <Text style={[styles.difficultyText, { color: getDifficultyColor(stage.difficulty) }]}>
                    {stage.difficulty}
                  </Text>
                </View>
              </View>

              {/* Flash Button */}
              <TouchableOpacity
                style={styles.flashButton}
                onPress={() => handleFlash(stage)}
                activeOpacity={0.8}
              >
                <Text style={styles.flashButtonText}>Flash {stage.name}</Text>
                <Ionicons name="flash" size={24} color="#000" />
              </TouchableOpacity>
            </View>
          ))}

          <View style={{ height: 40 }} />
        </ScrollView>
      )}
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
  warningBanner: {
    flexDirection: 'row',
    backgroundColor: '#FFD70010',
    borderRadius: 12,
    padding: 16,
    marginBottom: 24,
    borderWidth: 1,
    borderColor: '#FFD70030',
  },
  warningTextContainer: {
    flex: 1,
    marginLeft: 12,
  },
  warningTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#FFD700',
    marginBottom: 4,
  },
  warningDescription: {
    fontSize: 14,
    color: '#888',
    lineHeight: 20,
  },
  stageCard: {
    backgroundColor: '#111',
    borderRadius: 16,
    padding: 20,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#222',
  },
  stageHeader: {
    flexDirection: 'row',
    marginBottom: 16,
  },
  stageIconContainer: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: '#FFD70020',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  stageHeaderText: {
    flex: 1,
  },
  stageName: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFD700',
    marginBottom: 4,
  },
  stageDescription: {
    fontSize: 14,
    color: '#888',
  },
  statsRow: {
    flexDirection: 'row',
    marginBottom: 16,
    gap: 12,
  },
  statBox: {
    flex: 1,
    backgroundColor: '#000',
    borderRadius: 12,
    padding: 12,
    alignItems: 'center',
  },
  statValue: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#fff',
    marginTop: 8,
  },
  statLabel: {
    fontSize: 12,
    color: '#888',
    marginTop: 4,
  },
  changesContainer: {
    backgroundColor: '#000',
    borderRadius: 12,
    padding: 12,
    marginBottom: 16,
  },
  changesTitle: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#1E90FF',
    marginBottom: 8,
  },
  changeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 6,
    gap: 8,
  },
  changeText: {
    fontSize: 14,
    color: '#ccc',
  },
  metaRow: {
    marginBottom: 16,
  },
  difficultyBadge: {
    alignSelf: 'flex-start',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 6,
  },
  difficultyText: {
    fontSize: 14,
    fontWeight: 'bold',
  },
  flashButton: {
    backgroundColor: '#FFD700',
    borderRadius: 12,
    padding: 18,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  flashButtonText: {
    color: '#000',
    fontSize: 18,
    fontWeight: 'bold',
  },
  flashingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 24,
  },
  flashingContent: {
    alignItems: 'center',
    width: '100%',
  },
  flashingTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#fff',
    marginTop: 24,
  },
  flashingStep: {
    fontSize: 16,
    color: '#888',
    marginTop: 12,
  },
  progressBarContainer: {
    width: '100%',
    height: 8,
    backgroundColor: '#222',
    borderRadius: 4,
    marginTop: 32,
    overflow: 'hidden',
  },
  progressBar: {
    height: '100%',
    backgroundColor: '#FFD700',
  },
  progressText: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#FFD700',
    marginTop: 16,
  },
  warningBox: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFD70010',
    borderRadius: 12,
    padding: 16,
    marginTop: 32,
    borderWidth: 1,
    borderColor: '#FFD70030',
    gap: 12,
  },
  warningText: {
    flex: 1,
    fontSize: 14,
    color: '#FFD700',
    lineHeight: 20,
  },
});
