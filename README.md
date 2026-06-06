# PhotoLink VR

PhotoLink VR 是一个用于照片记录、比邻环管理、NFC 内容链接和沉浸式回放的 Flutter App 项目。

## 当前版本目标

MVP 优先跑通以下流程：

1. 用户通过手机号验证码登录，并自动分配 PhotoLink ID。
2. 用户授权读取本地照片。
3. 用户按时间、地区、种类浏览照片。
4. 用户在首页地图查看照片位置。
5. 同一区域内照片大于等于 2 张时进行聚合展示。
6. 用户创建相册。
7. 用户将相册或回放内容绑定到 NFC 标签。
8. 手机读取 NFC 标签后打开对应内容。
9. 用户播放相册的沉浸式照片回放。
10. 用户再次来到相同场景时，通过 AR 重现比邻环相册照片，并让照片以浮现、环绕、景深漂移等方式动起来。

## 底部导航

- 时空环：地图首页，默认只显示“地图漫游”；点击地图中的地点标点或区域聚合后，只展示用户选择的相册形式。
- 日期：按拍摄时间浏览照片；内部已连接“时间 / 堆叠 / 日历 / 杂志”四种形式，可按日期流、照片堆、月历和年份杂志查看。
- 比邻环：右上角加号可建立文件夹，支持家庭、友谊、爱情和其他自定义相册；可选择是否开启个人三色环 social，关闭时保留原有相册功能，开启后可为每个环选择 3-10 张照片，并通过预留智能体接口进行图片分析、后台用户画像和匹配系统推荐；相册卡片右上角小操作图标可展开“AR 同场景重现”和“剪辑回忆视频”两个选项。
- 我的：个人中心入口，用于管理自动分配的 PhotoLink ID、照片权限、NFC 分享记录、多人相册、VR 回忆设置、相册背景色和地点漫游后的展示形式。

登录页只负责手机号验证码登录：用户输入手机号，App 发送验证码，用户输入验证码后登录并自动分配 PhotoLink ID。相册背景色和地点漫游后的展示形式统一放在 App 内部的“我的”页面设置。相册背景色支持预设色和 RGB 自定义；展示形式与地点漫游后的页面关联，用户选择“相册”则点击地图地点后只展示相册详情，选择“相簿”则只展示照片堆叠。

回忆和 NFC 不再作为底部 tab 出现。回忆视频不保留固定区域，点击比邻环相册卡片右上角小操作图标并选择“剪辑回忆视频”后即时生成并播放，片段之间使用平滑过渡；打开任意比邻环相册后，详情页会用小图标标注相册所有权人数，右上角加号可展开“NFC 分享”“AR 同场景重现”“添加照片”三个功能。

## 技术栈

- Flutter
- Dart
- Riverpod
- go_router
- Dio
- Mapbox Static Tiles API
- Mapbox 样式：`mapbox://styles/mapbox/satellite-streets-v12`
- 三色环智能体预留接口：`/agents/personal-tri-ring/social`，请求包含自我环、关系环、场景环三组照片，每组 3-10 张，响应包含图片分析、用户画像和匹配建议。
- AR/Unity 预留接口：Flutter MethodChannel `photo_link_vr/unity_ar_replay`，方法 `createArReplay`，用于向 Unity 传入相册、场景锚点、照片层和动效参数。
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

## 本地运行与 Mapbox Token 配置

Mapbox token 不写入仓库，通过本地文件在编译期注入（`--dart-define-from-file`）。

1. 复制模板为本地配置（`env.json` 已被 `.gitignore` 忽略，不会上传）：

   ```bash
   cp env.example.json env.json
   ```

2. 在 `env.json` 填入你的 Mapbox access token（申请：https://account.mapbox.com/access-tokens/）：

   ```json
   {
     "MAPBOX_ACCESS_TOKEN": "pk.your_real_token",
     "MAPBOX_STYLE": "mapbox://styles/mapbox/satellite-streets-v12",
     "API_BASE_URL": "https://api.example.com"
   }
   ```

3. 用本地配置运行 / 构建：

   ```bash
   flutter run --dart-define-from-file=env.json
   flutter build apk --dart-define-from-file=env.json
   ```

未配置 token 时，空间漫游地图会显示占位提示条；配置后即加载完整 Mapbox 地图瓦片。
