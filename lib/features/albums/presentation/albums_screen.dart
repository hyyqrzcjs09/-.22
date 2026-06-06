import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/tri_ring_agent.dart';
import '../../ar/application/ar_replay_bridge.dart';
import '../../vr/application/memory_video_store.dart';
import '../../vr/presentation/immersive_replay_screen.dart';
import '../../../shared/widgets/app_scaffold.dart';

class AlbumsScreen extends ConsumerStatefulWidget {
  const AlbumsScreen({super.key});

  @override
  ConsumerState<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends ConsumerState<AlbumsScreen> {
  final _albums = <_CategoryAlbum>[];
  final _triRingPhotoIds = {
    for (final type in TriRingType.values) type: <String>{},
  };
  _CategoryAlbum? _openedAlbum;
  bool _socialEnabled = false;

  @override
  Widget build(BuildContext context) {
    final openedAlbum = _openedAlbum;

    if (openedAlbum != null) {
      return AppScaffold(
        selectedIndex: 1,
        title: '比邻环',
        child: _AlbumDetailView(
          album: openedAlbum,
          onBack: () {
            setState(() {
              _openedAlbum = null;
            });
          },
          onNfcAction: _handleNfcAction,
          onAddPhoto: _addPhotoToAlbum,
          onStartArReplay: _startArReplay,
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;

    return AppScaffold(
      selectedIndex: 1,
      title: '比邻环',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '比邻环相册',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_albums.length} 个相册',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: '建立文件夹',
                onPressed: _showCreateAlbumDialog,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TriRingSocialPanel(
            albums: _albums,
            enabled: _socialEnabled,
            selectedPhotoIds: _triRingPhotoIds,
            onPhotoToggled: _toggleTriRingPhoto,
            onToggle: (enabled) {
              setState(() {
                _socialEnabled = enabled;
                if (!enabled) {
                  for (final ids in _triRingPhotoIds.values) {
                    ids.clear();
                  }
                }
              });
            },
          ),
          const SizedBox(height: 16),
          if (_albums.isEmpty)
            _EmptyCategoryPanel(onCreate: _showCreateAlbumDialog)
          else
            GridView.builder(
              itemCount: _albums.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisExtent: 136,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final album = _albums[index];
                return _CategoryAlbumCard(
                  album: album,
                  onStartArReplay: () => _startArReplay(album),
                  onCreateMemoryVideo: () => _createMemoryVideo(album),
                  onTap: () {
                    setState(() {
                      _openedAlbum = album;
                    });
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _showCreateAlbumDialog() async {
    final album = await showDialog<_CategoryAlbum>(
      context: context,
      builder: (context) => const _CreateAlbumDialog(),
    );

    if (album == null || !mounted) {
      return;
    }

    setState(() {
      _albums.add(album);
    });
  }

  void _toggleTriRingPhoto(TriRingType type, String photoId) {
    setState(() {
      final ringPhotoIds = _triRingPhotoIds[type]!;

      if (ringPhotoIds.contains(photoId)) {
        ringPhotoIds.remove(photoId);
        return;
      }

      if (ringPhotoIds.length >= triRingMaxPhotosPerRing) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.label}最多选择 $triRingMaxPhotosPerRing 张照片'),
          ),
        );
        return;
      }

      ringPhotoIds.add(photoId);
    });
  }

  void _createMemoryVideo(_CategoryAlbum album) {
    final video = MemoryVideoStore.instance.addFromAlbum(
      albumName: album.name,
      clips: [
        for (final photo in album.photos)
          MemoryClip(
            date: photo.createdAt,
            title: photo.title,
          ),
      ],
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已将「${album.name}」剪辑成回忆视频')),
    );

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: MemoryVideoPlayer(video: video),
        ),
      ),
    );
  }

  Future<void> _startArReplay(_CategoryAlbum album) async {
    final plan = await ref.read(arReplayBridgeProvider).createReplay(
          ArReplayRequest(
            albumId: album.id,
            albumName: album.name,
            photos: [
              for (final photo in album.photos)
                ArReplayPhoto(
                  createdAt: photo.createdAt,
                  id: photo.id,
                  title: photo.title,
                ),
            ],
            sceneAnchor: ArSceneAnchor(
              label: album.name,
              sceneSignature: album.sceneSignature,
            ),
          ),
        );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已为「${album.name}」生成 AR 同场景重现')),
    );

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _ArReplayPanel(album: album, plan: plan),
        ),
      ),
    );
  }

  Future<void> _handleNfcAction(
    _CategoryAlbum album,
    _AlbumNfcAction action,
  ) async {
    if (action == _AlbumNfcAction.shareOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已准备通过 NFC 分享「${album.name}」相册内容')),
      );
      return;
    }

    setState(() {
      album.isCollaborative = true;
      album.ownerCount = album.ownerCount < 2 ? 2 : album.ownerCount;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('「${album.name}」已设为多人相册')),
    );
  }

  void _addPhotoToAlbum(_CategoryAlbum album) {
    final nextIndex = album.photos.length + 1;
    final now = DateTime.now();

    setState(() {
      album.photos.add(
        _AlbumPhoto(
          createdAt: now,
          id: '${album.id}_photo_${nextIndex}_${now.microsecondsSinceEpoch}',
          title: '${album.name} 新照片 $nextIndex',
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已向「${album.name}」添加照片')),
    );
  }
}

class _CreateAlbumDialog extends StatefulWidget {
  const _CreateAlbumDialog();

  @override
  State<_CreateAlbumDialog> createState() => _CreateAlbumDialogState();
}

class _CreateAlbumDialogState extends State<_CreateAlbumDialog> {
  final _customController = TextEditingController();
  _CategoryAlbumPreset _selectedPreset = _CategoryAlbumPreset.family;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isCustom = _selectedPreset == _CategoryAlbumPreset.other;

    return AlertDialog(
      title: const Text('建立文件夹'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in _CategoryAlbumPreset.values)
                  ChoiceChip(
                    avatar: Icon(
                      preset.icon,
                      size: 18,
                      color: _selectedPreset == preset
                          ? colors.onSecondaryContainer
                          : colors.onSurfaceVariant,
                    ),
                    label: Text(preset.label),
                    selected: _selectedPreset == preset,
                    onSelected: (_) {
                      setState(() {
                        _selectedPreset = preset;
                      });
                    },
                  ),
              ],
            ),
            if (isCustom) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _customController,
                autofocus: true,
                maxLength: 12,
                decoration: const InputDecoration(
                  labelText: '自定义种类',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.create_new_folder_outlined),
          label: const Text('创建'),
        ),
      ],
    );
  }

  void _submit() {
    final customName = _customController.text.trim();
    if (_selectedPreset == _CategoryAlbumPreset.other && customName.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _CategoryAlbum(
        id: 'album_${DateTime.now().microsecondsSinceEpoch}',
        icon: _selectedPreset.icon,
        photos: _seedPhotosForAlbum(
          _selectedPreset == _CategoryAlbumPreset.other
              ? customName
              : _selectedPreset.label,
        ),
        name: _selectedPreset == _CategoryAlbumPreset.other
            ? customName
            : _selectedPreset.label,
      ),
    );
  }
}

class _EmptyCategoryPanel extends StatelessWidget {
  const _EmptyCategoryPanel({required this.onCreate});

  final VoidCallback onCreate;

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
            Icon(Icons.folder_special_outlined,
                size: 44, color: colors.primary),
            const SizedBox(height: 12),
            Text(
              '还没有比邻环相册',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('建立文件夹'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArReplayPanel extends StatelessWidget {
  const _ArReplayPanel({
    required this.album,
    required this.plan,
  });

  final _CategoryAlbum album;
  final ArReplayPlan plan;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.view_in_ar, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${album.name} AR 同场景重现',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          plan.sceneMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 14),
        _ArMovingPhotoPreview(plan: plan),
        const SizedBox(height: 14),
        _ArReplayInfoTile(
          icon: Icons.sensors_outlined,
          title: plan.sceneMatched ? '同场景已命中' : '等待同场景识别',
          subtitle: '场景签名：${album.sceneSignature}',
        ),
        _ArReplayInfoTile(
          icon: Icons.animation_outlined,
          title: '图片动效',
          subtitle: plan.animationSummary,
        ),
        _ArReplayInfoTile(
          icon: Icons.integration_instructions_outlined,
          title: 'Unity 接口预留',
          subtitle:
              '${UnityArReplayBridge.channelName} · ${UnityArReplayBridge.createReplayMethod}',
        ),
        const SizedBox(height: 10),
        Text(
          'AR 图片层',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        for (final overlay in plan.overlays)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: Text('${overlay.slot + 1}'),
            ),
            title: Text(overlay.photoTitle),
            subtitle: Text(
                '${overlay.animation.label} · 景深 ${overlay.depth.toStringAsFixed(1)}m'),
          ),
      ],
    );
  }
}

class _ArReplayInfoTile extends StatelessWidget {
  const _ArReplayInfoTile({
    required this.icon,
    required this.subtitle,
    required this.title,
  });

  final IconData icon;
  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: colors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _ArMovingPhotoPreview extends StatefulWidget {
  const _ArMovingPhotoPreview({required this.plan});

  final ArReplayPlan plan;

  @override
  State<_ArMovingPhotoPreview> createState() => _ArMovingPhotoPreviewState();
}

class _ArMovingPhotoPreviewState extends State<_ArMovingPhotoPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final overlays = widget.plan.overlays.take(5).toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: SizedBox(
        height: 220,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final phase = _controller.value * math.pi * 2;
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.primaryContainer.withValues(alpha: 0.6),
                          colors.tertiaryContainer.withValues(alpha: 0.42),
                        ],
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 14,
                  left: 14,
                  child: Text('AR Scene Preview'),
                ),
                for (var index = 0; index < overlays.length; index++)
                  _MovingArPhotoCard(
                    overlay: overlays[index],
                    phase: phase,
                    index: index,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MovingArPhotoCard extends StatelessWidget {
  const _MovingArPhotoCard({
    required this.index,
    required this.overlay,
    required this.phase,
  });

  final int index;
  final ArPhotoOverlay overlay;
  final double phase;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final orbit = phase + index * 0.72;
    final dx = math.cos(orbit) * (18 + index * 5);
    final dy = math.sin(orbit) * (10 + index * 4);
    final scale = 0.86 + math.sin(orbit) * 0.04;

    return Transform.translate(
      offset: Offset(dx + (index - 2) * 34, dy),
      child: Transform.scale(
        scale: scale,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                blurRadius: 18,
                color: Color(0x26000000),
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            width: 104,
            height: 132,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: [
                            colors.primaryContainer,
                            colors.secondaryContainer,
                          ],
                        ),
                      ),
                      child: const Center(child: Icon(Icons.photo_outlined)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    overlay.photoTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
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

class _TriRingSocialPanel extends ConsumerWidget {
  const _TriRingSocialPanel({
    required this.albums,
    required this.enabled,
    required this.onPhotoToggled,
    required this.onToggle,
    required this.selectedPhotoIds,
  });

  final List<_CategoryAlbum> albums;
  final bool enabled;
  final void Function(TriRingType type, String photoId) onPhotoToggled;
  final ValueChanged<bool> onToggle;
  final Map<TriRingType, Set<String>> selectedPhotoIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final photoEntries = [
      for (final album in albums)
        for (final photo in album.photos)
          _TriRingPhotoEntry(
            albumName: album.name,
            id: '${album.name}-${photo.title}-${photo.createdAt.toIso8601String()}',
            photo: photo,
          ),
    ];
    final selectedEntriesByRing = {
      for (final type in TriRingType.values)
        type: photoEntries
            .where((entry) => selectedPhotoIds[type]!.contains(entry.id))
            .take(triRingMaxPhotosPerRing)
            .toList(),
    };
    final agentRequest = TriRingAgentRequest(
      socialEnabled: enabled,
      rings: [
        for (final type in TriRingType.values)
          TriRingPhotoSelection(
            type: type,
            photos: [
              for (final entry in selectedEntriesByRing[type]!)
                TriRingAgentPhoto(
                  albumName: entry.albumName,
                  createdAt: entry.photo.createdAt,
                  id: entry.id,
                  title: entry.photo.title,
                ),
            ],
          ),
      ],
    );
    final agentPlan = ref.watch(triRingAgentPlanProvider(agentRequest));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hub_outlined, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '个人三色环 social',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      Text(
                        enabled ? '每个环选择 3-10 张照片' : '关闭时保留原有比邻环功能',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(value: enabled, onChanged: onToggle),
              ],
            ),
            if (enabled) ...[
              const SizedBox(height: 14),
              _TriRingPreview(entriesByRing: selectedEntriesByRing),
              const SizedBox(height: 12),
              _TriRingAgentInsight(plan: agentPlan),
              const SizedBox(height: 12),
              if (photoEntries.isEmpty)
                Text(
                  '建立相册后即可从照片中选择三色环内容。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final type in TriRingType.values) ...[
                      _TriRingPhotoPicker(
                        entries: photoEntries,
                        selectedIds: selectedPhotoIds[type]!,
                        type: type,
                        onPhotoToggled: onPhotoToggled,
                      ),
                      if (type != TriRingType.values.last)
                        const SizedBox(height: 14),
                    ],
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TriRingAgentInsight extends StatelessWidget {
  const _TriRingAgentInsight({required this.plan});

  final AsyncValue<TriRingAgentPlan> plan;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: plan.when(
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.headline,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data.guidance,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 10),
              for (final ring in data.rings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 56,
                        child: Text(
                          ring.name,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${ring.colorName} · ${ring.selectedCount}/$triRingMaxPhotosPerRing：${ring.insight}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              if (data.imageAnalyses.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '图片分析',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                for (final analysis in data.imageAnalyses.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${analysis.ringName} · ${analysis.photoTitle}：${analysis.emotionTag}，${analysis.visualSignal}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              Text(
                '用户画像：${data.profile.persona}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                data.profile.traits.isEmpty
                    ? data.profile.matchingVector
                    : '${data.profile.matchingVector} · ${data.profile.traits.join(' / ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              if (data.matches.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '匹配系统',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                for (final match in data.matches)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${match.title} ${match.score}%：${match.reason}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ],
          ),
          error: (_, __) => Text(
            '智能体接口暂不可用，已保留本地三色环选择。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.error,
                ),
          ),
          loading: () => Row(
            children: [
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                '智能体正在整理三色环...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TriRingPhotoPicker extends StatelessWidget {
  const _TriRingPhotoPicker({
    required this.entries,
    required this.onPhotoToggled,
    required this.selectedIds,
    required this.type,
  });

  final List<_TriRingPhotoEntry> entries;
  final void Function(TriRingType type, String photoId) onPhotoToggled;
  final Set<String> selectedIds;
  final TriRingType type;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enough = selectedIds.length >= triRingMinPhotosPerRing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                type.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Text(
              '${selectedIds.length}/$triRingMaxPhotosPerRing',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: enough ? colors.primary : colors.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          enough ? '已达到基础分析要求，可继续补充照片。' : '至少选择 $triRingMinPhotosPerRing 张照片。',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in entries)
              FilterChip(
                avatar: const Icon(Icons.photo_outlined, size: 18),
                label: Text('${entry.albumName} · ${entry.photo.title}'),
                selected: selectedIds.contains(entry.id),
                onSelected: (_) => onPhotoToggled(type, entry.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _TriRingPreview extends StatelessWidget {
  const _TriRingPreview({required this.entriesByRing});

  final Map<TriRingType, List<_TriRingPhotoEntry>> entriesByRing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const ringColors = [
      Color(0xFF22A7F2),
      Color(0xFFFF6B5A),
      Color(0xFFFFC857),
    ];

    return SizedBox(
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var index = 0; index < 3; index++)
            Positioned(
              left: 42 + index * 48,
              top: index == 1 ? 26 : 8,
              child: _TriRingCircle(
                borderColor: ringColors[index],
                label:
                    '${TriRingType.values[index].label}\n${entriesByRing[TriRingType.values[index]]!.length}/$triRingMaxPhotosPerRing',
              ),
            ),
          if (entriesByRing.values.every((entries) => entries.isEmpty))
            Positioned(
              bottom: 0,
              child: Text(
                '开启后为每个环选择照片生成画像与匹配建议',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TriRingCircle extends StatelessWidget {
  const _TriRingCircle({
    required this.borderColor,
    required this.label,
  });

  final Color borderColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.86),
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 7),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            color: Color(0x22000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: 92,
        height: 92,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TriRingPhotoEntry {
  const _TriRingPhotoEntry({
    required this.albumName,
    required this.id,
    required this.photo,
  });

  final String albumName;
  final String id;
  final _AlbumPhoto photo;
}

class _CategoryAlbumCard extends StatelessWidget {
  const _CategoryAlbumCard({
    required this.album,
    required this.onCreateMemoryVideo,
    required this.onStartArReplay,
    required this.onTap,
  });

  final _CategoryAlbum album;
  final VoidCallback onCreateMemoryVideo;
  final VoidCallback onStartArReplay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(album.icon, size: 34, color: colors.primary),
                    const Spacer(),
                    if (album.isCollaborative)
                      Icon(
                        Icons.group_outlined,
                        size: 20,
                        color: colors.secondary,
                      ),
                    PopupMenuButton<_AlbumCardAction>(
                      tooltip: '相册操作',
                      icon: const Icon(Icons.more_horiz, size: 20),
                      onSelected: (action) {
                        switch (action) {
                          case _AlbumCardAction.arReplay:
                            onStartArReplay();
                          case _AlbumCardAction.memoryVideo:
                            onCreateMemoryVideo();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _AlbumCardAction.arReplay,
                          child: _AlbumActionMenuItem(
                            icon: Icons.view_in_ar,
                            label: 'AR 同场景重现',
                          ),
                        ),
                        PopupMenuItem(
                          value: _AlbumCardAction.memoryVideo,
                          child: _AlbumActionMenuItem(
                            icon: Icons.view_in_ar_outlined,
                            label: '剪辑回忆视频',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  album.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${album.photos.length} 张照片',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
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

class _AlbumActionMenuItem extends StatelessWidget {
  const _AlbumActionMenuItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}

enum _AlbumCardAction {
  arReplay,
  memoryVideo,
}

enum _AlbumDetailAction {
  nfc,
  arReplay,
  addPhoto,
}

class _AlbumDetailView extends StatelessWidget {
  const _AlbumDetailView({
    required this.album,
    required this.onBack,
    required this.onAddPhoto,
    required this.onNfcAction,
    required this.onStartArReplay,
  });

  final _CategoryAlbum album;
  final VoidCallback onBack;
  final void Function(_CategoryAlbum album) onAddPhoto;
  final void Function(_CategoryAlbum album, _AlbumNfcAction action) onNfcAction;
  final void Function(_CategoryAlbum album) onStartArReplay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final groupedPhotos = _groupPhotosByDate(album.photos);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: '返回比邻环',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            Icon(album.icon, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _AlbumOwnerBadge(count: album.ownerCount),
                      Text(
                        album.isCollaborative
                            ? '多人相册'
                            : '${album.photos.length} 张照片',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<_AlbumDetailAction>(
              tooltip: '相册详情功能',
              icon: const Icon(Icons.add),
              onSelected: (action) {
                switch (action) {
                  case _AlbumDetailAction.nfc:
                    _showAlbumNfcSheet(context);
                  case _AlbumDetailAction.arReplay:
                    onStartArReplay(album);
                  case _AlbumDetailAction.addPhoto:
                    onAddPhoto(album);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _AlbumDetailAction.nfc,
                  child: _AlbumActionMenuItem(
                    icon: Icons.nfc_outlined,
                    label: 'NFC 分享',
                  ),
                ),
                PopupMenuItem(
                  value: _AlbumDetailAction.arReplay,
                  child: _AlbumActionMenuItem(
                    icon: Icons.view_in_ar,
                    label: 'AR 同场景重现',
                  ),
                ),
                PopupMenuItem(
                  value: _AlbumDetailAction.addPhoto,
                  child: _AlbumActionMenuItem(
                    icon: Icons.add_photo_alternate_outlined,
                    label: '添加照片',
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final group in groupedPhotos.entries) ...[
          Text(
            group.key,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: group.value.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisExtent: 126,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              return _AlbumPhotoTile(photo: group.value[index]);
            },
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }

  Future<void> _showAlbumNfcSheet(BuildContext context) async {
    final action = await showModalBottomSheet<_AlbumNfcAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('仅用 NFC 分享该相册内容'),
                subtitle: const Text('被分享者只能打开和查看该相册。'),
                onTap: () {
                  Navigator.of(context).pop(_AlbumNfcAction.shareOnly);
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_add_outlined),
                title: const Text('变成多人相册'),
                subtitle: const Text('被分享者加入后可以共同维护这个相册。'),
                onTap: () {
                  Navigator.of(context).pop(_AlbumNfcAction.collaborative);
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (action != null) {
      onNfcAction(album, action);
    }
  }
}

class _AlbumPhotoTile extends StatelessWidget {
  const _AlbumPhotoTile({required this.photo});

  final _AlbumPhoto photo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              photo.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumOwnerBadge extends StatelessWidget {
  const _AlbumOwnerBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_outlined,
              color: colors.onSecondaryContainer,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              '所有权 $count 人',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryAlbum {
  _CategoryAlbum({
    required this.id,
    required this.icon,
    required this.name,
    required this.photos,
  });

  final String id;
  final IconData icon;
  bool isCollaborative = false;
  final String name;
  int ownerCount = 1;
  final List<_AlbumPhoto> photos;

  String get sceneSignature {
    return '$id:${photos.map((photo) => photo.id).join('|')}';
  }
}

class _AlbumPhoto {
  const _AlbumPhoto({
    required this.createdAt,
    required this.id,
    required this.title,
  });

  final DateTime createdAt;
  final String id;
  final String title;
}

enum _AlbumNfcAction {
  shareOnly,
  collaborative,
}

enum _CategoryAlbumPreset {
  family('家庭', Icons.family_restroom_outlined),
  friendship('友谊', Icons.groups_outlined),
  love('爱情', Icons.favorite_border),
  other('其他', Icons.edit_note_outlined);

  const _CategoryAlbumPreset(this.label, this.icon);

  final IconData icon;
  final String label;
}

List<_AlbumPhoto> _seedPhotosForAlbum(String albumName) {
  return [
    _AlbumPhoto(
      createdAt: DateTime(2026, 6, 6),
      id: '${albumName}_photo_1',
      title: '$albumName 照片 1',
    ),
    _AlbumPhoto(
      createdAt: DateTime(2026, 6, 6),
      id: '${albumName}_photo_2',
      title: '$albumName 照片 2',
    ),
    _AlbumPhoto(
      createdAt: DateTime(2026, 6, 5),
      id: '${albumName}_photo_3',
      title: '$albumName 照片 3',
    ),
    _AlbumPhoto(
      createdAt: DateTime(2026, 5, 28),
      id: '${albumName}_photo_4',
      title: '$albumName 照片 4',
    ),
  ];
}

Map<String, List<_AlbumPhoto>> _groupPhotosByDate(List<_AlbumPhoto> photos) {
  final sorted = [...photos]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final groups = <String, List<_AlbumPhoto>>{};

  for (final photo in sorted) {
    final key = _formatDate(photo.createdAt);
    groups.putIfAbsent(key, () => []).add(photo);
  }

  return groups;
}

String _formatDate(DateTime date) {
  return '${date.year}年${date.month}月${date.day}日';
}
