import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_link_vr/app/photo_link_vr_app.dart';

void main() {
  testWidgets('renders app title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PhotoLinkVrApp()));
    await tester.pumpAndSettle();

    expect(find.text('PhotoLink VR'), findsOneWidget);
    expect(find.text('把照片连接到真实地点'), findsOneWidget);
  });
}
