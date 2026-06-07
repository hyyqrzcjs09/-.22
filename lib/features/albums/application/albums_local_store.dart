import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class AlbumsLocalStore {
  Map<String, Object?> read();

  void write(Map<String, Object?> data);
}

class MemoryAlbumsLocalStore implements AlbumsLocalStore {
  Map<String, Object?> _data = const {};

  @override
  Map<String, Object?> read() => Map<String, Object?>.from(_data);

  @override
  void write(Map<String, Object?> data) {
    _data = Map<String, Object?>.from(data);
  }
}

class SharedPreferencesAlbumsLocalStore implements AlbumsLocalStore {
  const SharedPreferencesAlbumsLocalStore(this._preferences);

  final SharedPreferences _preferences;

  static const _key = 'albums.localState.v1';

  @override
  Map<String, Object?> read() {
    final value = _preferences.getString(_key);
    if (value == null || value.isEmpty) {
      return const {};
    }

    final decoded = jsonDecode(value);
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, Object?>();
    }
    return const {};
  }

  @override
  void write(Map<String, Object?> data) {
    _preferences.setString(_key, jsonEncode(data));
  }
}

final albumsLocalStoreProvider = Provider<AlbumsLocalStore>((ref) {
  return MemoryAlbumsLocalStore();
});
