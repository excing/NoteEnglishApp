import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/app/service_locator.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/main.dart';

void main() {
  testWidgets('NoteEnglishApp writing studio smoke test', (WidgetTester tester) async {
    // 注册服务定位器
    await setupServiceLocator();

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
}
