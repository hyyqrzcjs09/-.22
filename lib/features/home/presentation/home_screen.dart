import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../photos/data/local_photo_repository.dart';
import '../../photos/presentation/photo_map_view.dart';

enum _PlaceMode { map, stack, detail }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _PlaceMode _mode = _PlaceMode.map;
  PhotoAreaGroup? _selectedPlace;

  bool get _hasSelectedPlace => _selectedPlace != null;

  @override
  Widget build(BuildContext context) {
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
                  showStatusPanel: false,
                  onPlaceSelected: _openPlace,
                ),
              _PlaceMode.stack => const _PlaceStackView(),
              _PlaceMode.detail => const _PlaceDetailView(),
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: _PlaceTopBar(
                hasSelectedPlace: _hasSelectedPlace,
                mode: _mode,
                onBack: _returnToMap,
                onToggle: () => setState(
                  () => _mode = _mode == _PlaceMode.stack
                      ? _PlaceMode.detail
                      : _PlaceMode.stack,
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 20,
            child: _PlaceModeBar(
              hasSelectedPlace: _hasSelectedPlace,
              mode: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
            ),
          ),
        ],
      ),
    );
  }

  void _openPlace(PhotoAreaGroup group) {
    setState(() {
      _selectedPlace = group;
      _mode = _PlaceMode.detail;
    });
  }

  void _returnToMap() {
    setState(() {
      _selectedPlace = null;
      _mode = _PlaceMode.map;
    });
  }
}

class _PlaceTopBar extends StatelessWidget {
  const _PlaceTopBar({
    required this.hasSelectedPlace,
    required this.mode,
    required this.onBack,
    required this.onToggle,
  });

  final bool hasSelectedPlace;
  final _PlaceMode mode;
  final VoidCallback onBack;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
              hasSelectedPlace ? 'Edinburgh · 8 张照片' : '地点链接 · 漫游地图',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
        const Spacer(),
        if (hasSelectedPlace)
          _GlassIconButton(
            tooltip: mode == _PlaceMode.detail ? '照片堆叠' : '地点详情',
            icon: mode == _PlaceMode.detail
                ? Icons.grid_view_rounded
                : Icons.map_outlined,
            onPressed: onToggle,
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }
}

class _PlaceStackView extends StatelessWidget {
  const _PlaceStackView();

  @override
  Widget build(BuildContext context) {
    return const _PlaceBackdrop(
      child: Center(
        child: SizedBox(
          width: 310,
          height: 340,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _PolaroidCard(
                angle: -0.24,
                offset: Offset(-58, 34),
                colors: [Color(0xFF5DAE79), Color(0xFFBFE8C0)],
              ),
              _PolaroidCard(
                angle: -0.11,
                offset: Offset(-20, -4),
                colors: [Color(0xFFD7B48C), Color(0xFFF6E8D5)],
              ),
              _PolaroidCard(
                angle: 0.15,
                offset: Offset(42, -52),
                colors: [Color(0xFFF08825), Color(0xFFFFD6A1)],
              ),
              _PolaroidCard(
                angle: -0.05,
                offset: Offset(36, 42),
                colors: [Color(0xFF5B8068), Color(0xFFE8F0F2)],
                foregroundIcon: Icons.water,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceDetailView extends StatelessWidget {
  const _PlaceDetailView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _PlaceBackdrop(
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
                  const AspectRatio(
                    aspectRatio: 1.18,
                    child: _MemoryImageBlock(
                      colors: [Color(0xFF4C7F59), Color(0xFFE8EEF2)],
                      icon: Icons.landscape_outlined,
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
                                'Edinburgh',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const _PhotoCountBadge(),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '2023/6/12 16:20',
                          style: textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '50.7192, -1.8808',
                          style: textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w700,
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
  const _PlaceBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD5D7DA), Color(0xFFBFC2C6), Color(0xFFEAE9E5)],
        ),
      ),
      child: SizedBox.expand(child: child),
    );
  }
}

class _PlaceModeBar extends StatelessWidget {
  const _PlaceModeBar({
    required this.hasSelectedPlace,
    required this.mode,
    required this.onChanged,
  });

  final bool hasSelectedPlace;
  final _PlaceMode mode;
  final ValueChanged<_PlaceMode> onChanged;

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
                if (hasSelectedPlace) ...[
                  _PlaceModeButton(
                    icon: Icons.grid_view_rounded,
                    label: '相册',
                    selected: mode == _PlaceMode.detail,
                    onTap: () => onChanged(_PlaceMode.detail),
                  ),
                  _PlaceModeButton(
                    icon: Icons.folder_rounded,
                    label: '相簿',
                    selected: mode == _PlaceMode.stack,
                    onTap: () => onChanged(_PlaceMode.stack),
                  ),
                ],
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
  });

  final double angle;
  final List<Color> colors;
  final IconData foregroundIcon;
  final Offset offset;

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
              child: _MemoryImageBlock(colors: colors, icon: foregroundIcon),
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
  const _PhotoCountBadge();

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
          '8 / 8',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}
