import 'package:flutter/material.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';

/// 桌面与平板端分栏拖拽手柄 (Pane Resize Handle)
///
/// 允许用户横向拖拽调整侧边栏宽度，提供：
/// - 舒适的点击/拖拽热区 (Hit Target)
/// - 原生级鼠标光标 (SystemMouseCursors.resizeColumn)
/// - 悬停与拖拽状态高亮
/// - 双击恢复默认宽度
class PaneResizeHandle extends StatefulWidget {
  final ValueChanged<double> onDelta;
  final VoidCallback? onReset;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final String? tooltip;
  final double hitWidth;

  const PaneResizeHandle({
    super.key,
    required this.onDelta,
    this.onReset,
    this.onDragStart,
    this.onDragEnd,
    this.tooltip,
    this.hitWidth = 8.0,
  });

  @override
  State<PaneResizeHandle> createState() => _PaneResizeHandleState();
}

class _PaneResizeHandleState extends State<PaneResizeHandle> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final isActive = _isHovered || _isDragging;

    final child = MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: widget.onReset,
        onHorizontalDragStart: (_) {
          setState(() => _isDragging = true);
          widget.onDragStart?.call();
        },
        onHorizontalDragEnd: (_) {
          setState(() => _isDragging = false);
          widget.onDragEnd?.call();
        },
        onHorizontalDragCancel: () {
          setState(() => _isDragging = false);
          widget.onDragEnd?.call();
        },
        onHorizontalDragUpdate: (details) {
          widget.onDelta(details.primaryDelta ?? 0.0);
        },
        child: SizedBox(
          width: widget.hitWidth,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 垂直分割基线
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: isActive ? 2.0 : 1.0,
                color: isActive ? tokens.terracotta : tokens.cardBorder,
              ),
              // 悬停/拖拽时浮现的居中手柄指示条
              if (isActive)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 4.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: tokens.terracotta,
                    borderRadius: BorderRadius.circular(2.0),
                    boxShadow: [
                      BoxShadow(
                        color: tokens.terracotta.withValues(alpha: 0.3),
                        blurRadius: 4.0,
                        spreadRadius: 1.0,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 600),
        child: child,
      );
    }

    return child;
  }
}
