import 'package:flutter/material.dart';

import '../../vr/application/memory_video_store.dart';
import '../../../shared/widgets/app_scaffold.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  final _albums = <_CategoryAlbum>[];
  _CategoryAlbum? _openedAlbum;

  @override
  Widget build(BuildContext context) {
    final openedAlbum = _openedAlbum;

    if (openedAlbum != null) {
      return AppScaffold(
        selectedIndex: 3,
        title: '分类',
        child: _AlbumDetailView(
          album: openedAlbum,
          onBack: () {
            setState(() {
              _openedAlbum = null;
            });
          },
          onNfcAction: _handleNfcAction,
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;

    return AppScaffold(
      selectedIndex: 3,
      title: '分类',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '分类相册',
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

  void _createMemoryVideo(_CategoryAlbum album) {
    MemoryVideoStore.instance.addFromAlbum(
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
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('「${album.name}」已设为多人相册')),
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
              '还没有分类相册',
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

class _CategoryAlbumCard extends StatelessWidget {
  const _CategoryAlbumCard({
    required this.album,
    required this.onCreateMemoryVideo,
    required this.onTap,
  });

  final _CategoryAlbum album;
  final VoidCallback onCreateMemoryVideo;
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
                    IconButton(
                      tooltip: '剪辑回忆视频',
                      onPressed: onCreateMemoryVideo,
                      icon: const Icon(Icons.view_in_ar_outlined, size: 20),
                      visualDensity: VisualDensity.compact,
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

class _AlbumDetailView extends StatelessWidget {
  const _AlbumDetailView({
    required this.album,
    required this.onBack,
    required this.onNfcAction,
  });

  final _CategoryAlbum album;
  final VoidCallback onBack;
  final void Function(_CategoryAlbum album, _AlbumNfcAction action) onNfcAction;

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
              tooltip: '返回分类',
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
            ),
            IconButton.filledTonal(
              tooltip: 'NFC 分享',
              onPressed: () => _showAlbumNfcSheet(context),
              icon: const Icon(Icons.nfc_outlined),
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

class _CategoryAlbum {
  _CategoryAlbum({
    required this.icon,
    required this.name,
    required this.photos,
  });

  final IconData icon;
  bool isCollaborative = false;
  final String name;
  final List<_AlbumPhoto> photos;
}

class _AlbumPhoto {
  const _AlbumPhoto({
    required this.createdAt,
    required this.title,
  });

  final DateTime createdAt;
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
      title: '$albumName 照片 1',
    ),
    _AlbumPhoto(
      createdAt: DateTime(2026, 6, 6),
      title: '$albumName 照片 2',
    ),
    _AlbumPhoto(
      createdAt: DateTime(2026, 6, 5),
      title: '$albumName 照片 3',
    ),
    _AlbumPhoto(
      createdAt: DateTime(2026, 5, 28),
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
