import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_link_vr/features/photos/presentation/photos_screen.dart';

void main() {
  testWidgets('connects date browsing modes inside the dates tab',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PhotosScreen(),
      ),
    );

    expect(find.text('时间'), findsOneWidget);
    expect(find.text('堆叠'), findsOneWidget);
    expect(find.text('日历'), findsOneWidget);
    expect(find.text('杂志'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);

    await tester.tap(find.text('日历'));
    await tester.pumpAndSettle();

    expect(find.text('June 2025'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);
    expect(find.text('Sat'), findsOneWidget);

    await tester.tap(find.text('杂志'));
    await tester.pumpAndSettle();

    expect(find.text('2023'), findsWidgets);
    expect(find.byTooltip('添加日期杂志'), findsOneWidget);
  });
}
