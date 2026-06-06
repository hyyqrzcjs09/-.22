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

- 地点链接：地图首页，展示照片地点、区域聚合和 Mapbox 地图；内部已连接“漫游地图 / 相册 / 相簿”三种形式，可在地图、地点详情卡和照片堆叠之间切换。
- 日期：按拍摄时间浏览照片；内部已连接“时间 / 堆叠 / 日历 / 杂志”四种形式，可按日期流、照片堆、月历和年份杂志查看。
- 分类：右上角加号可建立文件夹，支持家庭、友谊、爱情和其他自定义相册；相册卡片右上角 VR 小图标可将相册剪辑成回忆视频，并立即弹出播放层。

回忆和 NFC 不再作为底部 tab 出现。回忆视频不保留固定区域，点击分类相册的 VR 图标后即时生成并播放，片段之间使用平滑过渡；打开任意分类相册后，详情页右上角的 NFC 图标可选择“仅用 NFC 分享该相册内容”，或“变成多人相册”。

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
