import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AlbumDisplayMode {
  detail,
  stack,
}

enum TimeRoamDisplayMode {
  year,
  month,
  day,
}

extension AlbumDisplayModeText on AlbumDisplayMode {
  String get label {
    return switch (this) {
      AlbumDisplayMode.detail => '相册',
      AlbumDisplayMode.stack => '相簿',
    };
  }
}

extension TimeRoamDisplayModeText on TimeRoamDisplayMode {
  String get label {
    return switch (this) {
      TimeRoamDisplayMode.year => '年',
      TimeRoamDisplayMode.month => '月',
      TimeRoamDisplayMode.day => '日',
    };
  }
}

class UserSettings {
  const UserSettings({
    required this.albumBackgroundColor,
    required this.albumDisplayMode,
    required this.timeRoamDisplayMode,
    this.phoneNumber,
    this.userId,
  });

  final Color albumBackgroundColor;
  final AlbumDisplayMode albumDisplayMode;
  final String? phoneNumber;
  final TimeRoamDisplayMode timeRoamDisplayMode;
  final String? userId;

  static const defaults = UserSettings(
    albumBackgroundColor: Color(0xFFD5D7DA),
    albumDisplayMode: AlbumDisplayMode.detail,
    timeRoamDisplayMode: TimeRoamDisplayMode.day,
  );

  bool get isLoggedIn => userId != null;

  UserSettings copyWith({
    Color? albumBackgroundColor,
    AlbumDisplayMode? albumDisplayMode,
    String? phoneNumber,
    TimeRoamDisplayMode? timeRoamDisplayMode,
    String? userId,
  }) {
    return UserSettings(
      albumBackgroundColor: albumBackgroundColor ?? this.albumBackgroundColor,
      albumDisplayMode: albumDisplayMode ?? this.albumDisplayMode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      timeRoamDisplayMode: timeRoamDisplayMode ?? this.timeRoamDisplayMode,
      userId: userId ?? this.userId,
    );
  }
}

abstract interface class UserSettingsStore {
  UserSettings read();

  void write(UserSettings settings);
}

class MemoryUserSettingsStore implements UserSettingsStore {
  UserSettings _settings = UserSettings.defaults;

  @override
  UserSettings read() => _settings;

  @override
  void write(UserSettings settings) {
    _settings = settings;
  }
}

class SharedPreferencesUserSettingsStore implements UserSettingsStore {
  const SharedPreferencesUserSettingsStore(this._preferences);

  final SharedPreferences _preferences;

  static const _albumBackgroundColorKey = 'user.albumBackgroundColor';
  static const _albumDisplayModeKey = 'user.albumDisplayMode';
  static const _phoneNumberKey = 'user.phoneNumber';
  static const _timeRoamDisplayModeKey = 'user.timeRoamDisplayMode';
  static const _userIdKey = 'user.userId';

  @override
  UserSettings read() {
    return UserSettings(
      albumBackgroundColor: Color(
        _preferences.getInt(_albumBackgroundColorKey) ??
            UserSettings.defaults.albumBackgroundColor.toARGB32(),
      ),
      albumDisplayMode: _readAlbumDisplayMode(
        _preferences.getString(_albumDisplayModeKey),
      ),
      phoneNumber: _preferences.getString(_phoneNumberKey),
      timeRoamDisplayMode: _readTimeRoamDisplayMode(
        _preferences.getString(_timeRoamDisplayModeKey),
      ),
      userId: _preferences.getString(_userIdKey),
    );
  }

  @override
  void write(UserSettings settings) {
    unawaited(
      _preferences.setInt(
        _albumBackgroundColorKey,
        settings.albumBackgroundColor.toARGB32(),
      ),
    );
    unawaited(_preferences.setString(
      _albumDisplayModeKey,
      settings.albumDisplayMode.name,
    ));
    unawaited(_preferences.setString(
      _timeRoamDisplayModeKey,
      settings.timeRoamDisplayMode.name,
    ));

    final phoneNumber = settings.phoneNumber;
    if (phoneNumber == null) {
      unawaited(_preferences.remove(_phoneNumberKey));
    } else {
      unawaited(_preferences.setString(_phoneNumberKey, phoneNumber));
    }

    final userId = settings.userId;
    if (userId == null) {
      unawaited(_preferences.remove(_userIdKey));
    } else {
      unawaited(_preferences.setString(_userIdKey, userId));
    }
  }

  static AlbumDisplayMode _readAlbumDisplayMode(String? name) {
    return AlbumDisplayMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => UserSettings.defaults.albumDisplayMode,
    );
  }

  static TimeRoamDisplayMode _readTimeRoamDisplayMode(String? name) {
    return TimeRoamDisplayMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => UserSettings.defaults.timeRoamDisplayMode,
    );
  }
}

final userSettingsStoreProvider = Provider<UserSettingsStore>((ref) {
  return MemoryUserSettingsStore();
});

class UserSettingsController extends Notifier<UserSettings> {
  @override
  UserSettings build() {
    return ref.watch(userSettingsStoreProvider).read();
  }

  void loginWithPhone({
    required String code,
    required String phoneNumber,
  }) {
    final cleanPhone = phoneNumber.trim();
    final suffix = cleanPhone.length >= 4
        ? cleanPhone.substring(cleanPhone.length - 4)
        : cleanPhone.padLeft(4, '0');
    final random = Random(cleanPhone.hashCode + code.hashCode).nextInt(9000);
    final existingUserId =
        state.phoneNumber == cleanPhone ? state.userId : null;

    state = state.copyWith(
      phoneNumber: cleanPhone,
      userId: existingUserId ?? 'PLV-$suffix-${1000 + random}',
    );
    _persist();
  }

  void setAlbumBackgroundColor(Color color) {
    state = state.copyWith(albumBackgroundColor: color);
    _persist();
  }

  void setAlbumDisplayMode(AlbumDisplayMode mode) {
    state = state.copyWith(albumDisplayMode: mode);
    _persist();
  }

  void setTimeRoamDisplayMode(TimeRoamDisplayMode mode) {
    state = state.copyWith(timeRoamDisplayMode: mode);
    _persist();
  }

  void _persist() {
    ref.read(userSettingsStoreProvider).write(state);
  }
}

final userSettingsProvider =
    NotifierProvider<UserSettingsController, UserSettings>(
  UserSettingsController.new,
);
