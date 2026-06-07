import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../photos/application/photo_map_providers.dart';
import '../../photos/data/local_photo_repository.dart';
import '../../photos/presentation/photo_map_view.dart';
import '../../photos/presentation/photos_screen.dart';
import '../../profile/application/user_settings.dart';

enum _PlaceMode { map, stack, detail, time, journal }

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
    final selectedPlace = _selectedPlace;

    return AppScaffold(
      selectedIndex: 0,
      title: '时空环',
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
              _PlaceMode.time => TimeRoamView(
                  key: ValueKey('time-${settings.timeRoamDisplayMode.name}'),
                  mode: settings.timeRoamDisplayMode,
                ),
              _PlaceMode.journal => _JournalRoamView(
                  key: ValueKey('journal-${settings.albumDisplayMode.name}'),
                  backgroundColor: settings.albumBackgroundColor,
                  displayMode: settings.albumDisplayMode,
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
              mode: _mode,
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

    if (mode == _PlaceMode.time || mode == _PlaceMode.journal) {
      setState(() {
        _selectedPlace = null;
        _mode = mode;
      });
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
    final title = switch (mode) {
      _PlaceMode.time => '时空环 · 时间漫游',
      _PlaceMode.journal => '时空环 · 手账漫游',
      _ =>
        hasSelectedPlace && place != null ? place!.headerLabel : '时空环 · 空间漫游',
    };

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
        if (hasSelectedPlace &&
            mode != _PlaceMode.time &&
            mode != _PlaceMode.journal)
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

class _JournalRoamView extends ConsumerStatefulWidget {
  const _JournalRoamView({
    required this.backgroundColor,
    required this.displayMode,
    super.key,
  });

  final Color backgroundColor;
  final AlbumDisplayMode displayMode;

  @override
  ConsumerState<_JournalRoamView> createState() => _JournalRoamViewState();
}

class _JournalRoamViewState extends ConsumerState<_JournalRoamView> {
  _JournalVisualStyle _visualStyle = _JournalVisualStyle.dream;

  @override
  Widget build(BuildContext context) {
    final asyncMap = ref.watch(photoMapProvider);

    return asyncMap.when(
      loading: () => _JournalBackdrop(
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => const _JournalBackdrop(
        child: _JournalMessage(
          icon: Icons.error_outline,
          title: '手账读取失败',
          subtitle: '稍后会继续使用本地照片重新生成。',
        ),
      ),
      data: (result) => _JournalPage(
        backgroundColor: widget.backgroundColor,
        displayMode: widget.displayMode,
        onStyleChanged: (style) {
          setState(() {
            _visualStyle = style;
          });
        },
        photos: result.photos,
        visualStyle: _visualStyle,
      ),
    );
  }
}

class _JournalPage extends StatelessWidget {
  const _JournalPage({
    required this.backgroundColor,
    required this.displayMode,
    required this.onStyleChanged,
    required this.photos,
    required this.visualStyle,
  });

  final Color backgroundColor;
  final AlbumDisplayMode displayMode;
  final ValueChanged<_JournalVisualStyle> onStyleChanged;
  final List<PhotoMapItem> photos;
  final _JournalVisualStyle visualStyle;

  @override
  Widget build(BuildContext context) {
    final entries = _buildJournalEntries(photos);
    final selectedDay = _selectJournalDay(entries, DateTime.now());

    if (selectedDay == null) {
      return const _JournalBackdrop(
        child: _JournalMessage(
          icon: Icons.photo_library_outlined,
          title: '暂无照片可生成手账',
          subtitle: '授权本地照片后，会自动按日期整理成每日手账。',
        ),
      );
    }

    final isToday = _isSameDay(selectedDay.date, DateTime.now());
    final subtitle = isToday
        ? '已根据今天的照片生成'
        : '今天暂无照片，已显示最近一天：${_formatChineseDate(selectedDay.date)}';

    return _JournalBackdrop(
      child: ListView(
        key: ValueKey('journal-${displayMode.name}-${selectedDay.key}'),
        padding: const EdgeInsets.fromLTRB(20, 104, 20, 128),
        children: [
          _JournalHeader(
            backgroundColor: backgroundColor,
            count: selectedDay.entries.length,
            displayMode: displayMode,
            isToday: isToday,
            onStyleChanged: onStyleChanged,
            subtitle: subtitle,
            visualStyle: visualStyle,
          ),
          const SizedBox(height: 16),
          _JournalNotebook(
            backgroundColor: backgroundColor,
            day: selectedDay,
            displayMode: displayMode,
            visualStyle: visualStyle,
          ),
        ],
      ),
    );
  }
}

class _JournalBackdrop extends StatelessWidget {
  const _JournalBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: SizedBox.expand(child: child),
    );
  }
}

class _JournalMessage extends StatelessWidget {
  const _JournalMessage({
    required this.icon,
    required this.subtitle,
    required this.title,
  });

  final IconData icon;
  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                blurRadius: 20,
                color: Color(0x12000000),
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 34, color: const Color(0xFF202124)),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF666A73),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _JournalVisualStyle {
  dream('梦境彩贴', Icons.auto_awesome),
  film('复古胶片', Icons.local_movies_outlined),
  travel('旅行手账', Icons.explore_outlined),
  forest('森系拼贴', Icons.eco_outlined),
  city('城市霓虹', Icons.location_city_outlined),
  ocean('海边假日', Icons.beach_access),
  campus('校园便签', Icons.edit_note_outlined),
  festival('节日闪闪', Icons.celebration_outlined),
  cream('奶油极简', Icons.layers_outlined),
  cafe('咖啡日记', Icons.local_cafe_outlined),
  sunset('落日相片', Icons.wb_sunny_outlined),
  mono('黑白杂志', Icons.newspaper_outlined);

  const _JournalVisualStyle(this.label, this.icon);

  final IconData icon;
  final String label;
}

class _JournalStyleSpec {
  const _JournalStyleSpec({
    required this.backgroundColors,
    required this.borderColor,
    required this.captionColor,
    required this.foregroundColor,
    required this.paperColor,
    required this.stickerColor,
    required this.tapeColor,
  });

  final List<Color> backgroundColors;
  final Color borderColor;
  final Color captionColor;
  final Color foregroundColor;
  final Color paperColor;
  final Color stickerColor;
  final Color tapeColor;
}

_JournalStyleSpec _styleSpecFor(_JournalVisualStyle style) {
  return switch (style) {
    _JournalVisualStyle.dream => const _JournalStyleSpec(
        backgroundColors: [
          Color(0xFFFFE2F1),
          Color(0xFFE3F5FF),
          Color(0xFFFFF3C7),
        ],
        borderColor: Color(0xFFFF8FB8),
        captionColor: Color(0xFF73465B),
        foregroundColor: Color(0xFF321627),
        paperColor: Color(0xFFFFFBF3),
        stickerColor: Color(0xFFFFB6D5),
        tapeColor: Color(0xFFFFD166),
      ),
    _JournalVisualStyle.film => const _JournalStyleSpec(
        backgroundColors: [
          Color(0xFF2D221C),
          Color(0xFF74533E),
          Color(0xFFE8C995),
        ],
        borderColor: Color(0xFFC9925C),
        captionColor: Color(0xFFFFF0D0),
        foregroundColor: Color(0xFF1A120D),
        paperColor: Color(0xFFFFF5DC),
        stickerColor: Color(0xFFE26D5C),
        tapeColor: Color(0xFFB7A06A),
      ),
    _JournalVisualStyle.travel => const _JournalStyleSpec(
        backgroundColors: [
          Color(0xFFCFE6D8),
          Color(0xFFFFE3B4),
          Color(0xFFB7D7FF),
        ],
        borderColor: Color(0xFF3F8F6B),
        captionColor: Color(0xFF25493A),
        foregroundColor: Color(0xFF143124),
        paperColor: Color(0xFFFFFFF7),
        stickerColor: Color(0xFF69B99D),
        tapeColor: Color(0xFFFFB703),
      ),
    _JournalVisualStyle.forest => const _JournalStyleSpec(
        backgroundColors: [
          Color(0xFFE8F5E9),
          Color(0xFFB7E4C7),
          Color(0xFFFFF1C1),
        ],
        borderColor: Color(0xFF2D6A4F),
        captionColor: Color(0xFF315343),
        foregroundColor: Color(0xFF123524),
        paperColor: Color(0xFFFFFCF2),
        stickerColor: Color(0xFF95D5B2),
        tapeColor: Color(0xFFD8F3DC),
      ),
    _JournalVisualStyle.city => const _JournalStyleSpec(
        backgroundColors: [
          Color(0xFF111827),
          Color(0xFF7C3AED),
          Color(0xFF22D3EE),
        ],
        borderColor: Color(0xFF22D3EE),
        captionColor: Color(0xFFDBEAFE),
        foregroundColor: Color(0xFF0B1020),
        paperColor: Color(0xFFF8FAFC),
        stickerColor: Color(0xFFF472B6),
        tapeColor: Color(0xFF67E8F9),
      ),
    _JournalVisualStyle.ocean => const _JournalStyleSpec(
        backgroundColors: [
          Color(0xFFBDE0FE),
          Color(0xFFFFE5B4),
          Color(0xFF90E0EF),
        ],
        borderColor: Color(0xFF0077B6),
        captionColor: Color(0xFF145C72),
        foregroundColor: Color(0xFF063B4C),
        paperColor: Color(0xFFFFFFF8),
        stickerColor: Color(0xFFFFC8A2),
        tapeColor: Color(0xFF48CAE4),
      ),
    _JournalVisualStyle.campus => const _JournalStyleSpec(
        backgroundColors: [
          Color(0xFFFFF7AD),
          Color(0xFFE8F1FF),
          Color(0xFFFFD6E0),
        ],
        borderColor: Color(0xFF293241),
        captionColor: Color(0xFF5B5F6A),
        foregroundColor: Color(0xFF1F2937),
        paperColor: Color(0xFFFFFFFD),
        stickerColor: Color(0xFFFFC857),
        tapeColor: Color(0xFFA7C7E7),
      ),
    _JournalVisualStyle.festival => const _JournalStyleSpec(
        backgroundColors: [
          Color(0xFFFF0054),
          Color(0xFFFFBD00),
          Color(0xFF9B5DE5),
        ],
        borderColor: Color(0xFFFFBD00),
        captionColor: Color(0xFFFFF3B0),
        foregroundColor: Color(0xFF2A0A0A),
        paperColor: Color(0xFFFFFBEB),
        stickerColor: Color(0xFF00F5D4),
        tapeColor: Color(0xFFFFD166),
      ),
    _JournalVisualStyle.cream => const _JournalStyleSpec(
        backgroundColors: [
          Color(0xFFFFFBF0),
          Color(0xFFF1E7D0),
          Color(0xFFE8E5DA),
        ],
        borderColor: Color(0xFF7A6C5D),
        captionColor: Color(0xFF6B5E51),
        foregroundColor: Color(0xFF2E2A25),
        paperColor: Color(0xFFFFFFFA),
        stickerColor: Color(0xFFE8DCC3),
        tapeColor: Color(0xFFD9C7A5),
      ),
    _JournalVisualStyle.cafe => const _JournalStyleSpec(
        backgroundColors: [
          Color(0xFF5E3023),
          Color(0xFFDDB892),
          Color(0xFFFFE8D6),
        ],
        borderColor: Color(0xFF7F4F24),
        captionColor: Color(0xFFFFEDD8),
        foregroundColor: Color(0xFF2B160F),
        paperColor: Color(0xFFFFF7ED),
        stickerColor: Color(0xFFC17C74),
        tapeColor: Color(0xFFB08968),
      ),
    _JournalVisualStyle.sunset => const _JournalStyleSpec(
        backgroundColors: [
          Color(0xFFFF9E64),
          Color(0xFFFFD166),
          Color(0xFF5E60CE),
        ],
        borderColor: Color(0xFFFF7A59),
        captionColor: Color(0xFFFFF0D0),
        foregroundColor: Color(0xFF311B35),
        paperColor: Color(0xFFFFFAF0),
        stickerColor: Color(0xFFFFB703),
        tapeColor: Color(0xFFFF8A5B),
      ),
    _JournalVisualStyle.mono => const _JournalStyleSpec(
        backgroundColors: [
          Color(0xFFF6F6F6),
          Color(0xFFDEDEDE),
          Color(0xFFFFFFFF),
        ],
        borderColor: Color(0xFF111111),
        captionColor: Color(0xFF3F3F46),
        foregroundColor: Color(0xFF111111),
        paperColor: Color(0xFFFFFFFF),
        stickerColor: Color(0xFF111111),
        tapeColor: Color(0xFFD4D4D8),
      ),
  };
}

class _JournalHeader extends StatelessWidget {
  const _JournalHeader({
    required this.backgroundColor,
    required this.count,
    required this.displayMode,
    required this.isToday,
    required this.onStyleChanged,
    required this.subtitle,
    required this.visualStyle,
  });

  final Color backgroundColor;
  final int count;
  final AlbumDisplayMode displayMode;
  final bool isToday;
  final ValueChanged<_JournalVisualStyle> onStyleChanged;
  final String subtitle;
  final _JournalVisualStyle visualStyle;

  @override
  Widget build(BuildContext context) {
    final accent = Color.alphaBlend(
      backgroundColor.withValues(alpha: 0.16),
      Colors.white,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E5E8)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            color: Color(0x10000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SizedBox(
                    width: 52,
                    height: 52,
                    child: Icon(Icons.auto_stories_outlined),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday ? '今日手账' : '最近手账',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$subtitle · 偏好：${displayMode.label}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF666A73),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _JournalCountPill(count: count),
              ],
            ),
            const Divider(height: 28),
            _JournalStyleSelector(
              selected: visualStyle,
              onChanged: onStyleChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalStyleSelector extends StatelessWidget {
  const _JournalStyleSelector({
    required this.onChanged,
    required this.selected,
  });

  final ValueChanged<_JournalVisualStyle> onChanged;
  final _JournalVisualStyle selected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final style in _JournalVisualStyle.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(style.icon, size: 18),
                label: Text(style.label),
                selected: selected == style,
                onSelected: (_) => onChanged(style),
              ),
            ),
        ],
      ),
    );
  }
}

class _JournalNotebook extends StatelessWidget {
  const _JournalNotebook({
    required this.backgroundColor,
    required this.day,
    required this.displayMode,
    required this.visualStyle,
  });

  final Color backgroundColor;
  final _JournalDay day;
  final AlbumDisplayMode displayMode;
  final _JournalVisualStyle visualStyle;

  @override
  Widget build(BuildContext context) {
    final spec = _styleSpecFor(visualStyle);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: spec.borderColor, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: spec.paperColor,
        boxShadow: const [
          BoxShadow(
            blurRadius: 30,
            color: Color(0x24000000),
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: spec.backgroundColors,
            ),
          ),
          child: Stack(
            children: [
              _JournalDecorLayer(spec: spec, visualStyle: visualStyle),
              Padding(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 620;
                    final body = _JournalBody(
                      day: day,
                      displayMode: displayMode,
                      visualStyle: visualStyle,
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _JournalDateRail(
                            backgroundColor: backgroundColor,
                            day: day,
                            horizontal: true,
                            visualStyle: visualStyle,
                          ),
                          const SizedBox(height: 18),
                          body,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 144,
                          child: _JournalDateRail(
                            backgroundColor: backgroundColor,
                            day: day,
                            visualStyle: visualStyle,
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(child: body),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JournalDecorLayer extends StatelessWidget {
  const _JournalDecorLayer({
    required this.spec,
    required this.visualStyle,
  });

  final _JournalStyleSpec spec;
  final _JournalVisualStyle visualStyle;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              left: 24,
              top: 18,
              child: _JournalTape(
                angle: -0.08,
                color: spec.tapeColor.withValues(alpha: 0.9),
                label: visualStyle.label,
              ),
            ),
            Positioned(
              right: 24,
              top: 28,
              child: Icon(
                visualStyle.icon,
                color: spec.foregroundColor.withValues(alpha: 0.18),
                size: 72,
              ),
            ),
            Positioned(
              right: 32,
              bottom: 24,
              child: _JournalSticker(
                color: spec.stickerColor,
                icon: Icons.favorite,
              ),
            ),
            Positioned(
              left: 42,
              bottom: 28,
              child: _JournalSticker(
                color: spec.paperColor,
                icon: Icons.auto_awesome,
                outlined: true,
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: spec.foregroundColor.withValues(alpha: 0.16),
                      width: 2,
                    ),
                  ),
                ),
                child: const SizedBox(height: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalTape extends StatelessWidget {
  const _JournalTape({
    required this.angle,
    required this.color,
    required this.label,
  });

  final double angle;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF111111),
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ),
    );
  }
}

class _JournalSticker extends StatelessWidget {
  const _JournalSticker({
    required this.color,
    required this.icon,
    this.outlined = false,
  });

  final Color color;
  final IconData icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: outlined ? Colors.white.withValues(alpha: 0.78) : color,
        border: Border.all(color: const Color(0xFF111111), width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Color(0x1F000000),
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        width: 46,
        height: 46,
        child: Icon(icon, color: const Color(0xFF111111), size: 22),
      ),
    );
  }
}

class _JournalDateRail extends StatelessWidget {
  const _JournalDateRail({
    required this.backgroundColor,
    required this.day,
    required this.visualStyle,
    this.horizontal = false,
  });

  final Color backgroundColor;
  final _JournalDay day;
  final bool horizontal;
  final _JournalVisualStyle visualStyle;

  @override
  Widget build(BuildContext context) {
    final spec = _styleSpecFor(visualStyle);
    final accent = Color.alphaBlend(
      backgroundColor.withValues(alpha: 0.16),
      spec.paperColor,
    );
    final monthLabel = '${day.date.month}月';
    final dayLabel = '${day.date.day}';
    final countLabel = '${day.entries.length} 张';

    if (horizontal) {
      return Row(
        children: [
          _JournalDateBox(
            accent: accent,
            dayLabel: dayLabel,
            monthLabel: monthLabel,
            spec: spec,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _JournalDateMeta(
              countLabel: countLabel,
              date: day.date,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _JournalDateBox(
          accent: accent,
          dayLabel: dayLabel,
          monthLabel: monthLabel,
          spec: spec,
        ),
        const SizedBox(height: 18),
        Container(
          width: 2,
          height: 78,
          color: spec.foregroundColor.withValues(alpha: 0.28),
        ),
        const SizedBox(height: 18),
        _JournalDateMeta(
          countLabel: countLabel,
          date: day.date,
        ),
      ],
    );
  }
}

class _JournalDateBox extends StatelessWidget {
  const _JournalDateBox({
    required this.accent,
    required this.dayLabel,
    required this.monthLabel,
    required this.spec,
  });

  final Color accent;
  final String dayLabel;
  final String monthLabel;
  final _JournalStyleSpec spec;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: spec.foregroundColor, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: accent,
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Color(0x24000000),
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: SizedBox(
        width: 104,
        height: 112,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              monthLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: spec.captionColor,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              dayLabel,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: spec.foregroundColor,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalDateMeta extends StatelessWidget {
  const _JournalDateMeta({
    required this.countLabel,
    required this.date,
  });

  final String countLabel;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _weekdayLabel(date),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          countLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF666A73),
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _JournalBody extends StatelessWidget {
  const _JournalBody({
    required this.day,
    required this.displayMode,
    required this.visualStyle,
  });

  final _JournalDay day;
  final AlbumDisplayMode displayMode;
  final _JournalVisualStyle visualStyle;

  @override
  Widget build(BuildContext context) {
    return switch (displayMode) {
      AlbumDisplayMode.detail => _JournalGrid(
          day: day,
          visualStyle: visualStyle,
        ),
      AlbumDisplayMode.stack => _JournalCollage(
          day: day,
          visualStyle: visualStyle,
        ),
    };
  }
}

class _JournalGrid extends StatelessWidget {
  const _JournalGrid({
    required this.day,
    required this.visualStyle,
  });

  final _JournalDay day;
  final _JournalVisualStyle visualStyle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 780
            ? 4
            : constraints.maxWidth >= 520
                ? 3
                : constraints.maxWidth >= 340
                    ? 2
                    : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: day.entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.86,
          ),
          itemBuilder: (context, index) => _JournalPhotoTile(
            entry: day.entries[index],
            index: index,
            visualStyle: visualStyle,
          ),
        );
      },
    );
  }
}

class _JournalCollage extends StatelessWidget {
  const _JournalCollage({
    required this.day,
    required this.visualStyle,
  });

  final _JournalDay day;
  final _JournalVisualStyle visualStyle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spec = _styleSpecFor(visualStyle);
        final width = constraints.maxWidth.clamp(280.0, 620.0).toDouble();
        final cardWidth = math.min(168.0, math.max(118.0, width * 0.34));
        final layouts = [
          (left: width * 0.02, top: 42.0, angle: -0.16),
          (left: width * 0.22, top: 16.0, angle: 0.08),
          (left: width * 0.48, top: 48.0, angle: -0.06),
          (left: width * 0.12, top: 210.0, angle: 0.13),
          (left: width * 0.38, top: 192.0, angle: -0.11),
          (left: width * 0.58, top: 218.0, angle: 0.07),
        ];

        return SizedBox(
          height: 410,
          child: Center(
            child: SizedBox(
              width: width,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 8,
                    right: 8,
                    top: 88,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: spec.foregroundColor.withValues(alpha: 0.24),
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: spec.paperColor.withValues(alpha: 0.72),
                      ),
                      child: const SizedBox(height: 210),
                    ),
                  ),
                  for (var index = 0;
                      index < math.min(day.entries.length, layouts.length);
                      index++)
                    Positioned(
                      left: layouts[index].left,
                      top: layouts[index].top,
                      child: _JournalStickerTile(
                        angle: layouts[index].angle,
                        entry: day.entries[index],
                        index: index,
                        visualStyle: visualStyle,
                        width: cardWidth,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _JournalPhotoTile extends StatelessWidget {
  const _JournalPhotoTile({
    required this.entry,
    required this.index,
    required this.visualStyle,
  });

  final _JournalPhotoEntry entry;
  final int index;
  final _JournalVisualStyle visualStyle;

  @override
  Widget build(BuildContext context) {
    final spec = _styleSpecFor(visualStyle);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: spec.foregroundColor, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: spec.paperColor,
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Color(0x22000000),
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _JournalPictureBlock(
                entry: entry,
                index: index,
                visualStyle: visualStyle,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              entry.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: spec.foregroundColor,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(entry.date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: spec.captionColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalStickerTile extends StatelessWidget {
  const _JournalStickerTile({
    required this.angle,
    required this.entry,
    required this.index,
    required this.visualStyle,
    required this.width,
  });

  final double angle;
  final _JournalPhotoEntry entry;
  final int index;
  final _JournalVisualStyle visualStyle;
  final double width;

  @override
  Widget build(BuildContext context) {
    final spec = _styleSpecFor(visualStyle);

    return Transform.rotate(
      angle: angle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: spec.foregroundColor, width: 2),
          color: spec.paperColor,
          boxShadow: const [
            BoxShadow(
              blurRadius: 18,
              color: Color(0x22000000),
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: SizedBox(
          width: width,
          height: width * 1.24,
          child: Padding(
            padding: EdgeInsets.fromLTRB(9, 9, 9, width * 0.24),
            child: _JournalPictureBlock(
              entry: entry,
              index: index,
              visualStyle: visualStyle,
            ),
          ),
        ),
      ),
    );
  }
}

class _JournalPictureBlock extends StatelessWidget {
  const _JournalPictureBlock({
    required this.entry,
    required this.index,
    required this.visualStyle,
  });

  final _JournalPhotoEntry entry;
  final int index;
  final _JournalVisualStyle visualStyle;

  @override
  Widget build(BuildContext context) {
    final asset = entry.source?.asset;

    if (asset == null) {
      return _JournalIllustrationBlock(
        areaType: entry.areaType,
        index: index,
        visualStyle: visualStyle,
      );
    }

    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(
        const ThumbnailSize.square(520),
        quality: 76,
      ),
      builder: (context, snapshot) {
        final bytes = snapshot.data;

        if (bytes == null) {
          return _JournalIllustrationBlock(
            areaType: entry.areaType,
            index: index,
            visualStyle: visualStyle,
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.memory(bytes, fit: BoxFit.cover),
        );
      },
    );
  }
}

class _JournalIllustrationBlock extends StatelessWidget {
  const _JournalIllustrationBlock({
    required this.areaType,
    required this.index,
    required this.visualStyle,
  });

  final PhotoAreaType areaType;
  final int index;
  final _JournalVisualStyle visualStyle;

  @override
  Widget build(BuildContext context) {
    final spec = _styleSpecFor(visualStyle);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _journalPaletteFor(areaType, index, visualStyle),
          transform: const GradientRotation(math.pi / 8),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 8,
            top: 8,
            child: Icon(
              visualStyle.icon,
              color: Colors.white.withValues(alpha: 0.34),
              size: 36,
            ),
          ),
          Center(
            child: Icon(
              _iconForAreaType(areaType),
              color: Colors.white.withValues(alpha: 0.86),
              size: 54,
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: spec.paperColor.withValues(alpha: 0.76),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  areaType.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: spec.foregroundColor,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalCountPill extends StatelessWidget {
  const _JournalCountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF202124),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          '$count 张',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
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
    required this.mode,
    required this.onChanged,
  });

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
                  label: '空间漫游',
                  selected: mode == _PlaceMode.map,
                  onTap: () => onChanged(_PlaceMode.map),
                ),
                _PlaceModeButton(
                  icon: Icons.schedule_outlined,
                  label: '时间漫游',
                  selected: mode == _PlaceMode.time,
                  onTap: () => onChanged(_PlaceMode.time),
                ),
                _PlaceModeButton(
                  icon: Icons.auto_stories_outlined,
                  label: '手账漫游',
                  selected: mode == _PlaceMode.journal,
                  onTap: () => onChanged(_PlaceMode.journal),
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
    [Color(0xFF111111), Color(0xFFD4D4D8)],
    [Color(0xFF3F3F46), Color(0xFFE4E4E7)],
    [Color(0xFF71717A), Color(0xFFF4F4F5)],
    [Color(0xFF18181B), Color(0xFFA1A1AA)],
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

class _JournalDay {
  const _JournalDay({
    required this.date,
    required this.entries,
  });

  final DateTime date;
  final List<_JournalPhotoEntry> entries;

  String get key => '${date.year}-${date.month}-${date.day}';
}

class _JournalPhotoEntry {
  const _JournalPhotoEntry({
    required this.areaType,
    required this.date,
    required this.title,
    this.source,
  });

  final PhotoAreaType areaType;
  final DateTime date;
  final PhotoMapItem? source;
  final String title;
}

List<_JournalPhotoEntry> _buildJournalEntries(List<PhotoMapItem> photos) {
  if (photos.isEmpty) {
    return _fallbackJournalEntries();
  }

  return [
    for (var index = 0; index < photos.length; index++)
      _JournalPhotoEntry(
        areaType: photos[index].areaType,
        date: photos[index].createdAt ?? _fallbackJournalDate(index),
        source: photos[index],
        title: photos[index].title.trim().isEmpty
            ? '${photos[index].areaType.label}照片 ${index + 1}'
            : photos[index].title,
      ),
  ];
}

List<_JournalPhotoEntry> _fallbackJournalEntries() {
  const titles = [
    '晨间街角',
    '校园光影',
    '午后展馆',
    '夜色散步',
    '车窗风景',
    '归家餐桌',
  ];
  const areaTypes = [
    PhotoAreaType.life,
    PhotoAreaType.school,
    PhotoAreaType.attraction,
    PhotoAreaType.life,
    PhotoAreaType.other,
    PhotoAreaType.life,
  ];

  return [
    for (var index = 0; index < titles.length; index++)
      _JournalPhotoEntry(
        areaType: areaTypes[index],
        date: _fallbackJournalDate(index),
        title: titles[index],
      ),
  ];
}

DateTime _fallbackJournalDate(int index) {
  return switch (index % 6) {
    0 => DateTime(2026, 6, 6, 8, 32),
    1 => DateTime(2026, 6, 6, 10, 18),
    2 => DateTime(2026, 6, 6, 15, 46),
    3 => DateTime(2026, 6, 5, 19, 20),
    4 => DateTime(2026, 6, 5, 21, 6),
    _ => DateTime(2026, 5, 28, 12, 40),
  };
}

_JournalDay? _selectJournalDay(
  List<_JournalPhotoEntry> entries,
  DateTime now,
) {
  if (entries.isEmpty) {
    return null;
  }

  final today = _dateOnly(now);
  final grouped = <DateTime, List<_JournalPhotoEntry>>{};

  for (final entry in entries) {
    final date = _dateOnly(entry.date);
    grouped.putIfAbsent(date, () => []).add(entry);
  }

  final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
  var selectedDate = sortedDays.first;

  for (final day in sortedDays) {
    if (!day.isAfter(today)) {
      selectedDate = day;
      break;
    }
  }

  final selectedEntries = List<_JournalPhotoEntry>.from(
    grouped[selectedDate] ?? const [],
  )..sort((a, b) => a.date.compareTo(b.date));

  return _JournalDay(
    date: selectedDate,
    entries: selectedEntries,
  );
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatChineseDate(DateTime date) {
  return '${date.year}年${date.month}月${date.day}日';
}

String _formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _weekdayLabel(DateTime date) {
  const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return labels[date.weekday - 1];
}

List<Color> _journalPaletteFor(
  PhotoAreaType areaType,
  int index,
  _JournalVisualStyle style,
) {
  final palettes = switch (style) {
    _JournalVisualStyle.dream => const [
        [Color(0xFFFF7AB6), Color(0xFF6EE7F9)],
        [Color(0xFFFFD166), Color(0xFFFF8FAB)],
        [Color(0xFFA78BFA), Color(0xFFFDE68A)],
        [Color(0xFF60A5FA), Color(0xFFFFB3C7)],
      ],
    _JournalVisualStyle.film => const [
        [Color(0xFF3B2A21), Color(0xFFD6A15F)],
        [Color(0xFF6F4E37), Color(0xFFF4D06F)],
        [Color(0xFF1F2937), Color(0xFFE26D5C)],
        [Color(0xFF8B5E34), Color(0xFFFFE5B4)],
      ],
    _JournalVisualStyle.travel => const [
        [Color(0xFF2A9D8F), Color(0xFFF4A261)],
        [Color(0xFF457B9D), Color(0xFFFFE8A3)],
        [Color(0xFF588157), Color(0xFFBDE0FE)],
        [Color(0xFFE9C46A), Color(0xFF90BE6D)],
      ],
    _JournalVisualStyle.forest => const [
        [Color(0xFF2D6A4F), Color(0xFFB7E4C7)],
        [Color(0xFF40916C), Color(0xFFFFF3B0)],
        [Color(0xFF1B4332), Color(0xFF95D5B2)],
        [Color(0xFF74C69D), Color(0xFFFFE8A3)],
      ],
    _JournalVisualStyle.city => const [
        [Color(0xFF111827), Color(0xFF22D3EE)],
        [Color(0xFF7C3AED), Color(0xFFF472B6)],
        [Color(0xFF0F172A), Color(0xFFA78BFA)],
        [Color(0xFF1E293B), Color(0xFF67E8F9)],
      ],
    _JournalVisualStyle.ocean => const [
        [Color(0xFF0077B6), Color(0xFF90E0EF)],
        [Color(0xFF48CAE4), Color(0xFFFFE5B4)],
        [Color(0xFF023E8A), Color(0xFFBDE0FE)],
        [Color(0xFFFFC8A2), Color(0xFF00B4D8)],
      ],
    _JournalVisualStyle.campus => const [
        [Color(0xFFFFC857), Color(0xFFA7C7E7)],
        [Color(0xFF293241), Color(0xFFFFD6E0)],
        [Color(0xFF3D5A80), Color(0xFFFFF7AD)],
        [Color(0xFF98C1D9), Color(0xFFFFE6A7)],
      ],
    _JournalVisualStyle.festival => const [
        [Color(0xFFFF0054), Color(0xFFFFBD00)],
        [Color(0xFF9B5DE5), Color(0xFF00F5D4)],
        [Color(0xFFF15BB5), Color(0xFFFEE440)],
        [Color(0xFF00BBF9), Color(0xFFFF6B6B)],
      ],
    _JournalVisualStyle.cream => const [
        [Color(0xFFE8DCC3), Color(0xFFFFFBF0)],
        [Color(0xFFD9C7A5), Color(0xFFF7F1E5)],
        [Color(0xFFB8A58F), Color(0xFFFFFFFA)],
        [Color(0xFF7A6C5D), Color(0xFFF1E7D0)],
      ],
    _JournalVisualStyle.cafe => const [
        [Color(0xFF5E3023), Color(0xFFDDB892)],
        [Color(0xFF7F4F24), Color(0xFFFFE8D6)],
        [Color(0xFFB08968), Color(0xFFEDE0D4)],
        [Color(0xFF3C2415), Color(0xFFC17C74)],
      ],
    _JournalVisualStyle.sunset => const [
        [Color(0xFFFF7A59), Color(0xFFFFD166)],
        [Color(0xFF5E60CE), Color(0xFFFF9E64)],
        [Color(0xFF3B185F), Color(0xFFFFB703)],
        [Color(0xFFFF8A5B), Color(0xFF4EA8DE)],
      ],
    _JournalVisualStyle.mono => const [
        [Color(0xFF111111), Color(0xFFE5E5E5)],
        [Color(0xFF3F3F46), Color(0xFFF4F4F5)],
        [Color(0xFF71717A), Color(0xFFD4D4D8)],
        [Color(0xFF18181B), Color(0xFFA1A1AA)],
      ],
  };

  return palettes[(areaType.index + index).abs() % palettes.length];
}
