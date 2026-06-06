import 'package:flutter_test/flutter_test.dart';
import 'package:photo_link_vr/core/config/app_config.dart';

void main() {
  test('uses Mapbox satellite streets style by default', () {
    expect(
      AppConfig.mapboxStyle,
      'mapbox://styles/mapbox/satellite-streets-v12',
    );
    expect(AppConfig.mapboxStylePath, 'mapbox/satellite-streets-v12');
    expect(
      AppConfig.mapboxTileUrl,
      contains('/mapbox/satellite-streets-v12/tiles/512/'),
    );
  });
}
