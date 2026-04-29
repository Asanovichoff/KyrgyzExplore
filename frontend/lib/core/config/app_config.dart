class AppConfig {
  AppConfig._();

  // Injected at build time via --dart-define.
  // Example: flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
  //
  // WHY 10.0.2.2 as default? Android emulators use 10.0.2.2 to reach the host
  // machine's localhost. iOS simulators use localhost directly. The default here
  // serves Android emulator dev; override with --dart-define for iOS or real devices.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  static const wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://10.0.2.2:8080',
  );

  static const mapsKey = String.fromEnvironment('MAPS_KEY', defaultValue: '');
}
