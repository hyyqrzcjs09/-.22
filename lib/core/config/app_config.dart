abstract final class AppConfig {
  static const appName = 'PhotoLink VR';

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  static const mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
  );

  static const mapboxStyle = String.fromEnvironment(
    'MAPBOX_STYLE',
    defaultValue: 'mapbox/streets-v12',
  );

  static bool get hasMapboxAccessToken => mapboxAccessToken.isNotEmpty;

  static String get mapboxTileUrl =>
      'https://api.mapbox.com/styles/v1/$mapboxStyle/tiles/512/{z}/{x}/{y}'
      '?access_token=$mapboxAccessToken';
}
