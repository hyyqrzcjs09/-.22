import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../photos/data/local_photo_repository.dart';
import '../../photos/presentation/photo_map_view.dart';
import '../../profile/application/user_settings.dart';

enum _PlaceMode { map, stack, detail }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _PlaceMode _mode = _PlaceMode.map;
  PhotoAreaGroup? _selectedPlace;

  bool get _hasSelectedPlace => _selectedPlace != null;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(userSettingsProvider);
    final selectedMode = _placeModeFromSetting(settings.albumDisplayMode);
    final selectedPlace = _selectedPlace;

    return AppScaffold(
      selectedIndex: 0,
      title: '地点链接',
      showAppBar: false,
      child: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: switch (_mode) {
              _PlaceMode.map => PhotoMapView(
                  key: const ValueKey('map'),
                  showStatusPanel: false,
                  onPlaceSelected: _openPlace,
                ),
              _PlaceMode.stack => selectedPlace == null
                  ? const SizedBox.shrink()
                  : _PlaceStackView(
                      key: ValueKey('stack-${selectedPlace.hashCode}'),
                      backgroundColor: settings.albumBackgroundColor,
                      place: selectedPlace,
                    ),
              _PlaceMode.detail => selectedPlace == null
                  ? const SizedBox.shrink()
                  : _PlaceDetailView(
                      key: ValueKey('detail-${selectedPlace.hashCode}'),
                      backgroundColor: settings.albumBackgroundColor,
                      place: selectedPlace,
                    ),
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: _PlaceTopBar(
                displayMode: settings.albumDisplayMode,
                hasSelectedPlace: _hasSelectedPlace,
                mode: _mode,
                place: selectedPlace,
                onBack: _returnToMap,
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 20,
            child: _PlaceModeBar(
              displayMode: settings.albumDisplayMode,
              hasSelectedPlace: _hasSelectedPlace,
              mode: _mode,
              selectedPlaceMode: selectedMode,
              onChanged: _changePlaceMode,
            ),
          ),
        ],
      ),
    );
  }

  void _openPlace(PhotoAreaGroup group) {
    final displayMode = ref.read(userSettingsProvider).albumDisplayMode;
    setState(() {
      _selectedPlace = group;
      _mode = _placeModeFromSetting(displayMode);
    });
  }

  void _returnToMap() {
    setState(() {
      _selectedPlace = null;
      _mode = _PlaceMode.map;
    });
  }

  void _changePlaceMode(_PlaceMode mode) {
    if (mode == _PlaceMode.map) {
      _returnToMap();
      return;
    }

    setState(() => _mode = mode);
  }
}

_PlaceMode _placeModeFromSetting(AlbumDisplayMode mode) {
  return switch (mode) {
    AlbumDisplayMode.detail => _PlaceMode.detail,
    AlbumDisplayMode.stack => _PlaceMode.stack,
  };
}

class _PlaceTopBar extends StatelessWidget {
  const _PlaceTopBar({
    required this.displayMode,
    required this.hasSelectedPlace,
    required this.mode,
    required this.onBack,
    this.place,
  });

  final AlbumDisplayMode displayMode;
  final bool hasSelectedPlace;
  final _PlaceMode mode;
  final VoidCallback onBack;
  final PhotoAreaGroup? place;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title =
        hasSelectedPlace && place != null ? place!.headerLabel : '地点链接 · 漫游地图';

    return Row(
      children: [
        _GlassIconButton(
          tooltip: '返回地图',
          icon: Icons.arrow_back_ios_new,
          onPressed: onBack,
        ),
        const Spacer(),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                blurRadius: 14,
                color: Color(0x1F000000),
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
        const Spacer(),
        if (hasSelectedPlace)
          DecoratedBox(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                displayMode == AlbumDisplayMode.detail
                    ? Icons.grid_view_rounded
                    : Icons.folder_rounded,
              ),
            ),
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }
}

class _PlaceStackView extends StatelessWidget {
  const _PlaceStackView({
    required this.backgroundColor,
    required this.place,
    super.key,
  });

  final Color backgroundColor;
  final PhotoAreaGroup place;

  @override
  Widget build(BuildContext context) {
    final cards = place.items.take(4).toList();
    final layouts = const [
      (angle: -0.24, offset: Offset(-58, 34)),
      (angle: -0.11, offset: Offset(-20, -4)),
      (angle: 0.15, offset: Offset(42, -52)),
      (angle: -0.05, offset: Offset(36, 42)),
    ];

    return _PlaceBackdrop(
      backgroundColor: backgroundColor,
      child: Center(
        child: SizedBox(
          width: 310,
          height: 340,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              for (var index = 0; index < cards.length; index++)
                _PolaroidCard(
                  angle: layouts[index % layouts.length].angle,
                  offset: layouts[index % layouts.length].offset,
                  colors: _paletteForItem(cards[index], index),
                  foregroundIcon: _iconForAreaType(cards[index].areaType),
                  label: cards[index].title,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceDetailView extends StatelessWidget {
  const _PlaceDetailView({
    required this.backgroundColor,
    required this.place,
    super.key,
  });

  final Color backgroundColor;
  final PhotoAreaGroup place;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final featured = place.items.first;

    return _PlaceBackdrop(
      backgroundColor: backgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 32,
                    color: Color(0x33000000),
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1.18,
                    child: _MemoryImageBlock(
                      colors: _paletteForItem(featured, 0),
                      icon: _iconForAreaType(featured.areaType),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                place.placeTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _PhotoCountBadge(
                              current: 1,
                              total: place.photoCount,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          place.formattedLatestDate,
                          style: textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          place.coordinateLabel,
                          style: textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          featured.title,
                          style: textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceBackdrop extends StatelessWidget {
  const _PlaceBackdrop({
    required this.backgroundColor,
    required this.child,
  });

  final Color backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            backgroundColor.withValues(alpha: 0.72),
            const Color(0xFFEAE9E5),
          ],
        ),
      ),
      child: SizedBox.expand(child: child),
    );
  }
}

class _PlaceModeBar extends StatelessWidget {
  const _PlaceModeBar({
    required this.displayMode,
    required this.hasSelectedPlace,
    required this.mode,
    required this.onChanged,
    required this.selectedPlaceMode,
  });

  final AlbumDisplayMode displayMode;
  final bool hasSelectedPlace;
  final _PlaceMode mode;
  final ValueChanged<_PlaceMode> onChanged;
  final _PlaceMode selectedPlaceMode;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(36),
            boxShadow: const [
              BoxShadow(
                blurRadius: 24,
                color: Color(0x26000000),
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PlaceModeButton(
                  icon: Icons.add_location_alt_outlined,
                  label: '漫游地图',
                  selected: mode == _PlaceMode.map,
                  onTap: () => onChanged(_PlaceMode.map),
                ),
                if (hasSelectedPlace)
                  _PlaceModeButton(
                    icon: displayMode == AlbumDisplayMode.detail
                        ? Icons.grid_view_rounded
                        : Icons.folder_rounded,
                    label: displayMode.label,
                    selected: mode == selectedPlaceMode,
                    onTap: () => onChanged(selectedPlaceMode),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceModeButton extends StatelessWidget {
  const _PlaceModeButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? Theme.of(context).colorScheme.primary : Colors.grey;

    return SizedBox(
      width: 92,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

class _PolaroidCard extends StatelessWidget {
  const _PolaroidCard({
    required this.angle,
    required this.colors,
    required this.offset,
    this.foregroundIcon = Icons.photo_outlined,
    this.label,
  });

  final double angle;
  final List<Color> colors;
  final IconData foregroundIcon;
  final Offset offset;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                blurRadius: 20,
                color: Color(0x26000000),
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: SizedBox(
            width: 188,
            height: 220,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 42),
              child: Column(
                children: [
                  Expanded(
                    child: _MemoryImageBlock(
                      colors: colors,
                      icon: foregroundIcon,
                    ),
                  ),
                  if (label != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryImageBlock extends StatelessWidget {
  const _MemoryImageBlock({
    required this.colors,
    required this.icon,
  });

  final List<Color> colors;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
          transform: const GradientRotation(math.pi / 8),
        ),
      ),
      child: Center(
        child:
            Icon(icon, color: Colors.white.withValues(alpha: 0.82), size: 54),
      ),
    );
  }
}

class _PhotoCountBadge extends StatelessWidget {
  const _PhotoCountBadge({
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF626262),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Text(
          '$current / $total',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

List<Color> _paletteForItem(PhotoMapItem item, int index) {
  const palettes = [
    [Color(0xFF5DAE79), Color(0xFFBFE8C0)],
    [Color(0xFFD7B48C), Color(0xFFF6E8D5)],
    [Color(0xFFF08825), Color(0xFFFFD6A1)],
    [Color(0xFF5B8068), Color(0xFFE8F0F2)],
  ];
  return palettes[(item.title.hashCode + index).abs() % palettes.length];
}

IconData _iconForAreaType(PhotoAreaType areaType) {
  return switch (areaType) {
    PhotoAreaType.school => Icons.school_outlined,
    PhotoAreaType.attraction => Icons.attractions_outlined,
    PhotoAreaType.life => Icons.apartment_outlined,
    PhotoAreaType.other => Icons.landscape_outlined,
  };
}
