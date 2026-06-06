import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' as geo;
import 'package:photo_manager/photo_manager.dart';

class PhotoMapItem {
  const PhotoMapItem({
    required this.position,
    required this.title,
    this.asset,
    this.createdAt,
    this.isDemo = false,
  });

  final AssetEntity? asset;
  final DateTime? createdAt;
  final bool isDemo;
  final geo.LatLng position;
  final String title;
}

class PhotoMapLoadResult {
  const PhotoMapLoadResult({
    required this.photos,
    required this.scannedCount,
    required this.withoutLocationCount,
    this.demoMode = false,
    this.permission,
    this.supportsLocalPhotos = true,
  });

  final bool demoMode;
  final List<PhotoMapItem> photos;
  final PermissionState? permission;
  final int scannedCount;
  final bool supportsLocalPhotos;
  final int withoutLocationCount;

  bool get hasAccess => permission?.hasAccess ?? false;
  bool get isLimited => permission?.isLimited ?? false;
}

class LocalPhotoRepository {
  Future<PhotoMapLoadResult> loadPhotoMap({
    int scanLimit = 250,
    int markerLimit = 80,
  }) async {
    if (!_supportsLocalPhotoLibrary) {
      return PhotoMapLoadResult(
        demoMode: true,
        photos: _demoPhotos,
        scannedCount: _demoPhotos.length,
        supportsLocalPhotos: false,
        withoutLocationCount: 0,
      );
    }

    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      return PhotoMapLoadResult(
        photos: const [],
        permission: permission,
        scannedCount: 0,
        withoutLocationCount: 0,
      );
    }

    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.image,
    );
    if (paths.isEmpty) {
      return PhotoMapLoadResult(
        photos: const [],
        permission: permission,
        scannedCount: 0,
        withoutLocationCount: 0,
      );
    }

    final rootPath = paths.first;
    final count = await rootPath.assetCountAsync;
    final scannedCount = count < scanLimit ? count : scanLimit;
    if (scannedCount == 0) {
      return PhotoMapLoadResult(
        photos: const [],
        permission: permission,
        scannedCount: 0,
        withoutLocationCount: 0,
      );
    }

    final assets = await rootPath.getAssetListRange(
      start: 0,
      end: scannedCount,
    );
    final photos = <PhotoMapItem>[];
    var withoutLocationCount = 0;

    for (final asset in assets) {
      final latLng = asset.latLng ?? await asset.latlngAsync();
      if (latLng == null) {
        withoutLocationCount++;
        continue;
      }

      photos.add(
        PhotoMapItem(
          asset: asset,
          createdAt: asset.createDateTime,
          position: geo.LatLng(latLng.latitude, latLng.longitude),
          title: asset.title ?? '本地照片',
        ),
      );

      if (photos.length >= markerLimit) {
        break;
      }
    }

    withoutLocationCount +=
        assets.length - photos.length - withoutLocationCount;

    return PhotoMapLoadResult(
      photos: photos,
      permission: permission,
      scannedCount: assets.length,
      withoutLocationCount: withoutLocationCount,
    );
  }

  static bool get _supportsLocalPhotoLibrary {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }
}

const _demoPhotos = <PhotoMapItem>[
  PhotoMapItem(
    isDemo: true,
    position: geo.LatLng(31.2304, 121.4737),
    title: '演示照片 1',
  ),
  PhotoMapItem(
    isDemo: true,
    position: geo.LatLng(31.2152, 121.4581),
    title: '演示照片 2',
  ),
  PhotoMapItem(
    isDemo: true,
    position: geo.LatLng(31.2447, 121.5060),
    title: '演示照片 3',
  ),
];
