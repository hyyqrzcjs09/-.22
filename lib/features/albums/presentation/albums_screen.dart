import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  final _albums = <_CategoryAlbum>[];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppScaffold(
      selectedIndex: 4,
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
                return _CategoryAlbumCard(album: _albums[index]);
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
  const _CategoryAlbumCard({required this.album});

  final _CategoryAlbum album;

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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(album.icon, size: 34, color: colors.primary),
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
              '0 张照片',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryAlbum {
  const _CategoryAlbum({
    required this.icon,
    required this.name,
  });

  final IconData icon;
  final String name;
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
