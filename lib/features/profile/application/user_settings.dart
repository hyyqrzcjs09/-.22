import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AlbumDisplayMode {
  detail,
  stack,
}

extension AlbumDisplayModeText on AlbumDisplayMode {
  String get label {
    return switch (this) {
      AlbumDisplayMode.detail => '相册',
      AlbumDisplayMode.stack => '相簿',
    };
  }
}

class UserSettings {
  const UserSettings({
    required this.albumBackgroundColor,
    required this.albumDisplayMode,
    this.phoneNumber,
    this.userId,
  });

  final Color albumBackgroundColor;
  final AlbumDisplayMode albumDisplayMode;
  final String? phoneNumber;
  final String? userId;

  bool get isLoggedIn => userId != null;

  UserSettings copyWith({
    Color? albumBackgroundColor,
    AlbumDisplayMode? albumDisplayMode,
    String? phoneNumber,
    String? userId,
  }) {
    return UserSettings(
      albumBackgroundColor: albumBackgroundColor ?? this.albumBackgroundColor,
      albumDisplayMode: albumDisplayMode ?? this.albumDisplayMode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userId: userId ?? this.userId,
    );
  }
}

class UserSettingsController extends Notifier<UserSettings> {
  @override
  UserSettings build() {
    return const UserSettings(
      albumBackgroundColor: Color(0xFFD5D7DA),
      albumDisplayMode: AlbumDisplayMode.detail,
    );
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

    state = state.copyWith(
      phoneNumber: cleanPhone,
      userId: 'PLV-$suffix-${1000 + random}',
    );
  }

  void setAlbumBackgroundColor(Color color) {
    state = state.copyWith(albumBackgroundColor: color);
  }

  void setAlbumDisplayMode(AlbumDisplayMode mode) {
    state = state.copyWith(albumDisplayMode: mode);
  }
}

final userSettingsProvider =
    NotifierProvider<UserSettingsController, UserSettings>(
  UserSettingsController.new,
);
