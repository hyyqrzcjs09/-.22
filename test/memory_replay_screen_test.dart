import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_link_vr/features/vr/application/memory_video_store.dart';
import 'package:photo_link_vr/features/vr/presentation/immersive_replay_screen.dart';

void main() {
  testWidgets('plays a generated memory video preview', (tester) async {
    MemoryVideoStore.instance
      ..clearForTesting()
      ..addFromAlbum(
        albumName: '家庭',
        clips: [
          MemoryClip(date: DateTime(2026, 6, 6), title: '家庭 照片 1'),
          MemoryClip(date: DateTime(2026, 6, 5), title: '家庭 照片 2'),
        ],
      );

    final video = MemoryVideoStore.instance.videos.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MemoryVideoPlayer(video: video),
            ),
          ),
        ),
      ),
    );

    expect(find.text('家庭 回忆视频'), findsOneWidget);
    expect(find.text('2 个片段 / 8 秒'), findsOneWidget);
    expect(find.byTooltip('视频速览'), findsOneWidget);
  });
}
