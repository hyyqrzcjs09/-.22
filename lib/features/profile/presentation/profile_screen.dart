import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../shared/widgets/album_color_picker.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../application/user_settings.dart';
import 'profile_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);

    return AppScaffold(
      selectedIndex: 2,
      title: '我的',
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _AccountProfileCard(
            settings: settings,
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
          const _SettingsLinkPanel(
            route: AppRoutes.profileAlbumDisplayMode,
            title: '地点漫游后的展示形式',
          ),
          const SizedBox(height: 16),
          const _ProfileActionTile(
            icon: Icons.photo_library_outlined,
            route: AppRoutes.profilePhotoPermissions,
            title: '本地照片权限',
            subtitle: '管理相册读取和位置照片扫描',
          ),
          const _ProfileActionTile(
            icon: Icons.nfc_outlined,
            route: AppRoutes.profileNfcShares,
            title: 'NFC 分享记录',
            subtitle: '查看已绑定的相册和多人相册入口',
          ),
          const _ProfileActionTile(
            icon: Icons.view_in_ar_outlined,
            route: AppRoutes.profileArMemories,
            title: 'AR 回忆设置',
            subtitle: '管理视频生成、过渡和播放偏好',
          ),
        ],
      ),
    );
  }
}

class _AccountProfileCard extends StatelessWidget {
  const _AccountProfileCard({required this.settings});

  final UserSettings settings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final displayName = settings.nickname?.trim().isNotEmpty == true
        ? settings.nickname!.trim()
        : settings.userId ?? '未分配 ID';
    final accountLine = settings.nickname?.trim().isNotEmpty == true
        ? settings.userId ?? '登录后自动生成 ID'
        : settings.phoneNumber ?? '手机号验证码登录后自动分配 ID';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      shadowColor: const Color(0x18000000),
      elevation: 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.push(AppRoutes.profileAccount),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        ProfileAvatar(
                          imageBase64: settings.avatarImageBase64,
                          radius: 30,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                accountLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '点击编辑昵称和头像',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: colors.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _NfcFriendExchangeButton(
                phoneNumber: settings.phoneNumber,
                userId: settings.userId,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NfcFriendExchangeButton extends StatelessWidget {
  const _NfcFriendExchangeButton({
    required this.phoneNumber,
    required this.userId,
  });

  final String? phoneNumber;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: 'NFC 碰一碰交朋友',
      child: Material(
        color: colors.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _openExchangeSheet(context),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.nfc_outlined, color: colors.onPrimaryContainer),
          ),
        ),
      ),
    );
  }

  void _openExchangeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: _NfcFriendExchangeSheet(
          phoneNumber: phoneNumber,
          userId: userId,
        ),
      ),
    );
  }
}

class _NfcFriendExchangeSheet extends StatefulWidget {
  const _NfcFriendExchangeSheet({
    required this.phoneNumber,
    required this.userId,
  });

  final String? phoneNumber;
  final String? userId;

  @override
  State<_NfcFriendExchangeSheet> createState() =>
      _NfcFriendExchangeSheetState();
}

class _NfcFriendExchangeSheetState extends State<_NfcFriendExchangeSheet> {
  var _sharePhotoRing = true;
  var _shareAppId = true;
  var _sharePhone = false;
  var _allowFriendRequest = true;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.nfc_outlined,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NFC 碰一碰交朋友',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '与其他安装此 App 的用户互换自己的照片环。',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ExchangePanel(
            title: '联系方式',
            child: Column(
              children: [
                _ExchangeToggle(
                  icon: Icons.badge_outlined,
                  title: '分享 App ID',
                  subtitle: widget.userId ?? '登录后自动生成',
                  value: _shareAppId,
                  onChanged: (value) => setState(() => _shareAppId = value),
                ),
                _ExchangeToggle(
                  icon: Icons.phone_iphone,
                  title: '分享手机号',
                  subtitle: widget.phoneNumber ?? '尚未绑定手机号',
                  value: _sharePhone,
                  onChanged: (value) => setState(() => _sharePhone = value),
                ),
                _ExchangeToggle(
                  icon: Icons.person_add_alt_1_outlined,
                  title: '允许对方发送好友申请',
                  subtitle: '对方收到照片环后，可以选择是否继续联系。',
                  value: _allowFriendRequest,
                  onChanged: (value) {
                    setState(() => _allowFriendRequest = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ExchangePanel(
            title: '照片环交换内容',
            child: Column(
              children: [
                _ExchangeToggle(
                  icon: Icons.all_inclusive,
                  title: '交换自己的照片环',
                  subtitle: '包含三色环选择、画像摘要和匹配入口。',
                  value: _sharePhotoRing,
                  onChanged: (value) {
                    setState(() => _sharePhotoRing = value);
                  },
                ),
                _ExchangeInfoRow(
                  icon: Icons.privacy_tip_outlined,
                  title: '默认不交换原图',
                  subtitle: '只交换照片环摘要和可见封面，原图访问需要再次确认。',
                ),
                _ExchangeInfoRow(
                  icon: Icons.sync_alt,
                  title: '双方确认后建立关系',
                  subtitle: '碰一碰只发出邀请，是否成为好友由双方选择。',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('取消'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _sharePhotoRing ? _startNfcExchange : null,
                  icon: const Icon(Icons.nfc_outlined),
                  label: const Text('开始碰一碰'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startNfcExchange() {
    final sharedContacts = [
      if (_shareAppId) 'App ID',
      if (_sharePhone) '手机号',
      if (_allowFriendRequest) '好友申请入口',
    ].join('、');

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sharedContacts.isEmpty
              ? '已准备通过 NFC 仅交换照片环'
              : '已准备通过 NFC 交换照片环，并分享$sharedContacts',
        ),
      ),
    );
  }
}

class _ExchangePanel extends StatelessWidget {
  const _ExchangePanel({
    required this.child,
    required this.title,
  });

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _ExchangeToggle extends StatelessWidget {
  const _ExchangeToggle({
    required this.icon,
    required this.onChanged,
    required this.subtitle,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final ValueChanged<bool> onChanged;
  final String subtitle;
  final String title;
  final bool value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: colors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ExchangeInfoRow extends StatelessWidget {
  const _ExchangeInfoRow({
    required this.icon,
    required this.subtitle,
    required this.title,
  });

  final IconData icon;
  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: colors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
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
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        ),
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
      ),
    );
  }
}

class _SettingsLinkPanel extends StatelessWidget {
  const _SettingsLinkPanel({
    required this.route,
    required this.title,
  });

  final String route;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(route),
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.route,
    required this.subtitle,
    required this.title,
  });

  final IconData icon;
  final String route;
  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: ListTile(
          leading: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: colors.onPrimaryContainer),
            ),
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(route),
        ),
      ),
    );
  }
}
