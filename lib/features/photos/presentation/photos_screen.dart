import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/category_chip_row.dart';
import '../../../shared/widgets/placeholder_panel.dart';
import '../../../shared/widgets/section_header.dart';

class PhotosScreen extends StatelessWidget {
  const PhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 1,
      title: '照片库',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SectionHeader(title: '分类入口'),
          CategoryChipRow(),
          SizedBox(height: 16),
          PlaceholderPanel(
            icon: Icons.photo_outlined,
            title: '还没有照片',
            subtitle:
                '下一步接入 image_picker 和 photo_manager，实现拍照、导入、上传和 EXIF 信息读取。',
          ),
        ],
      ),
    );
  }
}
