import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/placeholder_panel.dart';

class ImmersiveReplayScreen extends StatelessWidget {
  const ImmersiveReplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 2,
      title: '回忆',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          PlaceholderPanel(
            icon: Icons.play_circle_outline,
            title: '回忆重现',
            subtitle: '这里用于播放照片回忆、VR 视频或沉浸式场景，后续会连接照片集合和 NFC 内容。',
          ),
        ],
      ),
    );
  }
}
