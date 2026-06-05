import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/placeholder_panel.dart';

class ImmersiveReplayScreen extends StatelessWidget {
  const ImmersiveReplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 4,
      title: '沉浸式回放',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          PlaceholderPanel(
            icon: Icons.play_circle_outline,
            title: '照片回放体验',
            subtitle: '第一版先实现照片全屏播放、自动转场、暂停继续和横屏模式。',
          ),
        ],
      ),
    );
  }
}
