import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_link_vr/features/albums/presentation/albums_screen.dart';
import 'package:photo_link_vr/features/vr/application/memory_video_store.dart';

void main() {
  testWidgets('creates a category album from the add button', (tester) async {
    MemoryVideoStore.instance.clearForTesting();

    await tester.pumpWidget(
      const MaterialApp(
        home: AlbumsScreen(),
      ),
    );

    await tester.tap(find.byTooltip('建立文件夹').first);
    await tester.pumpAndSettle();

    expect(find.text('家庭'), findsOneWidget);
    expect(find.text('友谊'), findsOneWidget);
    expect(find.text('爱情'), findsOneWidget);
    expect(find.text('其他'), findsOneWidget);

    await tester.tap(find.text('创建'));
    await tester.pumpAndSettle();

    expect(find.text('家庭'), findsOneWidget);
    expect(find.text('4 张照片'), findsOneWidget);
    expect(find.text('还没有回忆视频'), findsNothing);

    await tester.tap(find.byTooltip('剪辑回忆视频'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(MemoryVideoStore.instance.videos, hasLength(1));
    expect(MemoryVideoStore.instance.videos.first.albumName, '家庭');
    expect(find.text('家庭 回忆视频'), findsOneWidget);
    expect(find.byTooltip('视频速览'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('家庭'));
    await tester.pumpAndSettle();

    expect(find.text('2026年6月6日'), findsOneWidget);
    expect(find.text('2026年6月5日'), findsOneWidget);
    expect(find.text('2026年5月28日'), findsOneWidget);
    expect(find.text('家庭 照片 1'), findsOneWidget);
    expect(find.byTooltip('NFC 分享'), findsOneWidget);

    await tester.tap(find.byTooltip('NFC 分享'));
    await tester.pumpAndSettle();

    expect(find.text('仅用 NFC 分享该相册内容'), findsOneWidget);
    expect(find.text('变成多人相册'), findsOneWidget);

    await tester.tap(find.text('变成多人相册'));
    await tester.pumpAndSettle();

    expect(find.text('多人相册'), findsOneWidget);
  });

  testWidgets('enables personal tri-ring social and selects photos',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AlbumsScreen(),
      ),
    );

    expect(find.text('个人三色环 social'), findsOneWidget);
    expect(find.text('关闭时保留原有比邻环功能'), findsOneWidget);

    await tester.tap(find.byTooltip('建立文件夹').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('创建'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('选择照片形成三色环'), findsOneWidget);
    expect(find.text('已选择 0/3 张照片'), findsOneWidget);

    await tester.tap(find.text('家庭 · 家庭 照片 1'));
    await tester.pumpAndSettle();

    expect(find.text('已选择 1/3 张照片'), findsOneWidget);
    expect(find.text('家庭 照片 1'), findsWidgets);
  });
}
