import 'package:go_router/go_router.dart';

import '../features/albums/presentation/albums_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/photos/presentation/photos_screen.dart';
import '../features/profile/presentation/profile_screen.dart';

abstract final class AppRoutes {
  static const placeLinks = '/';
  static const dates = '/dates';
  static const categories = '/categories';
  static const profile = '/profile';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.placeLinks,
  routes: [
    GoRoute(
      path: AppRoutes.placeLinks,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.dates,
      builder: (context, state) => const PhotosScreen(),
    ),
    GoRoute(
      path: AppRoutes.categories,
      builder: (context, state) => const AlbumsScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
