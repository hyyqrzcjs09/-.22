import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' as geo;
import 'package:photo_manager/photo_manager.dart';

enum PhotoAreaType {
  school,
  attraction,
  life,
  other,
}

extension PhotoAreaTypeLabel on PhotoAreaType {
  String get label {
    return switch (this) {
      PhotoAreaType.school => '学校',
      PhotoAreaType.attraction => '景点',
      PhotoAreaType.life => '生活区',
      PhotoAreaType.other => '区域',
    };
  }
}

class PhotoMapItem {
  const PhotoMapItem({
    required this.position,
    required this.title,
    this.areaType = PhotoAreaType.other,
    this.asset,
    this.createdAt,
    this.isDemo = false,
  });

  final PhotoAreaType areaType;
  final AssetEntity? asset;
  final DateTime? createdAt;
  final bool isDemo;
  final geo.LatLng position;
  final String title;
}

class PhotoAreaGroup {
  const PhotoAreaGroup({
    required this.areaType,
    required this.center,
    required this.items,
  });

  final PhotoAreaType areaType;
  final geo.LatLng center;
  final List<PhotoMapItem> items;

  bool get isCluster => items.length >= 2;
}

List<PhotoAreaGroup> buildPhotoAreaGroups(
  List<PhotoMapItem> photos, {
  int minClusterSize = 2,
  double radiusMeters = 700,
}) {
  final groups = <_MutablePhotoAreaGroup>[];

  for (final photo in photos) {
    _MutablePhotoAreaGroup? match;
    for (final group in groups) {
      if (group.areaType != photo.areaType) {
        continue;
      }

      if (_distanceMeters(group.center, photo.position) <= radiusMeters) {
        match = group;
        break;
      }
    }

    if (match == null) {
      groups.add(_MutablePhotoAreaGroup(photo));
    } else {
      match.add(photo);
    }
  }

  return [
    for (final group in groups)
      if (group.items.length >= minClusterSize)
        group.toGroup()
      else
        for (final photo in group.items)
          PhotoAreaGroup(
            areaType: photo.areaType,
            center: photo.position,
            items: [photo],
          ),
  ];
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
          areaType: _inferAreaType(asset.title ?? ''),
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

class _MutablePhotoAreaGroup {
  _MutablePhotoAreaGroup(PhotoMapItem photo)
      : areaType = photo.areaType,
        center = photo.position,
        items = [photo];

  final PhotoAreaType areaType;
  geo.LatLng center;
  final List<PhotoMapItem> items;

  void add(PhotoMapItem photo) {
    final nextCount = items.length + 1;
    center = geo.LatLng(
      ((center.latitude * items.length) + photo.position.latitude) / nextCount,
      ((center.longitude * items.length) + photo.position.longitude) /
          nextCount,
    );
    items.add(photo);
  }

  PhotoAreaGroup toGroup() {
    return PhotoAreaGroup(
      areaType: areaType,
      center: center,
      items: List.unmodifiable(items),
    );
  }
}

PhotoAreaType _inferAreaType(String title) {
  final text = title.toLowerCase();
  if (_containsAny(text, const ['学校', '校园', '大学', '学院', '中学', '小学'])) {
    return PhotoAreaType.school;
  }
  if (_containsAny(text, const ['景点', '公园', '博物馆', '展览', '山', '湖', '塔'])) {
    return PhotoAreaType.attraction;
  }
  if (_containsAny(text, const ['家', '社区', '餐厅', '咖啡', '商场', '生活'])) {
    return PhotoAreaType.life;
  }
  return PhotoAreaType.other;
}

bool _containsAny(String text, List<String> keywords) {
  return keywords.any(text.contains);
}

double _distanceMeters(geo.LatLng a, geo.LatLng b) {
  const earthRadiusMeters = 6371000.0;
  final dLat = _degreesToRadians(b.latitude - a.latitude);
  final dLng = _degreesToRadians(b.longitude - a.longitude);
  final lat1 = _degreesToRadians(a.latitude);
  final lat2 = _degreesToRadians(b.latitude);
  final h =
      _sinHalfSquared(dLat) + _sinHalfSquared(dLng) * _cos(lat1) * _cos(lat2);

  return earthRadiusMeters * 2 * math.asin(math.sqrt(h.clamp(0, 1)));
}

double _degreesToRadians(double degrees) => degrees * 3.141592653589793 / 180;

double _sinHalfSquared(double value) {
  final sinHalf = math.sin(value / 2);
  return sinHalf * sinHalf;
}

double _cos(double value) => math.cos(value);

const _demoPhotos = <PhotoMapItem>[
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
  PhotoMapItem(
    areaType: PhotoAreaType.attraction,
    isDemo: true,
    position: geo.LatLng(31.2397, 121.4998),
    title: '景点照片 1',
  ),
];
