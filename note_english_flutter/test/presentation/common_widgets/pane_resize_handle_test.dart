import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/presentation/common_widgets/pane_resize_handle.dart';

void main() {
  group('PaneResizeHandle 分栏拖拽手柄与分割线验证', () {
    testWidgets('默认采用 tokens.canvas 背景色，避免透明透出黑色底层',
        (WidgetTester tester) async {
      double lastDelta = 0.0;
      bool resetCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeTokens.createThemeData(isDark: false),
          home: Scaffold(
            body: Center(
              child: PaneResizeHandle(
                onDelta: (d) => lastDelta = d,
                onReset: () => resetCalled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 验证外层容器带有背景色 (tokens.canvas = AppColors.lightCanvas)
      final containerFinder = find.byType(Container).first;
      final containerWidget = tester.widget<Container>(containerFinder);
      expect(containerWidget.color, equals(AppThemeTokens.light.canvas));

      // 验证双击恢复默认
      await tester.tap(find.byType(PaneResizeHandle));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(PaneResizeHandle));
      await tester.pumpAndSettle();
      expect(resetCalled, isTrue);

      // 验证拖拽触发 onDelta
      final gesture = await tester.startGesture(tester.getCenter(find.byType(PaneResizeHandle)));
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(lastDelta, greaterThan(0.0));
    });

    testWidgets('支持显式自定义 backgroundColor',
        (WidgetTester tester) async {
      const customBg = Color(0xFF123456);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeTokens.createThemeData(isDark: false),
          home: Scaffold(
            body: Center(
              child: PaneResizeHandle(
                backgroundColor: customBg,
                onDelta: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final containerFinder = find.byType(Container).first;
      final containerWidget = tester.widget<Container>(containerFinder);
      expect(containerWidget.color, equals(customBg));
    });
  });
}
