import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../application/user_settings.dart';
import 'profile_avatar.dart';

class ProfileAccountEditScreen extends ConsumerStatefulWidget {
  const ProfileAccountEditScreen({super.key});

  @override
  ConsumerState<ProfileAccountEditScreen> createState() =>
      _ProfileAccountEditScreenState();
}

class _ProfileAccountEditScreenState
    extends ConsumerState<ProfileAccountEditScreen> {
  final _nicknameController = TextEditingController();
  String? _avatarImageBase64;
  bool _initialized = false;
  bool _pickingAvatar = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final settings = ref.read(userSettingsProvider);
    _nicknameController.text = settings.nickname ?? '';
    _avatarImageBase64 = settings.avatarImageBase64;
    _initialized = true;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(userSettingsProvider);
    final colors = Theme.of(context).colorScheme;

    return AppScaffold(
      selectedIndex: 2,
      title: '账号资料',
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outlineVariant),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 20,
                  color: Color(0x14000000),
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ProfileAvatar(
                        imageBase64: _avatarImageBase64,
                        radius: 42,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              settings.userId ?? '未分配 ID',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              settings.phoneNumber ?? '尚未绑定手机号',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: _pickingAvatar ? null : _pickAvatar,
                    icon: Icon(
                      _pickingAvatar
                          ? Icons.hourglass_empty
                          : Icons.upload_outlined,
                    ),
                    label: Text(_pickingAvatar ? '正在上传头像' : '上传头像'),
                  ),
                  if (_avatarImageBase64 != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _avatarImageBase64 = null;
                        });
                      },
                      icon: const Icon(Icons.restore_outlined),
                      label: const Text('恢复默认头像'),
                    ),
                  ],
                  const SizedBox(height: 18),
                  TextField(
                    controller: _nicknameController,
                    maxLength: 16,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '昵称',
                      hintText: '输入你想展示的昵称',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close),
                          label: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.check),
                          label: const Text('保存资料'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    setState(() {
      _pickingAvatar = true;
    });

    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxHeight: 720,
        maxWidth: 720,
        imageQuality: 86,
      );
      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _avatarImageBase64 = base64Encode(bytes);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('头像上传失败，请重新选择图片')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _pickingAvatar = false;
        });
      }
    }
  }

  void _save() {
    ref.read(userSettingsProvider.notifier).setAccountProfile(
          avatarImageBase64: _avatarImageBase64,
          nickname: _nicknameController.text,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('账号资料已保存')),
    );
    context.pop();
  }
}
