import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_link_vr/features/albums/application/albums_local_store.dart';
import 'package:photo_link_vr/features/profile/application/user_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('shared preferences keeps user choices across store instances',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesUserSettingsStore(preferences);

    store.write(
      UserSettings.defaults.copyWith(
        albumBackgroundColor: const Color(0xFF121212),
        albumDisplayMode: AlbumDisplayMode.stack,
        avatarImageBase64: 'avatar-data',
        nickname: 'Encounter 用户',
        phoneNumber: '13800000000',
        timeRoamDisplayMode: TimeRoamDisplayMode.month,
        userId: 'PLV-0000-1298',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final restored = SharedPreferencesUserSettingsStore(preferences).read();

    expect(restored.albumBackgroundColor.toARGB32(), 0xFF121212);
    expect(restored.albumDisplayMode, AlbumDisplayMode.stack);
    expect(restored.avatarImageBase64, 'avatar-data');
    expect(restored.nickname, 'Encounter 用户');
    expect(restored.phoneNumber, '13800000000');
    expect(restored.timeRoamDisplayMode, TimeRoamDisplayMode.month);
    expect(restored.userId, 'PLV-0000-1298');
  });

  test('shared preferences keeps album local state', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesAlbumsLocalStore(preferences);

    store.write({
      'socialEnabled': true,
      'selectedPhotoIds': {
        'self': ['photo-1', 'photo-2'],
      },
      'shareRecords': [
        {
          'text': 'hello',
          'recipients': ['friend-a'],
        },
      ],
    });
    await Future<void>.delayed(Duration.zero);

    final restored = SharedPreferencesAlbumsLocalStore(preferences).read();

    expect(restored['socialEnabled'], isTrue);
    expect(
      restored['selectedPhotoIds'],
      isA<Map>()
          .having((value) => value['self'], 'self', ['photo-1', 'photo-2']),
    );
    expect(restored['shareRecords'],
        isA<List>().having((value) => value.length, 'length', 1));
  });
}
