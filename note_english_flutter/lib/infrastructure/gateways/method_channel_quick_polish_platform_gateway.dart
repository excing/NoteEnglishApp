import 'package:flutter/services.dart';
import 'package:note_english_flutter/domain/gateways/quick_polish_platform_gateway.dart';

/// 基于 Flutter 原生 MethodChannel 实现的平台防腐网关
class MethodChannelQuickPolishPlatformGateway implements IQuickPolishPlatformGateway {
  static const MethodChannel _channel =
      MethodChannel('io.github.excing.otterjot/quick_polish');

  QuickPolishTextHandler? _handler;

  @override
  Future<void> initialize() async {
    _channel.setMethodCallHandler(_handleNativeMethodCall);
    try {
      await _channel.invokeMethod('initializeQuickPolish');
    } on MissingPluginException {
      // 兼容在非桌面平台或测试环境中无原生插件宿主的情况
    } on PlatformException catch (_) {
      // 原生抛出平台异常时进行安全吸收与降级
    }
  }

  @override
  void setQuickPolishHandler(QuickPolishTextHandler handler) {
    _handler = handler;
  }

  @override
  Future<bool> isAccessibilityGranted() async {
    try {
      final granted =
          await _channel.invokeMethod<bool>('isAccessibilityGranted');
      return granted ?? false;
    } on MissingPluginException {
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> requestAccessibilityPermission() async {
    try {
      await _channel.invokeMethod('requestAccessibilityPermission');
    } on MissingPluginException {
      // No-op
    } catch (_) {}
  }

  @override
  Future<void> setQuickPolishEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setQuickPolishEnabled', {'enabled': enabled});
    } on MissingPluginException {
      // No-op
    } catch (_) {}
  }

  @override
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    try {
      await _channel.invokeMethod('showNotification', {
        'title': title,
        'body': body,
      });
    } on MissingPluginException {
      // No-op
    } catch (_) {}
  }

  @override
  Future<void> openAppInFinder() async {
    try {
      await _channel.invokeMethod('openAppInFinder');
    } on MissingPluginException {
      // No-op
    } catch (_) {}
  }

  @override
  Future<void> relaunchApp() async {
    try {
      await _channel.invokeMethod('relaunchApp');
    } on MissingPluginException {
      // No-op
    } catch (_) {}
  }

  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'performQuickPolish':
        final args = call.arguments;
        final rawText = (args is Map ? args['selectedText'] : null) as String? ?? '';
        if (_handler != null) {
          final polished = await _handler!(rawText);
          return {'polishedText': polished};
        }
        return {'polishedText': rawText};
      default:
        throw MissingPluginException('Unimplemented method ${call.method}');
    }
  }
}
