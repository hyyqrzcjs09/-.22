abstract final class AppConfig {
  static const appName = 'PhotoLink VR';

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );
}
