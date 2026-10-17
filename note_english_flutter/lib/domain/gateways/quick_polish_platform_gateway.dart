typedef QuickPolishTextHandler = Future<String> Function(String selectedText);

/// 全局快捷润色与系统原生宿主防腐网关接口 (DDD Gateway)
abstract class IQuickPolishPlatformGateway {
  /// 初始化菜单栏常驻图标与全局快捷键监听
  Future<void> initialize();

  /// 注册全局快捷键触发时的文本处理回调 (入参为当前选中的待润色文本，返回值为替换后的地道英文)
  void setQuickPolishHandler(QuickPolishTextHandler handler);

  /// 检查是否有 macOS 辅助功能 (Accessibility) 权限
  Future<bool> isAccessibilityGranted();

  /// 唤起系统设置以授予辅助功能权限
  Future<void> requestAccessibilityPermission();

  /// 启用或禁用原生全局快捷键与快捷润色
  Future<void> setQuickPolishEnabled(bool enabled);

  /// 显示系统原生通知提示 (例如: 已就绪 / 已润色替换)
  Future<void> showNotification({
    required String title,
    required String body,
  });

  /// 在 macOS 访达 (Finder) 中高亮定位当前应用 Bundle，便于手动拖入辅助功能列表
  Future<void> openAppInFinder();
}
