import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import 'photo_map_view.dart';

class PhotosScreen extends StatelessWidget {
  const PhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 1,
      title: '照片地图',
      child: const PhotoMapView(),
    );
  }
}
