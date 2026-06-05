import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import 'app_router.dart';
import 'app_theme.dart';

class PhotoLinkVrApp extends StatelessWidget {
  const PhotoLinkVrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter,
    );
  }
}
