import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/placeholder_panel.dart';

class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 2,
      title: '相册',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          PlaceholderPanel(
            icon: Icons.collections_bookmark_outlined,
            title: '创建第一个相册',
            subtitle: '相册会作为 NFC 绑定和沉浸式回放的核心内容单元。',
          ),
        ],
      ),
    );
  }
}
