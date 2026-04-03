# Pebble

Pebble 是一个基于 Flutter 的移动端原型项目，当前 UI 已重置为 3 个核心页面：`Home`、`Map`、`Ask`。这 3 个页面按照最新 Figma 设计重建，并统一使用浅绿色背景、玻璃卡片、底部导航和本地图片资源。

## 当前状态

- `Home`：健康测试总览页，包含平均测试数据、设备状态、Test Life、Water Quality 4 张卡片
- `Map`：地图页，包含搜索栏、地图标记和地点信息卡片
- `Ask`：知识问答页，包含常见问题列表和 AI Search 卡片
- 本地资源已导入 `flutter_app/assets/`
- 当前代码通过 `flutter analyze` 和 `flutter test`

## 项目结构

- `flutter_app/`：Flutter 应用主体
- `flutter_app/lib/main.dart`：应用入口
- `flutter_app/lib/app/pebble_app.dart`：三页导航壳层
- `flutter_app/lib/pages/`：`Home` / `Map` / `Ask` 页面
- `flutter_app/lib/widgets/`：底部导航、玻璃卡片、环形进度等共享组件
- `flutter_app/lib/theme/design_tokens.dart`：颜色、圆角、阴影等设计令牌
- `flutter_app/assets/`：从 Figma 固化下来的图片资源
- `flutter/`：本地 Flutter SDK

## 本地运行

```powershell
cd flutter_app
..\flutter\bin\flutter.bat pub get
..\flutter\bin\flutter.bat run
```

## 验证

```powershell
cd flutter_app
..\flutter\bin\flutter.bat analyze
..\flutter\bin\flutter.bat test
```

## 打包 APK

```powershell
cd flutter_app
..\flutter\bin\flutter.bat build apk --release
```

输出文件默认位于 `flutter_app/build/app/outputs/flutter-apk/app-release.apk`。
