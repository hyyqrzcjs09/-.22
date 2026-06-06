import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/application/user_settings.dart';

enum _DateMode { timeline, stack, calendar, magazine }

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  _DateMode _mode = _DateMode.timeline;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 1,
      title: '日期',
      showAppBar: false,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _DateSegmentedControl(
              mode: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: switch (_mode) {
                  _DateMode.timeline => const _TimelineView(),
                  _DateMode.stack => const _StackDateView(),
                  _DateMode.calendar => const _CalendarView(),
                  _DateMode.magazine => const _MagazineView(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimeRoamView extends StatelessWidget {
  const TimeRoamView({
    required this.mode,
    super.key,
  });

  final TimeRoamDisplayMode mode;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: switch (mode) {
        TimeRoamDisplayMode.day => const _TimelineView(),
        TimeRoamDisplayMode.month => const _CalendarView(),
        TimeRoamDisplayMode.year => const _MagazineView(),
      },
    );
  }
}

class _DateSegmentedControl extends StatelessWidget {
  const _DateSegmentedControl({
    required this.mode,
    required this.onChanged,
  });

  final _DateMode mode;
  final ValueChanged<_DateMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE9E9EC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SegmentButton(
                label: '时间',
                selected: mode == _DateMode.timeline,
                onTap: () => onChanged(_DateMode.timeline),
              ),
              _SegmentButton(
                label: '堆叠',
                selected: mode == _DateMode.stack,
                onTap: () => onChanged(_DateMode.stack),
              ),
              _SegmentButton(
                label: '日历',
                selected: mode == _DateMode.calendar,
                onTap: () => onChanged(_DateMode.calendar),
              ),
              _SegmentButton(
                label: '杂志',
                selected: mode == _DateMode.magazine,
                onTap: () => onChanged(_DateMode.magazine),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.onTap,
    required this.selected,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF202124) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selected ? Colors.white : const Color(0xFF81838A),
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ),
    );
  }
}

class _TimelineView extends StatelessWidget {
  const _TimelineView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('timeline'),
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
      children: const [
        _TimelineGroup(
          title: 'Yesterday',
          titleColor: Color(0xFFFF6B35),
          cards: _PhotoPalette.yesterday,
        ),
        SizedBox(height: 28),
        _TimelineGroup(
          title: '7 June · Saturday',
          cards: _PhotoPalette.june,
        ),
        SizedBox(height: 28),
        _TimelineGroup(
          title: '5 June · Thursday',
          cards: _PhotoPalette.city,
        ),
      ],
    );
  }
}

class _TimelineGroup extends StatelessWidget {
  const _TimelineGroup({
    required this.cards,
    required this.title,
    this.titleColor = Colors.black,
  });

  final List<List<Color>> cards;
  final String title;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 160,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var index = 0; index < cards.length; index++)
                Positioned(
                  left: index * 84.0,
                  top: index.isEven ? 8 : 24,
                  child: _TiltedPhoto(
                    angle: (index - 1) * 0.08,
                    colors: cards[index],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StackDateView extends StatelessWidget {
  const _StackDateView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('stack'),
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 34),
      children: const [
        _DatePile(title: 'June 2025', subtitle: '18 张照片'),
        SizedBox(height: 26),
        _DatePile(title: 'May 2025', subtitle: '26 张照片', reverse: true),
        SizedBox(height: 26),
        _DatePile(title: '2024 旅行', subtitle: '43 张照片'),
      ],
    );
  }
}

class _DatePile extends StatelessWidget {
  const _DatePile({
    required this.subtitle,
    required this.title,
    this.reverse = false,
  });

  final bool reverse;
  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    final palettes = reverse ? _PhotoPalette.city : _PhotoPalette.june;

    return Row(
      children: [
        SizedBox(
          width: 160,
          height: 176,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var index = 0; index < 3; index++)
                Transform.translate(
                  offset: Offset((index - 1) * 14, (index - 1) * 7),
                  child: _TiltedPhoto(
                    angle: (index - 1) * 0.13,
                    colors: palettes[index],
                    width: 118,
                    height: 142,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF7B7E86),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalendarView extends StatelessWidget {
  const _CalendarView();

  @override
  Widget build(BuildContext context) {
    const activeDays = {
      5: (3, [Color(0xFFAA4E30), Color(0xFFF0B07A)]),
      6: (8, [Color(0xFFCABFA0), Color(0xFF786B54)]),
      7: (2, [Color(0xFFD4D4D8), Color(0xFF52525B)]),
      15: (12, [Color(0xFF5D5147), Color(0xFFC9B59B)]),
      22: (5, [Color(0xFF101827), Color(0xFF64748B)]),
      28: (1, [Color(0xFFE4E4E7), Color(0xFF71717A)]),
    };

    return ListView(
      key: const ValueKey('calendar'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        Row(
          children: [
            Text(
              'June 2025',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const Spacer(),
            IconButton(
              tooltip: '上个月',
              onPressed: () {},
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: '下个月',
              onPressed: () {},
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _WeekHeader(),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 35,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
          ),
          itemBuilder: (context, index) {
            final day = index + 1;
            final data = activeDays[day];
            return _CalendarDay(day: day, photoData: data);
          },
        ),
      ],
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader();

  @override
  Widget build(BuildContext context) {
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF8B8D92),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
      ],
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.photoData,
  });

  final int day;
  final (int, List<Color>)? photoData;

  @override
  Widget build(BuildContext context) {
    final data = photoData;

    if (data == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '$day',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF85878C),
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(colors: data.$2),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 7,
            top: 6,
            child: Text(
              '$day',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          Positioned(
            right: 5,
            top: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xCC202124),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: Text(
                  '${data.$1}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
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

class _MagazineView extends StatelessWidget {
  const _MagazineView();

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('magazine'),
      children: [
        Row(
          children: [
            SizedBox(
              width: 128,
              child: Padding(
                padding: const EdgeInsets.only(left: 24, top: 42),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final year in ['2022', '2023', '2024', '2025', '2026'])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 38),
                        child: Row(
                          children: [
                            if (year == '2023')
                              const Icon(Icons.play_arrow, size: 18)
                            else
                              const SizedBox(width: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FittedBox(
                                alignment: Alignment.centerLeft,
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  year,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: year == '2023'
                                            ? Colors.black
                                            : const Color(0xFFB4B5BA),
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: const [
                  _MagazineCard(
                    year: '2022',
                    angle: -0.12,
                    offset: Offset(-8, -80),
                    colors: [Color(0xFFBDBEC3), Color(0xFFE7E8EA)],
                  ),
                  _MagazineCard(
                    year: '2024',
                    angle: 0.17,
                    offset: Offset(64, 280),
                    colors: [Color(0xFFE65353), Color(0xFFFFC2A5)],
                  ),
                  _MagazineCard(
                    year: '2023',
                    angle: 0.0,
                    offset: Offset(18, 44),
                    colors: [Color(0xFF8B6F55), Color(0xFFE5D0AA)],
                    foreground: Icons.groups_2_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 28,
          bottom: 54,
          child: FloatingActionButton(
            heroTag: 'magazineAdd',
            tooltip: '添加日期杂志',
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _MagazineCard extends StatelessWidget {
  const _MagazineCard({
    required this.angle,
    required this.colors,
    required this.offset,
    required this.year,
    this.foreground = Icons.photo_album_outlined,
  });

  final double angle;
  final List<Color> colors;
  final IconData foreground;
  final Offset offset;
  final String year;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: year == '2023'
                  ? const Color(0xFFE5B82C)
                  : Colors.white.withValues(alpha: 0.7),
              width: 5,
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 22,
                color: Color(0x26000000),
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: SizedBox(
            width: 238,
            height: 318,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(colors: colors),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  top: 10,
                  child: Text(
                    year,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.74),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Center(
                  child: Icon(
                    foreground,
                    color: Colors.white.withValues(alpha: 0.74),
                    size: 70,
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

class _TiltedPhoto extends StatelessWidget {
  const _TiltedPhoto({
    required this.angle,
    required this.colors,
    this.height = 140,
    this.width = 108,
  });

  final double angle;
  final List<Color> colors;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              blurRadius: 14,
              color: Color(0x1F000000),
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 30),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                  transform: const GradientRotation(math.pi / 7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class _PhotoPalette {
  static const yesterday = [
    [Color(0xFF4B5563), Color(0xFFD1D5DB)],
    [Color(0xFFD9D4C8), Color(0xFF71717A)],
    [Color(0xFF111827), Color(0xFFE5E7EB)],
  ];

  static const june = [
    [Color(0xFFE4E4E7), Color(0xFF71717A)],
    [Color(0xFF3F3F46), Color(0xFFD4D4D8)],
    [Color(0xFFFFCFBC), Color(0xFFE57D78)],
    [Color(0xFF64748B), Color(0xFF111827)],
  ];

  static const city = [
    [Color(0xFF18181B), Color(0xFFD4D4D8)],
    [Color(0xFF5A341E), Color(0xFFE8A35B)],
    [Color(0xFF111827), Color(0xFF52525B)],
    [Color(0xFFE5E7EB), Color(0xFF94A3B8)],
  ];
}
