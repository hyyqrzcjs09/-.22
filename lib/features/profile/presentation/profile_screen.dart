import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/album_color_picker.dart';
import '../../../shared/widgets/album_display_mode_selector.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../application/user_settings.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final colors = Theme.of(context).colorScheme;

    return AppScaffold(
      selectedIndex: 3,
      title: '我的',
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: settings.albumBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    child: const Icon(Icons.person, size: 34),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.userId ?? '未分配 ID',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          settings.phoneNumber ?? '手机号验证码登录后自动分配 ID',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SettingsPanel(
            title: '相册背景颜色',
            subtitle: '自由设计相册背景色，地点漫游页面会同步使用。',
            child: _AlbumColorPaletteLauncher(
              selected: settings.albumBackgroundColor,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsPanel(
            title: '地点漫游后的展示形式',
            subtitle: '点击地图地点后，仅展示所选形式。',
            child:
                AlbumDisplayModeSelector(selected: settings.albumDisplayMode),
          ),
          const SizedBox(height: 16),
          const _ProfileActionTile(
            icon: Icons.photo_library_outlined,
            title: '本地照片权限',
            subtitle: '管理相册读取和位置照片扫描',
          ),
          const _ProfileActionTile(
            icon: Icons.nfc_outlined,
            title: 'NFC 分享记录',
            subtitle: '查看已绑定的相册和多人相册入口',
          ),
          const _ProfileActionTile(
            icon: Icons.view_in_ar_outlined,
            title: 'VR 回忆设置',
            subtitle: '管理视频生成、过渡和播放偏好',
          ),
        ],
      ),
    );
  }
}

class _AlbumColorPaletteLauncher extends StatelessWidget {
  const _AlbumColorPaletteLauncher({required this.selected});

  final Color selected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '打开调色板',
      child: OutlinedButton.icon(
        onPressed: () => _openPalette(context),
        icon: DecoratedBox(
          decoration: BoxDecoration(
            color: selected,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                blurRadius: 6,
                color: Color(0x26000000),
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const SizedBox(width: 24, height: 24),
        ),
        label: const Text('打开调色板'),
      ),
    );
  }

  void _openPalette(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('相册背景调色板'),
          content: SingleChildScrollView(
            child: AlbumColorPicker(selected: selected),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('完成'),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.child,
    required this.title,
    this.subtitle,
  });

  final Widget child;
  final String? subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.subtitle,
    required this.title,
  });

  final IconData icon;
  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}
