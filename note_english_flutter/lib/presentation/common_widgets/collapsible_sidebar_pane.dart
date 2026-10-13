import 'package:flutter/material.dart';

/// 侧边栏滑入滑出方向 (Sidebar Slide Direction)
enum SidebarSlideDirection {
  /// 从屏幕左侧滑入 / 向屏幕左侧滑出
  fromLeft,

  /// 从屏幕右侧滑入 / 向屏幕右侧滑出
  fromRight,
}

/// 侧边栏平滑滑入滑出容器 (Collapsible Sidebar Pane)
///
/// 具备以下特性：
/// 1. 显隐切换时平滑滑入/滑出过渡 (Slide In / Slide Out)；
/// 2. 内部内容在过渡过程中保持恒定宽度，避免文字排版与子组件发生挤压折叠；
/// 3. 支持拖拽调宽模式 (duration = Duration.zero)，实现 60/120fps 绝对物理跟手。
class CollapsibleSidebarPane extends StatelessWidget {
  /// 边栏是否处于可见显示状态
  final bool isVisible;

  /// 展开时的目标宽度
  final double targetWidth;

  /// 滑入滑出方向
  final SidebarSlideDirection direction;

  /// 动画过渡时长 (拖拽时传入 Duration.zero)
  final Duration duration;

  /// 动画过渡曲线
  final Curve curve;

  /// 边栏子内容
  final Widget child;

  const CollapsibleSidebarPane({
    super.key,
    required this.isVisible,
    required this.targetWidth,
    required this.direction,
    required this.child,
    this.duration = const Duration(milliseconds: 280),
    this.curve = Curves.easeInOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    // 拖拽手势中传入 Duration.zero 时，直接同步返回固定尺寸，消除所有过渡插值开销
    if (duration == Duration.zero) {
      if (!isVisible || targetWidth <= 0.0) {
        return const SizedBox.shrink();
      }
      return SizedBox(
        width: targetWidth,
        child: child,
      );
    }

    final effectiveTargetWidth = isVisible ? targetWidth : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: effectiveTargetWidth),
      duration: duration,
      curve: curve,
      builder: (context, animatedWidth, _) {
        if (animatedWidth <= 0.001) {
          return const SizedBox.shrink();
        }

        return ClipRect(
          child: SizedBox(
            width: animatedWidth,
            child: OverflowBox(
              alignment: direction == SidebarSlideDirection.fromLeft
                  ? Alignment.topRight
                  : Alignment.topLeft,
              minWidth: targetWidth,
              maxWidth: targetWidth,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
