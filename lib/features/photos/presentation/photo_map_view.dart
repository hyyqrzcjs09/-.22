import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as geo;
import 'package:photo_manager/photo_manager.dart';

import '../../../core/config/app_config.dart';
import '../application/photo_map_providers.dart';
import '../data/local_photo_repository.dart';

class PhotoMapView extends ConsumerWidget {
  const PhotoMapView({
    this.onPlaceSelected,
    this.showStatusPanel = true,
    super.key,
  });

  final ValueChanged<PhotoAreaGroup>? onPlaceSelected;
  final bool showStatusPanel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMap = ref.watch(photoMapProvider);

    return asyncMap.when(
      loading: () => _PhotoMapBody(
        center: _defaultCenter,
        onPlaceSelected: onPlaceSelected,
        photos: const [],
        overlay: const _MapLoadingPanel(),
      ),
      error: (error, stackTrace) => _PhotoMapBody(
        center: _defaultCenter,
        onPlaceSelected: onPlaceSelected,
        photos: const [],
        overlay: _MapErrorPanel(
          message: '本地照片读取失败',
          onRetry: () => ref.invalidate(photoMapProvider),
        ),
      ),
      data: (result) => _PhotoMapBody(
        center: _mapCenter(result.photos),
        onPlaceSelected: onPlaceSelected,
        photos: result.photos,
        overlay: showStatusPanel
            ? _MapStatusPanel(
                result: result,
                onRefresh: () => ref.invalidate(photoMapProvider),
              )
            : null,
        emptyOverlay: _buildEmptyOverlay(context, ref, result),
      ),
    );
  }

  Widget? _buildEmptyOverlay(
    BuildContext context,
    WidgetRef ref,
    PhotoMapLoadResult result,
  ) {
    if (result.photos.isNotEmpty) {
      return null;
    }

    if (!result.supportsLocalPhotos) {
      return const _MapHintPanel(
        icon: Icons.phone_android_outlined,
        title: '请在 Android 真机查看本地照片',
        subtitle: '当前平台显示演示地图；真机授权后会读取相册中的照片位置。',
      );
    }

    if (!result.hasAccess) {
      return _MapHintPanel(
        icon: Icons.photo_library_outlined,
        title: '需要本地照片权限',
        subtitle: '授权后会读取带位置信息的照片并显示在地图上。',
        action: FilledButton.icon(
          onPressed: () => ref.invalidate(photoMapProvider),
          icon: const Icon(Icons.lock_open_outlined),
          label: const Text('授权本地照片'),
        ),
      );
    }

    return _MapHintPanel(
      icon: Icons.location_off_outlined,
      title: '没有找到照片位置',
      subtitle: '已读取本地照片，但这些照片没有可用的 GPS 位置信息。',
      action: OutlinedButton.icon(
        onPressed: () => ref.invalidate(photoMapProvider),
        icon: const Icon(Icons.refresh),
        label: const Text('重新读取'),
      ),
    );
  }
}

class _PhotoMapBody extends StatelessWidget {
  const _PhotoMapBody({
    required this.center,
    required this.onPlaceSelected,
    required this.photos,
    this.emptyOverlay,
    this.overlay,
  });

  final geo.LatLng center;
  final Widget? emptyOverlay;
  final ValueChanged<PhotoAreaGroup>? onPlaceSelected;
  final Widget? overlay;
  final List<PhotoMapItem> photos;

  @override
  Widget build(BuildContext context) {
    final areaGroups = buildPhotoAreaGroups(photos);

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: photos.isEmpty ? 11 : 12,
            maxZoom: 18,
            minZoom: 2,
          ),
          children: [
            if (AppConfig.hasMapboxAccessToken)
              TileLayer(
                urlTemplate: AppConfig.mapboxTileUrl,
                subdomains: const [],
                tileDimension: 512,
                zoomOffset: -1,
                maxNativeZoom: 22,
                userAgentPackageName: 'photo_link_vr',
              ),
            MarkerLayer(
              markers: [
                for (final group in areaGroups)
                  Marker(
                    point: group.center,
                    width: group.isCluster ? 132 : 116,
                    height: group.isCluster ? 104 : 96,
                    alignment: Alignment.bottomCenter,
                    child: _SelectableMapMarker(
                      group: group,
                      onTap: onPlaceSelected == null
                          ? null
                          : () => onPlaceSelected!(group),
                    ),
                  ),
              ],
            ),
            const SimpleAttributionWidget(
              source: Text('© Mapbox © OpenStreetMap'),
              backgroundColor: Color(0xCCFFFFFF),
            ),
          ],
        ),
        if (!AppConfig.hasMapboxAccessToken)
          const Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _MapboxTokenPanel(),
          ),
        if (overlay != null)
          Positioned(
            top: AppConfig.hasMapboxAccessToken ? 12 : 88,
            left: 12,
            right: 12,
            child: overlay!,
          ),
        if (emptyOverlay != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: emptyOverlay!,
          ),
      ],
    );
  }
}

class _SelectableMapMarker extends StatelessWidget {
  const _SelectableMapMarker({
    required this.group,
    required this.onTap,
  });

  final PhotoAreaGroup group;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = group.isCluster
        ? '${group.areaType.label} ${group.items.length} 张照片'
        : group.items.first.title;

    return Semantics(
      button: onTap != null,
      label: label,
      child: Tooltip(
        message: '打开$label',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: group.isCluster
              ? _PhotoAreaGroupMarker(group: group)
              : _PhotoMapMarker(photo: group.items.first),
        ),
      ),
    );
  }
}

class _MapboxTokenPanel extends StatelessWidget {
  const _MapboxTokenPanel();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Color(0x1F000000),
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.key_outlined, color: colors.onPrimaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '配置 MAPBOX_ACCESS_TOKEN 后显示完整 Mapbox 地图',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoAreaGroupMarker extends StatelessWidget {
  const _PhotoAreaGroupMarker({required this.group});

  final PhotoAreaGroup group;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final areaColor = _areaColor(colors, group.areaType);
    final label = group.areaType.label;

    return Tooltip(
      message: '$label ${group.items.length} 张照片',
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: areaColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    color: Color(0x3D000000),
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox(
                width: 86,
                height: 72,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _areaIcon(group.areaType),
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      Text(
                        '${group.items.length}张',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Icon(
            Icons.location_on,
            color: areaColor,
            size: 34,
            shadows: const [
              Shadow(
                blurRadius: 5,
                color: Color(0x66000000),
                offset: Offset(0, 2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoMapMarker extends StatelessWidget {
  const _PhotoMapMarker({required this.photo});

  final PhotoMapItem photo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final areaColor = _areaColor(colors, photo.areaType);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Icon(
          Icons.location_on,
          color: areaColor,
          size: 40,
          shadows: const [
            Shadow(
              blurRadius: 6,
              color: Color(0x66000000),
              offset: Offset(0, 2),
            ),
          ],
        ),
        Positioned(
          left: 48,
          bottom: 28,
          child: _PhotoThumb(photo: photo),
        ),
      ],
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.photo});

  final PhotoMapItem photo;

  @override
  Widget build(BuildContext context) {
    final asset = photo.asset;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 3),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Color(0x33000000),
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: asset == null
          ? const ColoredBox(
              color: Color(0xFFE0F2F1),
              child: Icon(Icons.photo, color: Color(0xFF006B63)),
            )
          : FutureBuilder<Uint8List?>(
              future: asset.thumbnailDataWithSize(
                const ThumbnailSize.square(140),
                quality: 72,
              ),
              builder: (context, snapshot) {
                final bytes = snapshot.data;
                if (bytes == null) {
                  return const ColoredBox(
                    color: Color(0xFFE6E8EA),
                    child: Icon(Icons.photo_outlined),
                  );
                }
                return Image.memory(bytes, fit: BoxFit.cover);
              },
            ),
    );
  }
}

class _MapStatusPanel extends StatelessWidget {
  const _MapStatusPanel({
    required this.onRefresh,
    required this.result,
  });

  final VoidCallback onRefresh;
  final PhotoMapLoadResult result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final areaGroups = buildPhotoAreaGroups(result.photos);
    final clusterCount = areaGroups.where((group) => group.isCluster).length;
    final title = result.demoMode
        ? '演示地图'
        : result.isLimited
            ? '本地照片：部分授权'
            : '本地照片地图';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Color(0x1F000000),
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.map_outlined, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${result.photos.length} 张照片 / $clusterCount 个聚合 / ${result.withoutLocationCount} 张无位置',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '刷新',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapLoadingPanel extends StatelessWidget {
  const _MapLoadingPanel();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('正在读取本地照片'),
          ],
        ),
      ),
    );
  }
}

class _MapErrorPanel extends StatelessWidget {
  const _MapErrorPanel({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colors.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapHintPanel extends StatelessWidget {
  const _MapHintPanel({
    required this.icon,
    required this.subtitle,
    required this.title,
    this.action,
  });

  final Widget? action;
  final IconData icon;
  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            color: Color(0x26000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: colors.primary),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 14),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

IconData _areaIcon(PhotoAreaType areaType) {
  return switch (areaType) {
    PhotoAreaType.school => Icons.school_outlined,
    PhotoAreaType.attraction => Icons.attractions_outlined,
    PhotoAreaType.life => Icons.apartment_outlined,
    PhotoAreaType.other => Icons.location_city_outlined,
  };
}

Color _areaColor(ColorScheme colors, PhotoAreaType areaType) {
  return switch (areaType) {
    PhotoAreaType.school => colors.primary,
    PhotoAreaType.attraction => colors.tertiary,
    PhotoAreaType.life => colors.secondary,
    PhotoAreaType.other => const Color(0xFF4B5563),
  };
}

geo.LatLng _mapCenter(List<PhotoMapItem> photos) {
  if (photos.isEmpty) {
    return _defaultCenter;
  }

  final total = photos.fold<({double lat, double lng})>(
    (lat: 0, lng: 0),
    (sum, photo) => (
      lat: sum.lat + photo.position.latitude,
      lng: sum.lng + photo.position.longitude,
    ),
  );

  return geo.LatLng(
    total.lat / photos.length,
    total.lng / photos.length,
  );
}

const _defaultCenter = geo.LatLng(31.2304, 121.4737);
