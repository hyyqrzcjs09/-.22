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

    expect(find.text('登录'), findsOneWidget);
    expect(find.text('手机号'), findsOneWidget);
    expect(find.text('发送验证码'), findsOneWidget);
    expect(find.text('相册背景颜色'), findsNothing);
    expect(find.text('地点漫游后的展示形式'), findsNothing);

    await tester.tap(find.text('发送验证码'));
    await tester.pumpAndSettle();

    expect(find.text('验证码'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, '2026');

    final context = tester.element(find.byType(LoginScreen));
    final container = ProviderScope.containerOf(context);

    expect(
      container.read(userSettingsProvider).albumDisplayMode,
      AlbumDisplayMode.detail,
    );

    await tester.tap(find.text('登陆成功'));
    await tester.pumpAndSettle();

    final settings = container.read(userSettingsProvider);
    expect(settings.userId, startsWith('PLV-'));
    expect(settings.phoneNumber, '13800000000');
  });
}
