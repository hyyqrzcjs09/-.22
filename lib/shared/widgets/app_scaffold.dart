import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_router.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.child,
    required this.selectedIndex,
    required this.title,
    this.showAppBar = true,
    super.key,
  });

  final Widget child;
  final int selectedIndex;
  final bool showAppBar;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(title)) : null,
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.placeLinks);
            case 1:
              context.go(AppRoutes.dates);
            case 2:
              context.go(AppRoutes.memories);
            case 3:
              context.go(AppRoutes.categories);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.add_location_alt_outlined),
            selectedIcon: Icon(Icons.add_location_alt),
            label: '地点链接',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '日期',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_motion_outlined),
            selectedIcon: Icon(Icons.auto_awesome_motion),
            label: '回忆',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: '分类',
          ),
        ],
      ),
    );
  }
}
