import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/photo_link_vr_app.dart';
import 'features/albums/application/albums_local_store.dart';
import 'features/profile/application/user_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        userSettingsStoreProvider.overrideWithValue(
          SharedPreferencesUserSettingsStore(preferences),
        ),
        albumsLocalStoreProvider.overrideWithValue(
          SharedPreferencesAlbumsLocalStore(preferences),
        ),
      ],
      child: const PhotoLinkVrApp(),
    ),
  );
}
