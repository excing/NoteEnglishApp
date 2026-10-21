import 'package:flutter/services.dart';

/// 移动端与全平台设备屏幕方向锁定单一信源 (App Device Orientation)
///
/// 遵循单一信源原则 (Single Source of Truth)，统一收敛屏幕方向策略。
/// 移动端设备默认锁定为竖屏 (PortraitUp)，防止用户横向握持手机时界面自动旋转至横屏。
abstract final class AppDeviceOrientation {
  /// 应用首选屏幕方向单一信源定义 (仅支持竖屏)
  static const List<DeviceOrientation> preferredOrientations = [
    DeviceOrientation.portraitUp,
  ];

  /// 锁定移动端屏幕方向为首选竖屏方向
  ///
  /// 在应用初始化阶段调用，向底层宿主发送方向锁定指令，杜绝横屏抖动。
  static Future<void> lockPreferredOrientations() async {
    await SystemChrome.setPreferredOrientations(preferredOrientations);
  }
}
