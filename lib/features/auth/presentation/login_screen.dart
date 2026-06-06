import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../profile/application/user_settings.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _codeController = TextEditingController();
  final _phoneController = TextEditingController(text: '13800000000');
  final _formKey = GlobalKey<FormState>();
  bool _codeSent = false;

  @override
  void dispose() {
    _codeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(22),
                children: [
                  const _LoginBrandMark(),
                  const SizedBox(height: 18),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: 0.64),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '登录',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '输入手机号获取验证码，验证成功后即可登录。',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LoginPanel(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            enabled: !_codeSent,
                            decoration: const InputDecoration(
                              labelText: '手机号',
                              prefixIcon: Icon(Icons.phone_iphone),
                              border: OutlineInputBorder(),
                            ),
                            validator: _validatePhone,
                          ),
                          if (_codeSent) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '验证码',
                                prefixIcon: Icon(Icons.sms_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: _validateCode,
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (_codeSent)
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _login,
                                icon: const Icon(Icons.login),
                                label: const Text('登陆成功'),
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _sendCode,
                                icon: const Icon(Icons.sms_outlined),
                                label: const Text('发送验证码'),
                              ),
                            ),
                        ],
                      ),
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

    setState(() => _codeSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('验证码已发送（演示模式）')),
    );
  }

  void _login() {
    if (!_codeSent) {
      _sendCode();
      return;
    }

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

class _LoginBrandMark extends StatelessWidget {
  const _LoginBrandMark();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                blurRadius: 18,
                color: Color(0x26000000),
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.photo_library_outlined, color: colors.onPrimary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'encounter',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              Text(
                '照片记忆 · NFC · AR',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            color: Color(0x1A000000),
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}
