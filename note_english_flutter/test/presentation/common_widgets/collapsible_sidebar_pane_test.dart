import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/presentation/common_widgets/collapsible_sidebar_pane.dart';

void main() {
  group('CollapsibleSidebarPane 侧边栏滑入滑出组件验证', () {
    testWidgets('isVisible 为 true 时展开，宽度为 targetWidth',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                CollapsibleSidebarPane(
                  isVisible: true,
                  targetWidth: 260.0,
                  direction: SidebarSlideDirection.fromLeft,
                  duration: Duration(milliseconds: 100),
                  child: SizedBox(width: 260, child: Text('Sidebar Content')),
                ),
                Expanded(child: Text('Main Content')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sidebar Content'), findsOneWidget);
      final size = tester.getSize(find.byType(CollapsibleSidebarPane));
      expect(size.width, equals(260.0));
    });

    testWidgets('isVisible 从 true 变为 false 时，平滑滑出收起，最终尺寸收缩为 0',
        (WidgetTester tester) async {
      bool isVisible = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => setState(() => isVisible = !isVisible),
                      child: const Text('Toggle'),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          CollapsibleSidebarPane(
                            isVisible: isVisible,
                            targetWidth: 240.0,
                            direction: SidebarSlideDirection.fromLeft,
                            duration: const Duration(milliseconds: 200),
                            child: const SizedBox(
                              width: 240,
                              child: Text('Left Drawer Item'),
                            ),
                          ),
                          const Expanded(child: Text('Editor Pane')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Left Drawer Item'), findsOneWidget);

      // 点击切换为隐藏
      await tester.tap(find.text('Toggle'));
      await tester.pump(); // 动画开始

      // 推进 100ms (动画中途)，宽度正在平滑缩小中
      await tester.pump(const Duration(milliseconds: 100));
      final midWidth = tester.getSize(find.byType(CollapsibleSidebarPane)).width;
      expect(midWidth, greaterThan(0.0));
      expect(midWidth, lessThan(240.0));

      // 动画完全结束
      await tester.pumpAndSettle();
      expect(find.text('Left Drawer Item'), findsNothing);
    });

    testWidgets('duration 为 Duration.zero (拖拽调宽模式) 时，立即响应且不发生插值延迟',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                CollapsibleSidebarPane(
                  isVisible: true,
                  targetWidth: 300.0,
                  direction: SidebarSlideDirection.fromRight,
                  duration: Duration.zero,
                  child: SizedBox(width: 300, child: Text('Zero Duration')),
                ),
              ],
            ),
          ),
        ),
      );
      // 不需要 pumpAndSettle，第一帧直接到达目标尺寸
      await tester.pump();

      expect(find.text('Zero Duration'), findsOneWidget);
      final size = tester.getSize(find.byType(CollapsibleSidebarPane));
      expect(size.width, equals(300.0));
    });
  });
}
