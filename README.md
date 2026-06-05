# PhotoLink VR

PhotoLink VR 是一个用于照片记录、分类管理、NFC 内容链接和沉浸式回放的 Flutter App 项目。

## 当前版本目标

MVP 优先跑通以下流程：

1. 用户上传或导入照片。
2. 用户按时间、地区、种类浏览照片。
3. 用户创建相册。
4. 用户将相册或回放内容绑定到 NFC 标签。
5. 手机读取 NFC 标签后打开对应内容。
6. 用户播放相册的沉浸式照片回放。

## 技术栈

- Flutter
- Dart
- Riverpod
- go_router
- Dio
- Hive
- image_picker
- photo_manager
- nfc_manager
- video_player
- photo_view

## 本地运行

本仓库已经包含 Flutter 项目核心文件。如果本机已安装 Flutter SDK，可以在仓库根目录执行：

```bash
flutter pub get
flutter create . --platforms=android,ios
flutter run
```

其中 `flutter create . --platforms=android,ios` 用于生成 Android 和 iOS 平台工程文件。

## 目录结构

```text
lib/
  main.dart
  app/
  core/
  features/
    auth/
    photos/
    albums/
    nfc/
    vr/
    profile/
  shared/
```
