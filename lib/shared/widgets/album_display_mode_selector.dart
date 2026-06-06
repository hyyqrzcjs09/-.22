import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/application/user_settings.dart';

class AlbumDisplayModeSelector extends ConsumerWidget {
  const AlbumDisplayModeSelector({
    required this.selected,
    super.key,
  });

  final AlbumDisplayMode selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<AlbumDisplayMode>(
      segments: const [
        ButtonSegment(
          value: AlbumDisplayMode.detail,
          icon: Icon(Icons.grid_view_rounded),
          label: Text('相册'),
        ),
        ButtonSegment(
          value: AlbumDisplayMode.stack,
          icon: Icon(Icons.folder_rounded),
          label: Text('相簿'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) {
        ref
            .read(userSettingsProvider.notifier)
            .setAlbumDisplayMode(selection.first);
      },
    );
  }
}
