import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../shared/widgets/action_tile.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/status_summary_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 0,
      title: 'PhotoLink VR',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _HeroPanel(),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: StatusSummaryTile(label: '第一阶段', value: '基础工程'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StatusSummaryTile(label: '优先平台', value: 'Android'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ActionTile(
            title: '导入照片',
            subtitle: '拍照或从相册选择照片，开始建立你的记忆库。',
            icon: Icons.add_photo_alternate_outlined,
            onTap: () => context.go(AppRoutes.photos),
          ),
          ActionTile(
            title: '创建相册',
            subtitle: '按地区、时间或种类整理照片。',
            icon: Icons.photo_library_outlined,
            onTap: () => context.go(AppRoutes.albums),
          ),
          ActionTile(
            title: '绑定 NFC',
            subtitle: '把实体标签连接到照片、相册或回放内容。',
            icon: Icons.nfc_outlined,
            onTap: () => context.go(AppRoutes.nfc),
          ),
          ActionTile(
            title: '沉浸式回放',
            subtitle: '用照片集合生成可重看的场景体验。',
            icon: Icons.view_in_ar_outlined,
            onTap: () => context.go(AppRoutes.replay),
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.photo_camera_back_outlined,
              color: colors.onPrimaryContainer),
          const SizedBox(height: 16),
          Text(
            '把照片连接到真实地点',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '按地区、时间、种类整理照片，再用 NFC 标签触发相册和沉浸式回放。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}
