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

    test('dynamically adapts prompt to Japanese system locale via in-place replacement', () {
      final customEngine = PromptTemplateEngine(
        userLanguage: '日文',
      );

      final metadata = DiaryMetadata(
        recordedAt: DateTime(2026, 10, 13, 14, 0),
        weather: WeatherCondition.sunny,
        wordCount: 10,
      );

      final bundle = customEngine.buildAnalysisPromptBundle(
        metadata: metadata,
        diaryContent: '今日はとても天気が良かったです。I went to the park.',
      );

      // 验证提示词结构完全保持原样，只将中文直接替换为日文
      expect(bundle.systemPrompt, contains('若日记正文中完全没有日文或其他非英语汇'));
      expect(bundle.systemPrompt, contains('日式思维的表述'));
      expect(bundle.systemPrompt, contains('剖析日文母语思维与英文母语思维的转换逻辑'));
      expect(bundle.systemPrompt, contains('精准日文释义'));
      // 验证未添加多余的环境声明块
      expect(bundle.systemPrompt, isNot(contains('【用户环境】')));
      expect(bundle.systemPrompt, isNot(contains('剖析中文母语思维')));
    });

    test('dynamically adapts prompt to French system locale via in-place replacement', () {
      final customEngine = PromptTemplateEngine(
        userLanguage: '法文',
      );

      final bundle = customEngine.buildAnalysisPromptBundle(
        metadata: DiaryMetadata(recordedAt: DateTime.now()),
        diaryContent: 'Je voudrais commander un café.',
      );

      expect(bundle.systemPrompt, contains('精准法文释义'));
      expect(bundle.systemPrompt, isNot(contains('【用户环境】')));
      expect(bundle.systemPrompt, contains('剖析法文母语思维'));
    });

    test('dynamically adapts inquiry prompt to target system locale via in-place replacement', () {
      final customEngine = PromptTemplateEngine(
        userLanguage: '西班牙文',
      );

      final bundle = customEngine.buildInquiryPromptBundle(
        diaryContent: 'test diary',
        analysisContext: 'analysis context',
        historyTurns: const [],
        userQuestion: 'How to use this?',
      );

      expect(bundle.systemPrompt, contains('精准西班牙文释义'));
      expect(bundle.systemPrompt, isNot(contains('【用户环境】')));
    });
  });
}

