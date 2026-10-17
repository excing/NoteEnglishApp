import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 全局快捷键单一信源定义 (Application Shortcuts & Accelerators)
///
/// 遵循 macOS 与 Windows/Linux 桌面级人机交互习惯，统一管理快捷键绑定与提示文本。
abstract final class AppShortcuts {
  /// 是否为 macOS / iOS 平台 (优先使用 Meta/Cmd 键)
  static bool get isApplePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// 修饰键符号/前缀 (Mac 下为 ⌘, Windows/Linux 下为 Ctrl+)
  static String get modifierLabel => isApplePlatform ? '⌘' : 'Ctrl+';

  // ================= 提示文本 (Tooltip Labels) =================
  /// 新建随笔提示
  static String get newEntryTooltip => '新建随笔 ($modifierLabel N)';

  /// 切换左边栏提示
  static String toggleLeftSidebarTooltip(bool isOpen) =>
      '${isOpen ? "收起 OtterJot" : "展开 OtterJot"} ($modifierLabel B)';

  /// 切换右边栏提示
  static String toggleRightSidebarTooltip(bool isOpen) =>
      '${isOpen ? "收起主编视窗" : "展开主编视窗"} ($modifierLabel J)';

  /// 呼叫主编梳理提示
  static String get callEditorTooltip => '呼叫主编梳理 ($modifierLabel↵)';

  /// 打开语料库提示
  static String get openCorpusTooltip => '语料库金句 ($modifierLabel K)';

  /// 打开设置提示
  static String get openSettingsTooltip => '设置 ($modifierLabel,)';

  // ================= 快捷键激活器 (Activator Sets) =================

  /// 新建随笔: Cmd/Ctrl + N
  static const List<ShortcutActivator> newEntry = [
    SingleActivator(LogicalKeyboardKey.keyN, meta: true),
    SingleActivator(LogicalKeyboardKey.keyN, control: true),
  ];

  /// 切换左边栏 (随笔手账): Cmd/Ctrl + B, Cmd/Ctrl + [, Cmd/Ctrl + \, Cmd/Ctrl + Shift + L
  static const List<ShortcutActivator> toggleLeftSidebar = [
    SingleActivator(LogicalKeyboardKey.keyB, meta: true),
    SingleActivator(LogicalKeyboardKey.keyB, control: true),
    SingleActivator(LogicalKeyboardKey.bracketLeft, meta: true),
    SingleActivator(LogicalKeyboardKey.bracketLeft, control: true),
    SingleActivator(LogicalKeyboardKey.backslash, meta: true),
    SingleActivator(LogicalKeyboardKey.backslash, control: true),
    SingleActivator(LogicalKeyboardKey.keyL, meta: true, shift: true),
    SingleActivator(LogicalKeyboardKey.keyL, control: true, shift: true),
  ];

  /// 切换右边栏 (AI 主编视窗): Cmd/Ctrl + J 或 Cmd/Ctrl + ] 或 Cmd/Ctrl + Shift + B
  static const List<ShortcutActivator> toggleRightSidebar = [
    SingleActivator(LogicalKeyboardKey.keyJ, meta: true),
    SingleActivator(LogicalKeyboardKey.keyJ, control: true),
    SingleActivator(LogicalKeyboardKey.bracketRight, meta: true),
    SingleActivator(LogicalKeyboardKey.bracketRight, control: true),
    SingleActivator(LogicalKeyboardKey.keyB, meta: true, shift: true),
    SingleActivator(LogicalKeyboardKey.keyB, control: true, shift: true),
  ];

  /// 呼叫主编梳理: Cmd/Ctrl + Enter
  static const List<ShortcutActivator> callEditor = [
    SingleActivator(LogicalKeyboardKey.enter, meta: true),
    SingleActivator(LogicalKeyboardKey.enter, control: true),
  ];

  /// 打开语料库: Cmd/Ctrl + K 或 Cmd/Ctrl + Shift + C
  static const List<ShortcutActivator> openCorpus = [
    SingleActivator(LogicalKeyboardKey.keyK, meta: true),
    SingleActivator(LogicalKeyboardKey.keyK, control: true),
    SingleActivator(LogicalKeyboardKey.keyC, meta: true, shift: true),
    SingleActivator(LogicalKeyboardKey.keyC, control: true, shift: true),
  ];

  /// 打开设置: Cmd/Ctrl + ,
  static const List<ShortcutActivator> openSettings = [
    SingleActivator(LogicalKeyboardKey.comma, meta: true),
    SingleActivator(LogicalKeyboardKey.comma, control: true),
  ];

  /// 刷新实时天气: Cmd/Ctrl + R
  static const List<ShortcutActivator> refreshWeather = [
    SingleActivator(LogicalKeyboardKey.keyR, meta: true),
    SingleActivator(LogicalKeyboardKey.keyR, control: true),
  ];

  /// 判定当前键盘物理按键事件是否匹配给定的激活器集合中的任意一项
  static bool matchesAny(List<ShortcutActivator> activators, KeyEvent event) {
    for (final act in activators) {
      if (act.accepts(event, HardwareKeyboard.instance)) {
        return true;
      }
    }
    return false;
  }
}
