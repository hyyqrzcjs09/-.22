import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_link_vr/features/albums/presentation/albums_screen.dart';

void main() {
  testWidgets('creates a category album from the add button', (tester) async {
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
    expect(find.text('0 张照片'), findsOneWidget);
  });
}
