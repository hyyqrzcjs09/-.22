import 'package:flutter/material.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../photos/presentation/photo_map_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 0,
      title: '地点链接',
      showAppBar: false,
      child: const PhotoMapView(showStatusPanel: false),
    );
  }
}
