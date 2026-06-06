import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_link_vr/features/home/presentation/home_screen.dart';
import 'package:photo_link_vr/features/photos/application/photo_map_providers.dart';
import 'package:photo_link_vr/features/photos/data/local_photo_repository.dart';
import 'package:latlong2/latlong.dart' as geo;

void main() {
  testWidgets('connects place map, album and stack views', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPhotoRepositoryProvider.overrideWithValue(
            _FakeLocalPhotoRepository(),
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('地点链接 · 漫游地图'), findsOneWidget);
    expect(find.text('漫游地图'), findsOneWidget);
    expect(find.text('相册'), findsNothing);
    expect(find.text('相簿'), findsNothing);

    await tester.tap(find.text('学校'));
    await tester.pumpAndSettle();

    expect(find.text('Edinburgh · 8 张照片'), findsOneWidget);
    expect(find.text('相册'), findsOneWidget);
    expect(find.text('相簿'), findsOneWidget);

    await tester.tap(find.text('相册'));
    await tester.pumpAndSettle();

    expect(find.text('Edinburgh'), findsOneWidget);
    expect(find.text('8 / 8'), findsOneWidget);
    expect(find.text('50.7192, -1.8808'), findsOneWidget);

    await tester.tap(find.text('相簿'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('地点详情'), findsOneWidget);
  });
}

class _FakeLocalPhotoRepository extends LocalPhotoRepository {
  @override
  Future<PhotoMapLoadResult> loadPhotoMap({
    int scanLimit = 250,
    int markerLimit = 80,
  }) async {
    return const PhotoMapLoadResult(
      demoMode: true,
      photos: [
        PhotoMapItem(
          areaType: PhotoAreaType.school,
          isDemo: true,
          position: geo.LatLng(31.2986, 121.5032),
          title: '学校照片 1',
        ),
        PhotoMapItem(
          areaType: PhotoAreaType.school,
          isDemo: true,
          position: geo.LatLng(31.2994, 121.5040),
          title: '学校照片 2',
        ),
      ],
      scannedCount: 2,
      supportsLocalPhotos: false,
      withoutLocationCount: 0,
    );
  }
}
