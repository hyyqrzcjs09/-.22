import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/placeholder_panel.dart';

class PhotosScreen extends StatelessWidget {
  const PhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 1,
      title: '日期',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          PlaceholderPanel(
            icon: Icons.calendar_month_outlined,
            title: '按日期整理照片',
            subtitle: '这里用于按拍摄日期生成时间轴，后续会按年、月、日查看照片和回忆。',
          ),
        ],
      ),
    );
  }
}
