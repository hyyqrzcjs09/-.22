import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../shared/widgets/album_color_picker.dart';
import '../../../shared/widgets/album_display_mode_selector.dart';
import '../../profile/application/user_settings.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _codeController = TextEditingController(text: '2026');
  final _phoneController = TextEditingController(text: '13800000000');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(userSettingsProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              settings.albumBackgroundColor.withValues(alpha: 0.95),
              colors.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(22),
                children: [
                  Text(
                    '登录',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '使用手机号验证码登录，系统会自动分配 PhotoLink ID。',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 22),
                  _LoginPanel(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: '手机号',
                              prefixIcon: Icon(Icons.phone_iphone),
                              border: OutlineInputBorder(),
                            ),
                            validator: _validatePhone,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '验证码',
                              prefixIcon: const Icon(Icons.sms_outlined),
                              border: const OutlineInputBorder(),
                              suffixIcon: TextButton(
                                onPressed: _sendCode,
                                child: const Text('获取'),
                              ),
                            ),
                            validator: _validateCode,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _login,
                              icon: const Icon(Icons.login),
                              label: const Text('登录并分配 ID'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LoginPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '相册背景颜色',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '可自由设计相册背景色，地点漫游后的页面会同步使用该颜色。',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        AlbumColorPicker(
                          selected: settings.albumBackgroundColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LoginPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '地点漫游后的展示形式',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '点击地图地点后，仅展示你选择的相册或相簿形式。',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        AlbumDisplayModeSelector(
                          selected: settings.albumDisplayMode,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (!RegExp(r'^1\d{10}$').hasMatch(phone)) {
      return '请输入 11 位手机号';
    }
    return null;
  }

  String? _validateCode(String? value) {
    final code = value?.trim() ?? '';
    if (code.length < 4) {
      return '请输入验证码';
    }
    return null;
  }

  void _sendCode() {
    if (_validatePhone(_phoneController.text) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入正确的手机号')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('验证码已发送（演示模式）')),
    );
  }

  void _login() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    ref.read(userSettingsProvider.notifier).loginWithPhone(
          code: _codeController.text,
          phoneNumber: _phoneController.text,
        );
    context.go(AppRoutes.placeLinks);
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            color: Color(0x1F000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
