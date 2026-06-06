import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/albums/presentation/albums_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/photos/presentation/photos_screen.dart';
import '../features/profile/application/user_settings.dart';
import '../features/profile/presentation/profile_screen.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const placeLinks = '/';
  static const dates = '/dates';
  static const categories = '/categories';
  static const profile = '/profile';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final settings = ref.watch(userSettingsProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == AppRoutes.login;
      if (!settings.isLoggedIn && !loggingIn) {
        return AppRoutes.login;
      }
      if (settings.isLoggedIn && loggingIn) {
        return AppRoutes.placeLinks;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
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
});
