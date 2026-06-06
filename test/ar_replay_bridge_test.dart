import 'package:flutter_test/flutter_test.dart';
import 'package:photo_link_vr/features/ar/application/ar_replay_bridge.dart';

void main() {
  test('local AR replay bridge creates a Unity-ready replay plan', () async {
    final bridge = LocalArReplayBridge();

    final plan = await bridge.createReplay(
      ArReplayRequest(
        albumId: 'album-family',
        albumName: '家庭',
        sceneAnchor: const ArSceneAnchor(
          label: '家庭',
          sceneSignature: 'scene-family',
        ),
        photos: [
          ArReplayPhoto(
            createdAt: DateTime(2026, 6, 6),
            id: 'photo-1',
            title: '家庭 照片 1',
          ),
          ArReplayPhoto(
            createdAt: DateTime(2026, 6, 5),
            id: 'photo-2',
            title: '家庭 照片 2',
          ),
        ],
      ),
    );

    expect(plan.sceneMatched, isTrue);
    expect(plan.overlays, hasLength(2));
    expect(plan.unityPayload['bridge'], UnityArReplayBridge.channelName);
    expect(plan.unityPayload['method'], UnityArReplayBridge.createReplayMethod);
  });
}
