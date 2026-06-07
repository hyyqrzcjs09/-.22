import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_link_vr/features/albums/presentation/albums_screen.dart';
import 'package:photo_link_vr/features/vr/application/memory_video_store.dart';

void main() {
  testWidgets('creates a category album from the add button', (tester) async {
    MemoryVideoStore.instance.clearForTesting();

    await tester.pumpWidget(
      const MaterialApp(
        home: ProviderScope(child: AlbumsScreen()),
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

    await tester.tap(find.byTooltip('相册操作').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('AR 同场景重现'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('家庭 AR 同场景重现'), findsOneWidget);
    expect(find.text('Unity 接口预留'), findsOneWidget);
    expect(find.text('AR 图片层'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byTooltip('相册操作').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('剪辑回忆视频'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(MemoryVideoStore.instance.videos, hasLength(1));
    expect(MemoryVideoStore.instance.videos.first.albumName, '家庭');
    expect(find.text('家庭 回忆视频'), findsOneWidget);
    expect(find.byTooltip('视频速览'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('家庭'));
    await tester.pumpAndSettle();

    expect(find.text('相册评论'), findsOneWidget);
    expect(find.text('发送评论'), findsOneWidget);
    expect(find.text('2026年6月6日'), findsOneWidget);
    expect(find.text('2026年6月5日'), findsOneWidget);
    expect(find.text('家庭 照片 1'), findsOneWidget);
    expect(find.text('所有权 1 人'), findsOneWidget);
    expect(find.byTooltip('相册详情功能'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '一起补充一条评论');
    await tester.tap(find.text('发送评论'));
    await tester.pumpAndSettle();

    expect(find.textContaining('一起补充一条评论'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    final firstPhoto = find.text('家庭 照片 1').first;
    await tester.ensureVisible(firstPhoto);
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getTopLeft(firstPhoto).translate(12, -58));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byTooltip('弹幕设置'), findsOneWidget);
    await tester.tap(find.byTooltip('弹幕设置'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('开启弹幕'), findsOneWidget);
    expect(find.text('弹幕颜色'), findsOneWidget);
    expect(find.textContaining('透明度'), findsOneWidget);
    expect(find.textContaining('播放速度'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();

    expect(find.text('2026年5月28日'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 420));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('相册详情功能'));
    await tester.pumpAndSettle();

    expect(find.text('NFC 分享'), findsOneWidget);
    expect(find.text('AR 同场景重现'), findsOneWidget);
    expect(find.text('添加照片'), findsOneWidget);

    await tester.tap(find.text('添加照片'));
    await tester.pumpAndSettle();

    expect(find.text('5 张照片'), findsOneWidget);
    expect(find.text('家庭 新照片 5'), findsOneWidget);

    await tester.tap(find.byTooltip('相册详情功能'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NFC 分享'));
    await tester.pumpAndSettle();

    expect(find.text('仅用 NFC 分享该相册内容'), findsOneWidget);
    expect(find.text('变成多人相册'), findsOneWidget);

    await tester.tap(find.text('变成多人相册'));
    await tester.pumpAndSettle();

    expect(find.text('多人相册'), findsOneWidget);
    expect(find.text('所有权 2 人'), findsOneWidget);
  });

  testWidgets('enables personal tri-ring social and shares with inbox',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProviderScope(child: AlbumsScreen()),
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

    expect(find.text('每个环选择 3-10 张照片'), findsOneWidget);
    expect(find.text('等待照片输入'), findsNothing);
    expect(find.text('点击任意环查看已选照片，长按任意环添加或删除照片。'), findsOneWidget);
    expect(find.textContaining('自我环'), findsWidgets);
    expect(find.textContaining('关系环'), findsWidgets);
    expect(find.textContaining('场景环'), findsWidgets);

    Future<void> selectThreePhotos(String ringLabel) async {
      await tester.longPress(find.textContaining(ringLabel).first);
      await tester.pumpAndSettle();
      expect(find.text('编辑$ringLabel'), findsOneWidget);

      for (final title in ['家庭 照片 1', '家庭 照片 2', '家庭 照片 3']) {
        final option = find.text('家庭 · $title');
        await tester.ensureVisible(option);
        await tester.pumpAndSettle();
        await tester.tap(option);
        await tester.pumpAndSettle();
      }

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    }

    await selectThreePhotos('自我环');
    await selectThreePhotos('关系环');
    await selectThreePhotos('场景环');

    expect(find.textContaining('3/10'), findsWidgets);
    await tester.tap(find.textContaining('自我环').first);
    await tester.pumpAndSettle();
    expect(find.text('自我环照片'), findsOneWidget);
    expect(find.text('家庭 照片 1'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.textContaining('图片分析'), findsNothing);
    expect(find.textContaining('用户画像'), findsNothing);
    expect(find.text('同频匹配推荐'), findsOneWidget);

    await tester.ensureVisible(find.text('同频匹配推荐'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('加好友').first);
    await tester.pumpAndSettle();

    expect(find.text('已加好友'), findsOneWidget);
    expect(find.text('1 位好友'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.ensureVisible(find.text('好友分享'));
    await tester.pumpAndSettle();
    expect(find.text('收信'), findsOneWidget);
    expect(find.text('同频用户 A · 记忆节奏型 分享了手账漫游'), findsOneWidget);

    await tester.tap(find.text('选择好友并分享'));
    await tester.pumpAndSettle();
    expect(find.text('分享给好友'), findsOneWidget);
    expect(find.text('选择收件人'), findsOneWidget);
    await tester.tap(find.text('手账漫游'));
    await tester.tap(find.text('编辑图片'));
    await tester.enterText(find.byType(TextField).last, '分享一页今日手账');
    await tester.pumpAndSettle();
    await tester.tap(find.text('发送'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('已向好友分享图片和文字'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('分享记录'), findsOneWidget);
    expect(find.text('已分享 手账漫游 + 图片 + 文字'), findsOneWidget);
    expect(find.textContaining('发送给 同频用户 A'), findsOneWidget);

    await tester.ensureVisible(find.text('同频用户 A · 记忆节奏型 分享了手账漫游'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('同频用户 A · 记忆节奏型 分享了手账漫游'));
    await tester.pumpAndSettle();

    expect(find.text('同频用户 A · 记忆节奏型 的分享'), findsOneWidget);
    expect(find.text('回复图片或文字'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '我也想分享一张');
    await tester.tap(find.text('选择回复图片'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('回复'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('同频用户 A · 记忆节奏型 分享了手账漫游'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('同频用户 A · 记忆节奏型 分享了手账漫游'));
    await tester.pumpAndSettle();

    expect(find.text('回复记录'), findsOneWidget);
    expect(find.text('我也想分享一张'), findsOneWidget);
  });
}
