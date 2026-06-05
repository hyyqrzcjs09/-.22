import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const ProviderScope(child: PhotoLinkVrApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/photos',
      builder: (context, state) => const PhotosScreen(),
    ),
    GoRoute(
      path: '/albums',
      builder: (context, state) => const AlbumsScreen(),
    ),
    GoRoute(
      path: '/nfc',
      builder: (context, state) => const NfcScreen(),
    ),
    GoRoute(
      path: '/vr',
      builder: (context, state) => const ImmersiveReplayScreen(),
    ),
  ],
);

class PhotoLinkVrApp extends StatelessWidget {
  const PhotoLinkVrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PhotoLink VR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A8C87),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

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
          _ActionTile(
            title: '导入照片',
            subtitle: '拍照或从相册选择照片，开始建立你的记忆库。',
            icon: Icons.add_photo_alternate_outlined,
            onTap: () => context.go('/photos'),
          ),
          _ActionTile(
            title: '创建相册',
            subtitle: '按地区、时间或种类整理照片。',
            icon: Icons.photo_library_outlined,
            onTap: () => context.go('/albums'),
          ),
          _ActionTile(
            title: '绑定 NFC',
            subtitle: '把实体标签连接到照片、相册或回放内容。',
            icon: Icons.nfc_outlined,
            onTap: () => context.go('/nfc'),
          ),
          _ActionTile(
            title: '沉浸式回放',
            subtitle: '用照片集合生成可重看的场景体验。',
            icon: Icons.view_in_ar_outlined,
            onTap: () => context.go('/vr'),
          ),
        ],
      ),
    );
  }
}

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
          _SectionHeader(title: '分类入口'),
          _CategoryChipRow(),
          SizedBox(height: 16),
          _PlaceholderPanel(
            icon: Icons.photo_outlined,
            title: '还没有照片',
            subtitle: '下一步接入 image_picker 和 photo_manager，实现拍照、导入、上传和 EXIF 信息读取。',
          ),
        ],
      ),
    );
  }
}

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
          _PlaceholderPanel(
            icon: Icons.collections_bookmark_outlined,
            title: '创建第一个相册',
            subtitle: '相册会作为 NFC 绑定和沉浸式回放的核心内容单元。',
          ),
        ],
      ),
    );
  }
}

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
          _PlaceholderPanel(
            icon: Icons.nfc_outlined,
            title: '读取或写入 NFC',
            subtitle: 'MVP 中 NFC 标签只写入内容 URL，由后端解析到照片、相册或回放页面。',
          ),
        ],
      ),
    );
  }
}

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
          _PlaceholderPanel(
            icon: Icons.play_circle_outline,
            title: '照片回放体验',
            subtitle: '第一版先实现照片全屏播放、自动转场、暂停继续和横屏模式。',
          ),
        ],
      ),
    );
  }
}

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.child,
    required this.selectedIndex,
    required this.title,
    super.key,
  });

  final Widget child;
  final int selectedIndex;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/photos');
              break;
            case 2:
              context.go('/albums');
              break;
            case 3:
              context.go('/nfc');
              break;
            case 4:
              context.go('/vr');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_outlined),
            selectedIcon: Icon(Icons.photo),
            label: '照片',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_outlined),
            selectedIcon: Icon(Icons.collections),
            label: '相册',
          ),
          NavigationDestination(
            icon: Icon(Icons.nfc_outlined),
            selectedIcon: Icon(Icons.nfc),
            label: 'NFC',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_in_ar_outlined),
            selectedIcon: Icon(Icons.view_in_ar),
            label: '回放',
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
          Icon(Icons.photo_camera_back_outlined, color: colors.onPrimaryContainer),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.onTap,
    required this.subtitle,
    required this.title,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _CategoryChipRow extends StatelessWidget {
  const _CategoryChipRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilterChip(label: Text('按时间'), onSelected: null),
          FilterChip(label: Text('按地区'), onSelected: null),
          FilterChip(label: Text('按种类'), onSelected: null),
        ],
      ),
    );
  }
}

class _PlaceholderPanel extends StatelessWidget {
  const _PlaceholderPanel({
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: colors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
