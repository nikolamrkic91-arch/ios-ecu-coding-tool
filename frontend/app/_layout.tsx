import { Stack } from 'expo-router';
import { SafeAreaProvider } from 'react-native-safe-area-context';

export default function RootLayout() {
  return (
    <SafeAreaProvider>
      <Stack
        screenOptions={{
          headerShown: false,
          contentStyle: { backgroundColor: '#000' },
          animation: 'slide_from_right',
        }}
      >
        <Stack.Screen name="index" />
        <Stack.Screen name="home" />
        <Stack.Screen name="vehicle-select" />
        <Stack.Screen name="connection" />
        <Stack.Screen name="coding" />
        <Stack.Screen name="cheat-sheets" />
        <Stack.Screen name="history" />
        <Stack.Screen name="flash" />
      </Stack>
    </SafeAreaProvider>
  );
}
