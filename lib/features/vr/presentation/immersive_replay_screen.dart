import 'dart:async';

import 'package:flutter/material.dart';

import '../application/memory_video_store.dart';

class MemoryVideoSection extends StatelessWidget {
  const MemoryVideoSection({
    this.emptyMessage = '点击相册右上角的 VR 图标，即可把相册内容剪辑成视频并在这里直接播放。',
    super.key,
  });

  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: MemoryVideoStore.instance,
      builder: (context, _) {
        final videos = MemoryVideoStore.instance.videos;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '回忆视频',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            if (videos.isEmpty)
              _EmptyMemoryPanel(message: emptyMessage)
            else
              for (final video in videos) ...[
                _MemoryVideoPreviewCard(video: video),
                const SizedBox(height: 14),
              ],
          ],
        );
      },
    );
  }
}

class MemoryVideoPlayer extends StatelessWidget {
  const MemoryVideoPlayer({
    required this.video,
    super.key,
  });

  final MemoryVideo video;

  @override
  Widget build(BuildContext context) {
    return _MemoryVideoPreviewCard(video: video);
  }
}

class _EmptyMemoryPanel extends StatelessWidget {
  const _EmptyMemoryPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(Icons.movie_creation_outlined,
                size: 44, color: colors.primary),
            const SizedBox(height: 12),
            Text(
              '还没有回忆视频',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryVideoPreviewCard extends StatefulWidget {
  const _MemoryVideoPreviewCard({required this.video});

  final MemoryVideo video;

  @override
  State<_MemoryVideoPreviewCard> createState() =>
      _MemoryVideoPreviewCardState();
}

class _MemoryVideoPreviewCardState extends State<_MemoryVideoPreviewCard> {
  var _clipIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPreview();
  }

  @override
  void didUpdateWidget(covariant _MemoryVideoPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id) {
      _clipIndex = 0;
      _startPreview();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final clips = widget.video.clips;
    final clip = clips[_clipIndex % clips.length];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 650),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.98,
                          end: 1,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _MemoryClipFrame(
                    key: ValueKey('${widget.video.id}_${clip.title}'),
                    clip: clip,
                    index: _clipIndex,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.video.albumName} 回忆视频',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${clips.length} 个片段 / ${widget.video.durationSeconds} 秒',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: '视频速览',
                  onPressed: _advanceClip,
                  icon: const Icon(Icons.play_arrow),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              key: ValueKey(_clipIndex),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1800),
              curve: Curves.easeInOut,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(999),
                  value: value,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startPreview() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (mounted) {
        _advanceClip();
      }
    });
  }

  void _advanceClip() {
    final clips = widget.video.clips;
    if (clips.isEmpty) {
      return;
    }

    setState(() {
      _clipIndex = (_clipIndex + 1) % clips.length;
    });
  }
}

class _MemoryClipFrame extends StatelessWidget {
  const _MemoryClipFrame({
    required this.clip,
    required this.index,
    super.key,
  });

  final MemoryClip clip;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = _previewPalette(index, colors);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Icon(Icons.image_outlined,
                color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(height: 10),
            Text(
              clip.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(clip.date),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

List<Color> _previewPalette(int index, ColorScheme colors) {
  final palettes = [
    [colors.primary, colors.tertiary],
    [colors.secondary, const Color(0xFF475569)],
    [const Color(0xFF0F766E), const Color(0xFF7C3AED)],
    [const Color(0xFFBE123C), const Color(0xFF334155)],
  ];

  return palettes[index % palettes.length];
}

String _formatDate(DateTime date) {
  return '${date.year}年${date.month}月${date.day}日';
}
