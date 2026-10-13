import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';

void main() {
  group('PromptTemplateEngine Tests (TDD)', () {
    const engine = PromptTemplateEngine();

    test('injects rich micro-climate details into analysis prompt when available', () {
      final metadata = DiaryMetadata(
        recordedAt: DateTime(2026, 10, 13, 14, 0),
        weather: WeatherCondition.sunny,
        wordCount: 150,
        location: '成都',
        temperature: 20.3,
        apparentTemperature: 21.0,
        humidity: 60,
        isDay: true,
        detailedWeather: '晴间多云',
      );

      final bundle = engine.buildAnalysisPromptBundle(
        metadata: metadata,
        diaryContent: 'Today is a wonderful sunny day in Chengdu.',
      );

      expect(bundle.userMessage, contains('记录地点: 成都'));
      expect(bundle.userMessage, contains('晴间多云'));
      expect(bundle.userMessage, contains('20°C'));
      expect(bundle.userMessage, contains('体感 21°C'));
      expect(bundle.userMessage, contains('湿度 60%'));
    });

    test('falls back gracefully to standard weather description when micro-climate is null', () {
      final metadata = DiaryMetadata(
        recordedAt: DateTime(2026, 10, 13, 14, 0),
        weather: WeatherCondition.rainy,
        wordCount: 50,
      );

      final bundle = engine.buildAnalysisPromptBundle(
        metadata: metadata,
        diaryContent: 'Rainy mood today.',
      );

      expect(bundle.userMessage, contains('当时天气: 🌧️ 下雨'));
      expect(bundle.userMessage, isNot(contains('体感')));
    });
  });
}
