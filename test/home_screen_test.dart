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

    expect(find.text('时空环 · 地图漫游'), findsOneWidget);
    expect(find.text('地图漫游'), findsOneWidget);
    expect(find.text('相册'), findsNothing);
    expect(find.text('相簿'), findsNothing);

    await tester.tap(find.text('学校'));
    await tester.pumpAndSettle();

    expect(find.text('学校 · 2 张照片'), findsOneWidget);
    expect(find.text('学校'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('31.2990, 121.5036'), findsOneWidget);
    expect(find.text('相册'), findsNothing);
    expect(find.text('相簿'), findsNothing);

    await tester.tap(find.text('地图漫游'));
    await tester.pumpAndSettle();

    expect(find.text('时空环 · 地图漫游'), findsOneWidget);
    expect(find.text('相册'), findsNothing);
    expect(find.text('相簿'), findsNothing);

    await tester.tap(find.text('学校'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('相册'), findsNothing);
    expect(find.text('相簿'), findsNothing);
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
