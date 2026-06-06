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
              context.go(AppRoutes.categories);
            case 2:
              context.go(AppRoutes.profile);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.all_inclusive),
            selectedIcon: Icon(Icons.all_inclusive),
            label: '时空环',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: '比邻环',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
