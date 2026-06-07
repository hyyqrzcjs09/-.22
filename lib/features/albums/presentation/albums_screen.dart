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
  final _triRingFriendIds = <String>{};
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
          onAddComment: _addAlbumComment,
          onStartArReplay: _startArReplay,
        ),
      );
    }

    return AppScaffold(
      selectedIndex: 1,
      title: '比邻环',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TriRingSocialPanel(
            albums: _albums,
            enabled: _socialEnabled,
            selectedPhotoIds: _triRingPhotoIds,
            friendIds: _triRingFriendIds,
            onFriendToggled: _toggleTriRingFriend,
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
          _AlbumsOverviewPanel(
            albums: _albums,
            onCreate: _showCreateAlbumDialog,
            onCreateMemoryVideo: _createMemoryVideo,
            onOpenAlbum: (album) {
              setState(() {
                _openedAlbum = album;
              });
            },
            onStartArReplay: _startArReplay,
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

  void _toggleTriRingFriend(TriRingMatchSuggestion match) {
    final willAdd = !_triRingFriendIds.contains(match.title);

    setState(() {
      if (willAdd) {
        _triRingFriendIds.add(match.title);
      } else {
        _triRingFriendIds.remove(match.title);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            willAdd ? '已添加「${match.title}」为好友' : '已取消「${match.title}」好友推荐'),
      ),
    );
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

  void _addAlbumComment(_CategoryAlbum album, String text) {
    final value = text.trim();
    if (value.isEmpty) {
      return;
    }

    setState(() {
      album.comments.add(
        _AlbumComment(
          author: '我',
          color: Colors.black,
          createdAt: DateTime.now(),
          text: value,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已在「${album.name}」添加评论')),
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
    final albumName = _selectedPreset == _CategoryAlbumPreset.other
        ? customName
        : _selectedPreset.label;

    Navigator.of(context).pop(
      _CategoryAlbum(
        comments: _seedCommentsForAlbum(albumName),
        id: 'album_${DateTime.now().microsecondsSinceEpoch}',
        icon: _selectedPreset.icon,
        photos: _seedPhotosForAlbum(albumName),
        name: albumName,
      ),
    );
  }
}

class _AlbumsOverviewPanel extends StatelessWidget {
  const _AlbumsOverviewPanel({
    required this.albums,
    required this.onCreate,
    required this.onCreateMemoryVideo,
    required this.onOpenAlbum,
    required this.onStartArReplay,
  });

  final List<_CategoryAlbum> albums;
  final VoidCallback onCreate;
  final void Function(_CategoryAlbum album) onCreateMemoryVideo;
  final void Function(_CategoryAlbum album) onOpenAlbum;
  final void Function(_CategoryAlbum album) onStartArReplay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final albumCount = albums.length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: colors.outlineVariant.withValues(alpha: 0.72)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            color: Color(0x16000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.category_outlined,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '比邻环相册',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$albumCount 个相册',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: '建立文件夹',
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const Divider(height: 30),
            if (albums.isEmpty)
              _AlbumsEmptyState(onCreate: onCreate)
            else
              GridView.builder(
                itemCount: albums.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisExtent: 182,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final album = albums[index];
                  return _CategoryAlbumCard(
                    album: album,
                    onStartArReplay: () => onStartArReplay(album),
                    onCreateMemoryVideo: () => onCreateMemoryVideo(album),
                    onTap: () => onOpenAlbum(album),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _AlbumsEmptyState extends StatelessWidget {
  const _AlbumsEmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 0),
      child: Column(
        children: [
          Icon(
            Icons.folder_special_outlined,
            size: 44,
            color: colors.onSurface,
          ),
          const SizedBox(height: 12),
          Text(
            '还没有比邻环相册',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('建立文件夹'),
          ),
        ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            color: Color(0x12000000),
            offset: Offset(0, 8),
          ),
        ],
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
                      color: colors.primaryContainer.withValues(alpha: 0.28),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
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

class _TriRingSocialPanel extends ConsumerStatefulWidget {
  const _TriRingSocialPanel({
    required this.albums,
    required this.enabled,
    required this.friendIds,
    required this.onFriendToggled,
    required this.onPhotoToggled,
    required this.onToggle,
    required this.selectedPhotoIds,
  });

  final List<_CategoryAlbum> albums;
  final bool enabled;
  final Set<String> friendIds;
  final ValueChanged<TriRingMatchSuggestion> onFriendToggled;
  final void Function(TriRingType type, String photoId) onPhotoToggled;
  final ValueChanged<bool> onToggle;
  final Map<TriRingType, Set<String>> selectedPhotoIds;

  @override
  ConsumerState<_TriRingSocialPanel> createState() =>
      _TriRingSocialPanelState();
}

class _TriRingSocialPanelState extends ConsumerState<_TriRingSocialPanel> {
  final _shareController = TextEditingController();
  bool _shareImageAttached = false;

  @override
  void dispose() {
    _shareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final photoEntries = [
      for (final album in widget.albums)
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
            .where((entry) => widget.selectedPhotoIds[type]!.contains(entry.id))
            .take(triRingMaxPhotosPerRing)
            .toList(),
    };
    final agentRequest = TriRingAgentRequest(
      socialEnabled: widget.enabled,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            color: Color(0x12000000),
            offset: Offset(0, 8),
          ),
        ],
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
                        widget.enabled ? '每个环选择 3-10 张照片' : '关闭时保留原有比邻环功能',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(value: widget.enabled, onChanged: widget.onToggle),
              ],
            ),
            if (widget.enabled) ...[
              const SizedBox(height: 14),
              _TriRingPreview(entriesByRing: selectedEntriesByRing),
              const SizedBox(height: 12),
              _TriRingAgentInsight(
                friendIds: widget.friendIds,
                onFriendToggled: widget.onFriendToggled,
                plan: agentPlan,
              ),
              const SizedBox(height: 12),
              _TriRingFriendShareBox(
                controller: _shareController,
                friendCount: widget.friendIds.length,
                imageAttached: _shareImageAttached,
                onSend: _sendFriendShare,
                onToggleImage: () {
                  setState(() {
                    _shareImageAttached = !_shareImageAttached;
                  });
                },
              ),
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
                        selectedIds: widget.selectedPhotoIds[type]!,
                        type: type,
                        onPhotoToggled: widget.onPhotoToggled,
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

  void _sendFriendShare() {
    final text = _shareController.text.trim();
    if (widget.friendIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先从同频匹配里添加好友后再分享')),
      );
      return;
    }

    if (text.isEmpty && !_shareImageAttached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择图片或输入文字后再分享')),
      );
      return;
    }

    _shareController.clear();
    setState(() {
      _shareImageAttached = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已向好友分享图片和文字')),
    );
  }
}

class _TriRingFriendShareBox extends StatelessWidget {
  const _TriRingFriendShareBox({
    required this.controller,
    required this.friendCount,
    required this.imageAttached,
    required this.onSend,
    required this.onToggleImage,
  });

  final TextEditingController controller;
  final int friendCount;
  final bool imageAttached;
  final VoidCallback onSend;
  final VoidCallback onToggleImage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.ios_share_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '好友分享',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Text(
                  '$friendCount 位好友',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '写一段想和好友分享的文字',
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  avatar: Icon(
                    imageAttached
                        ? Icons.check_circle
                        : Icons.add_photo_alternate_outlined,
                    size: 18,
                  ),
                  label: Text(imageAttached ? '已选择图片' : '选择图片'),
                  selected: imageAttached,
                  onSelected: (_) => onToggleImage(),
                ),
                FilledButton.icon(
                  onPressed: onSend,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('分享给好友'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TriRingAgentInsight extends StatelessWidget {
  const _TriRingAgentInsight({
    required this.friendIds,
    required this.onFriendToggled,
    required this.plan,
  });

  final Set<String> friendIds;
  final ValueChanged<TriRingMatchSuggestion> onFriendToggled;
  final AsyncValue<TriRingAgentPlan> plan;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
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
                  '同频匹配推荐',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  '匹配度超过 70% 后才进入推荐，是否加好友由你确认。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 6),
                for (final match
                    in data.matches.where((match) => match.score >= 70))
                  _TriRingMatchCard(
                    friendAdded: friendIds.contains(match.title),
                    match: match,
                    onFriendToggled: () => onFriendToggled(match),
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

class _TriRingMatchCard extends StatelessWidget {
  const _TriRingMatchCard({
    required this.friendAdded,
    required this.match,
    required this.onFriendToggled,
  });

  final bool friendAdded;
  final TriRingMatchSuggestion match;
  final VoidCallback onFriendToggled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  Text(
                    '${match.score}%',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: match.score.clamp(0, 100).toDouble() / 100,
                  backgroundColor: colors.surfaceContainerHighest,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                match.reason,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onFriendToggled,
                  icon: Icon(
                    friendAdded
                        ? Icons.person_remove_alt_1_outlined
                        : Icons.person_add_alt_1_outlined,
                  ),
                  label: Text(friendAdded ? '已加好友' : '加好友'),
                ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
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
      color: Colors.white,
      elevation: 1.5,
      borderRadius: BorderRadius.circular(8),
      shadowColor: const Color(0x1A000000),
      surfaceTintColor: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.74)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          album.icon,
                          size: 24,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
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
                const SizedBox(height: 12),
                _AlbumMiniPhotoStrip(photoCount: album.photos.length),
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

class _AlbumMiniPhotoStrip extends StatelessWidget {
  const _AlbumMiniPhotoStrip({required this.photoCount});

  final int photoCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const previewColors = [
      Color(0xFFF4F4F5),
      Color(0xFFE4E4E7),
      Color(0xFFD4D4D8),
    ];

    return SizedBox(
      height: 38,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final visibleCount = math.min(
            photoCount,
            constraints.maxWidth < 170 ? 2 : 3,
          );
          final remainingCount = photoCount - visibleCount;

          return Row(
            children: [
              for (var index = 0; index < visibleCount; index++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: previewColors[index],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(
                        Icons.photo_outlined,
                        size: 17,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              if (remainingCount > 0)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.64),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    child: Text(
                      '+$remainingCount',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ),
            ],
          );
        },
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
    required this.onAddComment,
    required this.onAddPhoto,
    required this.onNfcAction,
    required this.onStartArReplay,
  });

  final _CategoryAlbum album;
  final VoidCallback onBack;
  final void Function(_CategoryAlbum album, String text) onAddComment;
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
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
            boxShadow: const [
              BoxShadow(
                blurRadius: 18,
                color: Color(0x12000000),
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                IconButton(
                  tooltip: '返回比邻环',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(album.icon, color: colors.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 10),
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
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
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
          ),
        ),
        const SizedBox(height: 16),
        _AlbumCommentPanel(
          album: album,
          onAddComment: (text) => onAddComment(album, text),
        ),
        const SizedBox(height: 16),
        for (final group in groupedPhotos.entries)
          _AlbumTimelineGroup(
            comments: album.comments,
            dateLabel: group.key,
            onPhotoTap: (photo) => _showPhotoViewer(context, photo),
            photos: group.value,
          ),
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

  void _showPhotoViewer(BuildContext context, _AlbumPhoto photo) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
            maxWidth: 720,
          ),
          child: _AlbumPhotoViewer(
            comments: album.comments,
            photo: photo,
          ),
        ),
      ),
    );
  }
}

class _AlbumCommentPanel extends StatefulWidget {
  const _AlbumCommentPanel({
    required this.album,
    required this.onAddComment,
  });

  final _CategoryAlbum album;
  final ValueChanged<String> onAddComment;

  @override
  State<_AlbumCommentPanel> createState() => _AlbumCommentPanelState();
}

class _AlbumCommentPanelState extends State<_AlbumCommentPanel> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.forum_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '相册评论',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Text(
                  '${widget.album.comments.length} 条',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final comment in widget.album.comments.take(4))
                  Chip(
                    avatar: CircleAvatar(
                      backgroundColor: comment.color,
                      child: Text(
                        comment.author.isEmpty
                            ? '?'
                            : comment.author.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    label: Text('${comment.author}：${comment.text}'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '相册所有人都可以评论',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final text = _controller.text;
                    widget.onAddComment(text);
                    if (text.trim().isNotEmpty) {
                      _controller.clear();
                    }
                  },
                  child: const Text('发送评论'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumTimelineGroup extends StatelessWidget {
  const _AlbumTimelineGroup({
    required this.comments,
    required this.dateLabel,
    required this.onPhotoTap,
    required this.photos,
  });

  final List<_AlbumComment> comments;
  final String dateLabel;
  final ValueChanged<_AlbumPhoto> onPhotoTap;
  final List<_AlbumPhoto> photos;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 14.0;
        const tileHeight = 126.0;
        const spacing = 10.0;
        final timelineWidth = constraints.maxWidth < 560 ? 110.0 : 144.0;
        final gridWidth = math.max(
          180.0,
          constraints.maxWidth - timelineWidth - gap,
        );
        final columns = math.max(1, (gridWidth / 180).floor());
        final rows = (photos.length / columns).ceil();
        final gridHeight = rows * tileHeight + math.max(0, rows - 1) * spacing;
        final groupHeight = math.max(gridHeight, 112.0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: SizedBox(
            height: groupHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: timelineWidth,
                  height: groupHeight,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 8,
                        top: 0,
                        bottom: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.outlineVariant,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const SizedBox(width: 2),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 7,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 10,
                                color: Color(0x1A000000),
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const SizedBox(width: 18, height: 18),
                        ),
                      ),
                      Positioned(
                        left: 28,
                        right: 0,
                        top: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${photos.length} 张',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: gap),
                Expanded(
                  child: SizedBox(
                    height: gridHeight,
                    child: GridView.builder(
                      itemCount: photos.length,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: tileHeight,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                      ),
                      itemBuilder: (context, index) {
                        return _AlbumPhotoTile(
                          commentCount: comments.length,
                          onTap: () => onPhotoTap(photos[index]),
                          photo: photos[index],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlbumPhotoTile extends StatelessWidget {
  const _AlbumPhotoTile({
    required this.commentCount,
    required this.onTap,
    required this.photo,
  });

  final int commentCount;
  final VoidCallback onTap;
  final _AlbumPhoto photo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 1,
      shadowColor: const Color(0x16000000),
      surfaceTintColor: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.74),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_outlined),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              '弹幕 $commentCount',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
        ),
      ),
    );
  }
}

class _AlbumPhotoViewer extends StatefulWidget {
  const _AlbumPhotoViewer({
    required this.comments,
    required this.photo,
  });

  final List<_AlbumComment> comments;
  final _AlbumPhoto photo;

  @override
  State<_AlbumPhotoViewer> createState() => _AlbumPhotoViewerState();
}

class _AlbumPhotoViewerState extends State<_AlbumPhotoViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _barrageEnabled = true;
  bool _showBarrageSettings = false;
  Color _barrageColor = Colors.white;
  double _barrageOpacity = 0.84;
  double _barrageSpeed = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 13),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sheetHeight = math.min(
      560.0,
      MediaQuery.sizeOf(context).height * 0.86,
    );
    final viewerHeight = math.min(
      260.0,
      sheetHeight * 0.48,
    );

    return SafeArea(
      child: SizedBox(
        height: sheetHeight,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.photo.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  Text(
                    '${widget.comments.length} 条弹幕',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: viewerHeight,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            border: Border.all(color: colors.outlineVariant),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: colors.onSurfaceVariant,
                              size: 54,
                            ),
                          ),
                        ),
                      ),
                      if (_barrageEnabled && widget.comments.isNotEmpty)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _BarrageOverlay(
                              animation: _controller,
                              color: _barrageColor.withValues(
                                alpha: _barrageOpacity,
                              ),
                              comments: widget.comments,
                              speed: _barrageSpeed,
                            ),
                          ),
                        ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Tooltip(
                          message: '弹幕设置',
                          child: IconButton.filled(
                            onPressed: () {
                              setState(() {
                                _showBarrageSettings = !_showBarrageSettings;
                              });
                            },
                            icon: const Icon(Icons.subtitles_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showBarrageSettings) ...[
                const SizedBox(height: 12),
                _BarrageSettingsPanel(
                  color: _barrageColor,
                  enabled: _barrageEnabled,
                  opacity: _barrageOpacity,
                  speed: _barrageSpeed,
                  onColorChanged: (color) {
                    setState(() {
                      _barrageColor = color;
                    });
                  },
                  onEnabledChanged: (value) {
                    setState(() {
                      _barrageEnabled = value;
                    });
                  },
                  onOpacityChanged: (value) {
                    setState(() {
                      _barrageOpacity = value;
                    });
                  },
                  onSpeedChanged: (value) {
                    setState(() {
                      _barrageSpeed = value;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BarrageOverlay extends StatelessWidget {
  const _BarrageOverlay({
    required this.animation,
    required this.color,
    required this.comments,
    required this.speed,
  });

  final Animation<double> animation;
  final Color color;
  final List<_AlbumComment> comments;
  final double speed;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                for (var index = 0; index < comments.length; index++)
                  Positioned(
                    left: _leftFor(index, constraints.maxWidth),
                    top: 18.0 + (index % 5) * 34,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          '${comments[index].author}：${comments[index].text}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  double _leftFor(int index, double width) {
    final progress = (animation.value * speed + index * 0.19) % 1.0;
    return width - progress * (width + 280);
  }
}

class _BarrageSettingsPanel extends StatelessWidget {
  const _BarrageSettingsPanel({
    required this.color,
    required this.enabled,
    required this.opacity,
    required this.speed,
    required this.onColorChanged,
    required this.onEnabledChanged,
    required this.onOpacityChanged,
    required this.onSpeedChanged,
  });

  final Color color;
  final bool enabled;
  final double opacity;
  final double speed;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<double> onOpacityChanged;
  final ValueChanged<double> onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const options = [
      Colors.white,
      Colors.black,
      Color(0xFFE53935),
      Color(0xFF1E88E5),
      Color(0xFFFFB300),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '开启弹幕',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Switch(value: enabled, onChanged: onEnabledChanged),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '弹幕颜色',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final option in options)
                  ChoiceChip(
                    avatar: CircleAvatar(backgroundColor: option),
                    label: Text(option == Colors.white ? '白' : '色'),
                    selected: color == option,
                    onSelected: (_) => onColorChanged(option),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('透明度 ${(opacity * 100).round()}%'),
            Slider(
              min: 0.2,
              max: 1,
              divisions: 8,
              value: opacity,
              onChanged: onOpacityChanged,
            ),
            Text('播放速度 ${speed.toStringAsFixed(1)}x'),
            Slider(
              min: 0.5,
              max: 2,
              divisions: 6,
              value: speed,
              onChanged: onSpeedChanged,
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
    required this.comments,
    required this.id,
    required this.icon,
    required this.name,
    required this.photos,
  });

  final List<_AlbumComment> comments;
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

class _AlbumComment {
  const _AlbumComment({
    required this.author,
    required this.color,
    required this.createdAt,
    required this.text,
  });

  final String author;
  final Color color;
  final DateTime createdAt;
  final String text;
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

List<_AlbumComment> _seedCommentsForAlbum(String albumName) {
  return [
    _AlbumComment(
      author: '我',
      color: Colors.black,
      createdAt: DateTime(2026, 6, 6, 18, 20),
      text: '$albumName 这一天很值得留下',
    ),
    _AlbumComment(
      author: '同行者',
      color: const Color(0xFF424242),
      createdAt: DateTime(2026, 6, 6, 19, 4),
      text: '下次可以把这组做成 AR 回放',
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
