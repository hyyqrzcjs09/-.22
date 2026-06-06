import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/albums/presentation/albums_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/photos/presentation/photos_screen.dart';
import '../features/profile/application/user_settings.dart';
import '../features/profile/presentation/profile_detail_screens.dart';
import '../features/profile/presentation/profile_screen.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const placeLinks = '/';
  static const dates = '/dates';
  static const categories = '/categories';
  static const profile = '/profile';
  static const profileAlbumDisplayMode = '/profile/album-display-mode';
  static const profilePhotoPermissions = '/profile/photo-permissions';
  static const profileNfcShares = '/profile/nfc-shares';
  static const profileArMemories = '/profile/ar-memories';
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
      GoRoute(
        path: AppRoutes.profileAlbumDisplayMode,
        builder: (context, state) => const AlbumDisplayModeDetailScreen(),
      ),
      GoRoute(
        path: AppRoutes.profilePhotoPermissions,
        builder: (context, state) => const PhotoPermissionDetailScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileNfcShares,
        builder: (context, state) => const NfcShareRecordsDetailScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileArMemories,
        builder: (context, state) => const ArMemorySettingsDetailScreen(),
      ),
    ],
  );
});
