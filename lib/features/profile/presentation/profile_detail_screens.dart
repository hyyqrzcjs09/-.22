import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../vr/presentation/immersive_replay_screen.dart';

class PhotoPermissionDetailScreen extends StatefulWidget {
  const PhotoPermissionDetailScreen({super.key});

  @override
  State<PhotoPermissionDetailScreen> createState() =>
      _PhotoPermissionDetailScreenState();
}

class _PhotoPermissionDetailScreenState
    extends State<PhotoPermissionDetailScreen> {
  var _autoScan = true;
  var _scanLocation = true;
  var _onlyNewPhotos = true;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 2,
      title: '本地照片权限',
      child: _DetailList(
        children: [
          _HeroPanel(
            icon: Icons.photo_library_outlined,
            title: '本地照片访问',
            subtitle: '用于读取本地相册、解析拍摄时间和定位照片坐标。',
            metrics: const [
              _DetailMetric(label: '权限状态', value: '待确认'),
              _DetailMetric(label: '扫描范围', value: '照片+位置'),
              _DetailMetric(label: '同步方式', value: '本地索引'),
            ],
          ),
          _DetailSection(
            title: '权限内容',
            children: const [
              _InfoRow(
                icon: Icons.collections_bookmark_outlined,
                title: '读取本地相册',
                subtitle: '获取照片缩略图、创建时间、文件类型和相册来源。',
              ),
              _InfoRow(
                icon: Icons.location_on_outlined,
                title: '读取照片位置',
                subtitle: '从 EXIF 中提取经纬度，用于地点漫游地图标点和区域聚合。',
              ),
              _InfoRow(
                icon: Icons.calendar_month_outlined,
                title: '同步日期索引',
                subtitle: '按年、月、日建立照片时间线，支持日期页面快速回看。',
              ),
              _InfoRow(
                icon: Icons.lock_outline,
                title: '隐私保护',
                subtitle: '默认只保存本地索引和必要元数据，原图不上传到后端。',
              ),
            ],
          ),
          _WhitePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PanelTitle(title: '扫描策略'),
                _ToggleRow(
                  icon: Icons.autorenew,
                  title: '进入 App 后自动检查新照片',
                  value: _autoScan,
                  onChanged: (value) => setState(() => _autoScan = value),
                ),
                _ToggleRow(
                  icon: Icons.travel_explore,
                  title: '扫描照片中的位置坐标',
                  value: _scanLocation,
                  onChanged: (value) => setState(() => _scanLocation = value),
                ),
                _ToggleRow(
                  icon: Icons.new_releases_outlined,
                  title: '仅扫描上次之后新增照片',
                  value: _onlyNewPhotos,
                  onChanged: (value) => setState(() => _onlyNewPhotos = value),
                ),
              ],
            ),
          ),
          _ActionPanel(
            actions: [
              _DetailAction(
                icon: Icons.verified_user_outlined,
                label: '申请照片权限',
                onPressed: () => _showMessage(context, '已准备调用系统照片权限申请'),
              ),
              _DetailAction(
                icon: Icons.manage_search,
                label: '立即扫描相册',
                onPressed: () => _showMessage(context, '已加入本地相册扫描任务'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NfcShareRecordsDetailScreen extends StatelessWidget {
  const NfcShareRecordsDetailScreen({super.key});

  static const _records = [
    _NfcRecord(
      album: '家庭',
      mode: '仅分享内容',
      target: 'NFC 标签 A-102',
      time: '2026/6/6 14:20',
      status: '可访问',
      icon: Icons.family_restroom_outlined,
    ),
    _NfcRecord(
      album: '友谊',
      mode: '多人相册入口',
      target: 'NFC 标签 B-214',
      time: '2026/6/5 19:08',
      status: '2 人',
      icon: Icons.groups_outlined,
    ),
    _NfcRecord(
      album: '旅行',
      mode: '回忆视频入口',
      target: 'NFC 标签 C-018',
      time: '2026/5/28 10:36',
      status: '已绑定',
      icon: Icons.explore_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 2,
      title: 'NFC 分享记录',
      child: _DetailList(
        children: [
          _HeroPanel(
            icon: Icons.nfc_outlined,
            title: 'NFC 相册入口',
            subtitle: '集中管理已写入 NFC 的相册、多人相册和回忆视频入口。',
            metrics: const [
              _DetailMetric(label: '已绑定', value: '3 个'),
              _DetailMetric(label: '多人入口', value: '1 个'),
              _DetailMetric(label: '最近写入', value: '今天'),
            ],
          ),
          _DetailSection(
            title: '分享类型',
            children: const [
              _InfoRow(
                icon: Icons.share_outlined,
                title: '仅分享相册内容',
                subtitle: '被分享者只能查看该相册照片和对应地点/日期信息。',
              ),
              _InfoRow(
                icon: Icons.group_add_outlined,
                title: '变成多人相册',
                subtitle: '被分享者加入后可以一起维护照片、NFC 入口和回忆视频。',
              ),
              _InfoRow(
                icon: Icons.movie_creation_outlined,
                title: '回忆视频入口',
                subtitle: '标签可直达相册生成的流畅过渡视频速览。',
              ),
            ],
          ),
          _WhitePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PanelTitle(title: '已绑定记录'),
                const SizedBox(height: 10),
                for (final record in _records) ...[
                  _NfcRecordTile(record: record),
                  if (record != _records.last)
                    const Divider(height: 18, thickness: 0.8),
                ],
              ],
            ),
          ),
          _ActionPanel(
            actions: [
              _DetailAction(
                icon: Icons.add_link,
                label: '写入新标签',
                onPressed: () => _showMessage(context, '已打开 NFC 写入流程'),
              ),
              _DetailAction(
                icon: Icons.cleaning_services_outlined,
                label: '清理失效入口',
                onPressed: () => _showMessage(context, '已检查失效 NFC 入口'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VrMemorySettingsDetailScreen extends StatefulWidget {
  const VrMemorySettingsDetailScreen({super.key});

  @override
  State<VrMemorySettingsDetailScreen> createState() =>
      _VrMemorySettingsDetailScreenState();
}

class _VrMemorySettingsDetailScreenState
    extends State<VrMemorySettingsDetailScreen> {
  var _quality = '1080p';
  var _transition = '淡入';
  var _duration = 0.65;
  var _smoothMotion = true;
  var _autoPreview = true;
  var _spatialAudio = false;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 2,
      title: 'VR 回忆设置',
      child: _DetailList(
        children: [
          _HeroPanel(
            icon: Icons.view_in_ar_outlined,
            title: '回忆视频偏好',
            subtitle: '管理相册转视频时的画面质量、过渡节奏和播放方式。',
            metrics: [
              _DetailMetric(label: '画质', value: _quality),
              _DetailMetric(
                label: '过渡',
                value: '${(_duration * 1000).round()} ms',
              ),
              _DetailMetric(label: '速览', value: _autoPreview ? '开启' : '关闭'),
            ],
          ),
          _WhitePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PanelTitle(title: '视频生成'),
                const SizedBox(height: 10),
                Text(
                  '输出画质',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '720p', label: Text('720p')),
                    ButtonSegment(value: '1080p', label: Text('1080p')),
                    ButtonSegment(value: '4K', label: Text('4K')),
                  ],
                  selected: {_quality},
                  onSelectionChanged: (selected) {
                    setState(() => _quality = selected.first);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  '过渡方式',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '淡入', label: Text('淡入')),
                    ButtonSegment(value: '推移', label: Text('推移')),
                    ButtonSegment(value: '景深', label: Text('景深')),
                  ],
                  selected: {_transition},
                  onSelectionChanged: (selected) {
                    setState(() => _transition = selected.first);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '过渡时长',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Text('${(_duration * 1000).round()} ms'),
                  ],
                ),
                Slider(
                  min: 0.35,
                  max: 1.2,
                  divisions: 17,
                  value: _duration,
                  onChanged: (value) => setState(() => _duration = value),
                ),
              ],
            ),
          ),
          _WhitePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PanelTitle(title: '播放偏好'),
                _ToggleRow(
                  icon: Icons.auto_fix_high,
                  title: '启用流畅动效补帧',
                  value: _smoothMotion,
                  onChanged: (value) => setState(() => _smoothMotion = value),
                ),
                _ToggleRow(
                  icon: Icons.play_circle_outline,
                  title: '点击回忆后自动播放速览',
                  value: _autoPreview,
                  onChanged: (value) => setState(() => _autoPreview = value),
                ),
                _ToggleRow(
                  icon: Icons.spatial_audio_off_outlined,
                  title: '预留空间音频接口',
                  value: _spatialAudio,
                  onChanged: (value) => setState(() => _spatialAudio = value),
                ),
              ],
            ),
          ),
          const MemoryVideoSection(
            emptyMessage: '在比邻环相册右上角点击回忆视频后，这里会显示已生成的视频速览。',
          ),
          _ActionPanel(
            actions: [
              _DetailAction(
                icon: Icons.movie_filter_outlined,
                label: '生成测试预览',
                onPressed: () => _showMessage(context, '已按当前偏好生成测试预览'),
              ),
              _DetailAction(
                icon: Icons.tune,
                label: '保存播放偏好',
                onPressed: () => _showMessage(context, 'VR 回忆设置已保存'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailList extends StatelessWidget {
  const _DetailList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemBuilder: (context, index) => children[index],
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemCount: children.length,
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.icon,
    required this.metrics,
    required this.subtitle,
    required this.title,
  });

  final IconData icon;
  final List<_DetailMetric> metrics;
  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _WhitePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, color: colors.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final metric in metrics) _MetricPill(metric: metric),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.children,
    required this.title,
  });

  final List<Widget> children;
  final String title;

  @override
  Widget build(BuildContext context) {
    return _WhitePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(title: title),
          const SizedBox(height: 10),
          for (final child in children) child,
        ],
      ),
    );
  }
}

class _WhitePanel extends StatelessWidget {
  const _WhitePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            color: Color(0x10000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary, size: 22),
          const SizedBox(width: 12),
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.onChanged,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final ValueChanged<bool> onChanged;
  final String title;
  final bool value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: colors.primary),
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.actions});

  final List<_DetailAction> actions;

  @override
  Widget build(BuildContext context) {
    return _WhitePanel(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final action in actions)
            FilledButton.icon(
              onPressed: action.onPressed,
              icon: Icon(action.icon),
              label: Text(action.label),
            ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.metric});

  final _DetailMetric metric;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              metric.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 8),
            Text(
              metric.value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NfcRecordTile extends StatelessWidget {
  const _NfcRecordTile({required this.record});

  final _NfcRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(record.icon, color: colors.onPrimaryContainer),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.album,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                '${record.mode} · ${record.target}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(record.time, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              record.status,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailMetric {
  const _DetailMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _DetailAction {
  const _DetailAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}

class _NfcRecord {
  const _NfcRecord({
    required this.album,
    required this.icon,
    required this.mode,
    required this.status,
    required this.target,
    required this.time,
  });

  final String album;
  final IconData icon;
  final String mode;
  final String status;
  final String target;
  final String time;
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
