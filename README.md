# Water Quality Companion (APK 原型)

这是一个基于 Flutter 的安卓 APK 原型项目，用于配套 Arduino UNO 水质检测设备（蓝牙传输）.

## 功能
- 蓝牙连接 Arduino（基于 `flutter_blue_plus`，示例 UUID 可替换）
- 接收 Arduino 上报数据（示例格式：`ph:7.05;tds:75;temp:25;cr6:0.15;score:66`）
- 四个核心页面 UI：
  1. 地图总览页（Map）
  2. 水质详情页（Water quality）
  3. 健康检测看板页（My Health Test）
  4. 水知识页（Knowledge of Water）

## 目录
- `flutter_app/lib/main.dart`: 主要 UI 与蓝牙数据流示例
- `flutter_app/pubspec.yaml`: 依赖配置

## 本地运行与打包 APK
```bash
cd flutter_app
flutter pub get
flutter run
```

打包 APK：
```bash
flutter build apk --release
```

输出文件：
`build/app/outputs/flutter-apk/app-release.apk`

## Arduino 通信建议
1. Arduino 端按固定文本协议发送，建议每条数据以换行结束。
2. 手机端应做粘包处理（按换行分帧）。
3. 统一单位：PH、TDS(ppm)、温度(℃)、Cr6+(mg/L)、Score(0-100)。
4. 可增加 CRC 或简单校验字段确保通信可靠性。
