import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_link_vr/features/auth/presentation/login_screen.dart';
import 'package:photo_link_vr/features/profile/application/user_settings.dart';

void main() {
  testWidgets('login assigns a user id and stores album preferences',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('已登录')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    expect(find.text('账号登录'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -520));
    await tester.pumpAndSettle();

    expect(find.text('地点漫游后的展示形式'), findsOneWidget);
    await tester.tap(find.text('相簿'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(LoginScreen));
    final container = ProviderScope.containerOf(context);

    expect(
      container.read(userSettingsProvider).albumDisplayMode,
      AlbumDisplayMode.stack,
    );

    await tester.tap(find.text('登录并分配 ID'));
    await tester.pumpAndSettle();

    final settings = container.read(userSettingsProvider);
    expect(settings.userId, startsWith('PLV-'));
    expect(settings.phoneNumber, '13800000000');
  });
}
