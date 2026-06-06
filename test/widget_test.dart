import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_link_vr/app/photo_link_vr_app.dart';

void main() {
  testWidgets('renders app title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PhotoLinkVrApp()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('MAPBOX_ACCESS_TOKEN'), findsOneWidget);
    expect(find.text('地点链接'), findsOneWidget);
    expect(find.text('日期'), findsOneWidget);
    expect(find.text('回忆'), findsOneWidget);
    expect(find.text('NFC'), findsOneWidget);
    expect(find.text('分类'), findsOneWidget);
  });
}
