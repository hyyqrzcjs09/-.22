import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_link_vr/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('connects place map, album and stack views', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Edinburgh · 8 张照片'), findsOneWidget);
    expect(find.text('漫游地图'), findsOneWidget);
    expect(find.text('相册'), findsOneWidget);
    expect(find.text('相簿'), findsOneWidget);

    await tester.tap(find.text('相册'));
    await tester.pumpAndSettle();

    expect(find.text('Edinburgh'), findsOneWidget);
    expect(find.text('8 / 8'), findsOneWidget);
    expect(find.text('50.7192, -1.8808'), findsOneWidget);

    await tester.tap(find.text('相簿'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('地点详情'), findsOneWidget);
  });
}
