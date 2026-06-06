# PhotoLink VR

PhotoLink VR 是一个用于照片记录、分类管理、NFC 内容链接和沉浸式回放的 Flutter App 项目。

## 当前版本目标

MVP 优先跑通以下流程：

1. 用户授权读取本地照片。
2. 用户按时间、地区、种类浏览照片。
3. 用户在首页地图查看照片位置。
4. 同一区域内照片大于等于 2 张时进行聚合展示。
5. 用户创建相册。
6. 用户将相册或回放内容绑定到 NFC 标签。
7. 手机读取 NFC 标签后打开对应内容。
8. 用户播放相册的沉浸式照片回放。

## 底部导航

- 地点链接：地图首页，展示照片地点、区域聚合和 Mapbox 地图。
- 日期：按拍摄时间浏览照片，后续承接时间轴功能。
- 回忆：照片回放、VR 视频和沉浸式重现入口。
- NFC：读取、写入和绑定 NFC 标签。
- 分类：按学校、景点、生活区等类型整理照片。

## 技术栈

- Flutter
- Dart
- Riverpod
- go_router
- Dio
- Mapbox Static Tiles API
- Mapbox 样式：`mapbox://styles/mapbox/satellite-streets-v12`
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
