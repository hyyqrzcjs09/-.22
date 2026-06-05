import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/placeholder_panel.dart';

class NfcScreen extends StatelessWidget {
  const NfcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 3,
      title: 'NFC',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          PlaceholderPanel(
            icon: Icons.nfc_outlined,
            title: '读取或写入 NFC',
            subtitle: 'MVP 中 NFC 标签只写入内容 URL，由后端解析到照片、相册或回放页面。',
          ),
        ],
      ),
    );
  }
}
