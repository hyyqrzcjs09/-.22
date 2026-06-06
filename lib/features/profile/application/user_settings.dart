import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class UserSettingsController extends Notifier<UserSettings> {
  @override
  UserSettings build() {
    return const UserSettings(
      albumBackgroundColor: Color(0xFFD5D7DA),
      albumDisplayMode: AlbumDisplayMode.detail,
      timeRoamDisplayMode: TimeRoamDisplayMode.day,
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

  void setTimeRoamDisplayMode(TimeRoamDisplayMode mode) {
    state = state.copyWith(timeRoamDisplayMode: mode);
  }
}

final userSettingsProvider =
    NotifierProvider<UserSettingsController, UserSettings>(
  UserSettingsController.new,
);
