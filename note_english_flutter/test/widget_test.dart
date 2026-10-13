import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/app/service_locator.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/main.dart';

void main() {
  setUp(() async {
    await sl.reset();
    await setupServiceLocator();
  });

  testWidgets('NoteEnglishApp writing studio smoke test', (WidgetTester tester) async {
    final entry = DiaryEntry.create(
      content: 'Today is a tranquil rainy day.',
      metadata: DiaryMetadata(
        recordedAt: DateTime(2026, 10, 10, 21, 30),
        weather: WeatherCondition.rainy,
        wordCount: 6,
      ),
    );

    await tester.pumpWidget(NoteEnglishApp(initialEntry: entry));
    await tester.pump();

    // 验证核心组件渲染
    expect(find.text('呼叫主编梳理'), findsOneWidget);
    expect(find.textContaining('下雨'), findsOneWidget);
  });

  testWidgets('Ultra-narrow viewport (220px) renders gracefully without any RenderFlex overflow',
      (WidgetTester tester) async {
    // 模拟拉到极小宽度（220px）的极限测试场景
    tester.view.physicalSize = const Size(220, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final entry = DiaryEntry.create(
      content: 'Short test.',
      metadata: DiaryMetadata(
        recordedAt: DateTime(2026, 10, 10, 21, 30),
        weather: WeatherCondition.rainy,
        wordCount: 2,
      ),
    );

    await tester.pumpWidget(NoteEnglishApp(initialEntry: entry));
    await tester.pump();

    // 验证在 220px 下降级为紧凑模式且无任何溢出崩溃
    expect(find.byKey(const ValueKey('call_editor_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick_new_diary_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('diary_drawer_button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
