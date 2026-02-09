import { View, Text, StyleSheet, TouchableOpacity, StatusBar, Image } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';

export default function WelcomeScreen() {
  const router = useRouter();

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" />
      
      {/* BMW Logo Area */}
      <View style={styles.logoContainer}>
        <View style={styles.bmwLogo}>
          <Text style={styles.bmwText}>BMW</Text>
        </View>
        <Text style={styles.title}>ECU Coding Tool</Text>
        <Text style={styles.subtitle}>Professional Diagnostic System</Text>
      </View>

      {/* Features Grid */}
      <View style={styles.featuresContainer}>
        <View style={styles.featureRow}>
          <View style={styles.featureCard}>
            <Ionicons name="flash" size={28} color="#1E90FF" />
            <Text style={styles.featureText}>Stage Tuning</Text>
          </View>
          <View style={styles.featureCard}>
            <Ionicons name="wifi" size={28} color="#1E90FF" />
            <Text style={styles.featureText}>Multi-Connect</Text>
          </View>
        </View>
        <View style={styles.featureRow}>
          <View style={styles.featureCard}>
            <Ionicons name="car-sport" size={28} color="#1E90FF" />
            <Text style={styles.featureText}>F/G/E Series</Text>
          </View>
          <View style={styles.featureCard}>
            <Ionicons name="shield-checkmark" size={28} color="#1E90FF" />
            <Text style={styles.featureText}>PSdZData</Text>
          </View>
        </View>
      </View>

      {/* Start Button */}
      <TouchableOpacity 
        style={styles.startButton}
        onPress={() => router.push('/home')}
        activeOpacity={0.8}
      >
        <Text style={styles.startButtonText}>Start Coding</Text>
        <Ionicons name="arrow-forward" size={24} color="#fff" />
      </TouchableOpacity>

      <Text style={styles.versionText}>v1.0.0 • Licensed Professional Tool</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
    paddingHorizontal: 24,
    paddingTop: 60,
    paddingBottom: 40,
  },
  logoContainer: {
    alignItems: 'center',
    marginTop: 40,
    marginBottom: 60,
  },
  bmwLogo: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: '#1E90FF',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 24,
    shadowColor: '#1E90FF',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.6,
    shadowRadius: 16,
    elevation: 10,
  },
  bmwText: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#fff',
    letterSpacing: 4,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#888',
  },
  featuresContainer: {
    flex: 1,
    justifyContent: 'center',
  },
  featureRow: {
    flexDirection: 'row',
    marginBottom: 16,
    gap: 16,
  },
  featureCard: {
    flex: 1,
    backgroundColor: '#111',
    borderRadius: 16,
    padding: 24,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#222',
  },
  featureText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
    marginTop: 12,
    textAlign: 'center',
  },
  startButton: {
    backgroundColor: '#1E90FF',
    borderRadius: 16,
    padding: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
    shadowColor: '#1E90FF',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.4,
    shadowRadius: 12,
    elevation: 8,
  },
  startButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
  },
  versionText: {
    color: '#555',
    textAlign: 'center',
    marginTop: 24,
    fontSize: 12,
  },
});
