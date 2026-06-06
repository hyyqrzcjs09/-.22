import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_link_vr/app/photo_link_vr_app.dart';

void main() {
  testWidgets('renders app title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PhotoLinkVrApp()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('登录'), findsOneWidget);
    expect(find.text('手机号'), findsOneWidget);
    expect(find.text('发送验证码'), findsOneWidget);
    expect(find.text('验证码'), findsNothing);
    expect(find.text('相册背景颜色'), findsNothing);
    expect(find.text('地点漫游后的展示形式'), findsNothing);

    await tester.tap(find.text('发送验证码'));
    await tester.pumpAndSettle();

    expect(find.text('验证码'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).last, '2026');
    await tester.tap(find.text('登录并分配 ID'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('地点链接'), findsOneWidget);
    expect(find.text('日期'), findsOneWidget);
    expect(find.text('地点链接 · 漫游地图'), findsOneWidget);
    expect(find.text('漫游地图'), findsOneWidget);
    expect(find.text('相册'), findsNothing);
    expect(find.text('相簿'), findsNothing);
    expect(find.text('回忆'), findsNothing);
    expect(find.text('NFC'), findsNothing);
    expect(find.text('分类'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    expect(find.textContaining('PLV-'), findsOneWidget);
    expect(find.text('地点漫游后的展示形式'), findsOneWidget);
    expect(find.text('打开调色板'), findsOneWidget);

    await tester.tap(find.text('打开调色板'));
    await tester.pumpAndSettle();

    expect(find.text('相册背景调色板'), findsOneWidget);

    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -320));
    await tester.pumpAndSettle();

    expect(find.text('本地照片权限'), findsOneWidget);
  });
}
