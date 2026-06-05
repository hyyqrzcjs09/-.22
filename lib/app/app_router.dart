import 'package:go_router/go_router.dart';

import '../features/albums/presentation/albums_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/nfc/presentation/nfc_screen.dart';
import '../features/photos/presentation/photos_screen.dart';
import '../features/vr/presentation/immersive_replay_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const photos = '/photos';
  static const albums = '/albums';
  static const nfc = '/nfc';
  static const replay = '/vr';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.photos,
      builder: (context, state) => const PhotosScreen(),
    ),
    GoRoute(
      path: AppRoutes.albums,
      builder: (context, state) => const AlbumsScreen(),
    ),
    GoRoute(
      path: AppRoutes.nfc,
      builder: (context, state) => const NfcScreen(),
    ),
    GoRoute(
      path: AppRoutes.replay,
      builder: (context, state) => const ImmersiveReplayScreen(),
    ),
  ],
);
