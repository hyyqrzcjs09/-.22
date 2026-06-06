import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/placeholder_panel.dart';

class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 4,
      title: '分类',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          PlaceholderPanel(
            icon: Icons.category_outlined,
            title: '照片分类',
            subtitle: '这里用于按学校、景点、生活区等类型管理照片，后续会连接地图聚合和筛选。',
          ),
        ],
      ),
    );
  }
}
