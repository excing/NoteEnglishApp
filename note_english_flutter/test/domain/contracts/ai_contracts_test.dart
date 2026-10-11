import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/domain/contracts/ai_contracts.dart';
import 'package:note_english_flutter/domain/models/analysis/diary_analysis_result.dart';
import 'package:note_english_flutter/domain/models/inquiry/inquiry_response.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';

void main() {
  group('PromptTemplateEngine Tests (TDD)', () {
    late PromptTemplateEngine engine;

    setUp(() {
      engine = const PromptTemplateEngine();
    });

    test('should assemble diary analysis prompt with user custom prompt and strict schema', () {
      final metadata = DiaryMetadata(
        recordedAt: DateTime(2026, 10, 10, 21, 30),
        weather: WeatherCondition.rainy,
        wordCount: 48,
      );
      const diaryContent =
          '今晚加班到九点多，走出来的时候外面下着很大的雨。Today work overtime until 9pm, outside is raining heavily.';
      const customPrompt = '请扮演《纽约客》杂志主编，偏好细腻、文学性的动词。';

      final promptBundle = engine.buildAnalysisPromptBundle(
        metadata: metadata,
        diaryContent: diaryContent,
        customSystemPrompt: customPrompt,
      );

      // 验证系统提示词中包含用户自定义风格
      expect(promptBundle.systemPrompt, contains(customPrompt));
      // 验证系统提示词中包含不可破坏的单一信源 JSON Schema 字段约束
      expect(promptBundle.systemPrompt, contains(AiContracts.keyNonEnglish));
      expect(promptBundle.systemPrompt, contains(AiContracts.keyIncorrectExpressions));
      expect(promptBundle.systemPrompt, contains(AiContracts.keyOriginalStyleVersion));
      expect(promptBundle.systemPrompt, contains(AiContracts.keyUnnaturalExpressions));
      expect(promptBundle.systemPrompt, contains(AiContracts.keyAuthenticAdvancedVersion));
      expect(promptBundle.systemPrompt, contains(AiContracts.keyExtractedCorpus));

      // 验证用户提示词中包含日记元数据与正文
      expect(promptBundle.userMessage, contains('2026-10-10'));
      expect(promptBundle.userMessage, contains('下雨'));
      expect(promptBundle.userMessage, contains(diaryContent));
    });

    test('should assemble inquiry prompt preserving full context and strict inquiry schema', () {
      const diaryContent = 'Today work overtime until 9pm.';
      const analysisContext = '{"originalStyleEnglishVersion": "I worked late until 9pm."}';
      const userQuestion = '为什么不用 overtime 做动词？';
      const customPrompt = '请简洁回答。';

      final promptBundle = engine.buildInquiryPromptBundle(
        diaryContent: diaryContent,
        analysisContext: analysisContext,
        historyTurns: const [],
        userQuestion: userQuestion,
        customSystemPrompt: customPrompt,
      );

      expect(promptBundle.systemPrompt, contains(customPrompt));
      expect(promptBundle.systemPrompt, contains(AiContracts.keyInquiryReply));
      expect(promptBundle.systemPrompt, contains(AiContracts.keyInquiryKeyTakeaway));
      expect(promptBundle.systemPrompt, contains(AiContracts.keyInquiryExamples));
      expect(promptBundle.systemPrompt, contains(AiContracts.keyExtractedCorpus));

      expect(promptBundle.userMessage, contains(userQuestion));
      expect(promptBundle.userMessage, contains(analysisContext));
    });
  });

  group('Structured Output Parsing Tests (TDD)', () {
    test('should parse complete diary analysis JSON correctly', () {
      final jsonSample = {
        AiContracts.keyNonEnglish: [
          {
            'original': '加班',
            'meaning': 'to work overtime',
            'explanation': '中文常见工作用词',
          }
        ],
        AiContracts.keyIncorrectExpressions: [
          {
            'original': 'Today work overtime until 9pm',
            'correction': 'I worked overtime until 9 PM today',
            'explanation': '缺少主语，且叙述过去发生的事态需使用过去时态。',
          }
        ],
        AiContracts.keyOriginalStyleVersion: 'I worked late until 9 PM today, and it was pouring outside.',
        AiContracts.keyUnnaturalExpressions: [
          {
            'original': 'outside is raining heavily',
            'naturalAlternative': 'it was pouring rain outside',
            'mindsetBridge': '中文习惯先交代地点“外面”，英文更地道使用天气主语 it 或名词性短语。',
          }
        ],
        AiContracts.keyAuthenticAdvancedVersion: 'Clocked out after nine tonight into a relentless downpour.',
        AiContracts.keyExtractedCorpus: [
          {
            'expression': 'clock out',
            'phonetic': '/klɒk aʊt/',
            'meaning': '打卡下班',
            'usageContext': '生动口语动词，比单纯 work overtime 更有生活下班打卡质感。',
          },
          {
            'expression': 'relentless downpour',
            'phonetic': '/rɪˈlentləs ˈdaʊnpɔːr/',
            'meaning': '倾盆大雨，不歇的暴雨',
            'usageContext': '替代简单的 rain heavily，文学画面感极强。',
          }
        ],
      };

      final result = DiaryAnalysisResult.fromJson(jsonSample);

      expect(result.nonEnglishItems.length, 1);
      expect(result.nonEnglishItems.first.original, '加班');
      expect(result.incorrectExpressions.first.correction, 'I worked overtime until 9 PM today');
      expect(result.originalStyleEnglishVersion, contains('I worked late'));
      expect(result.unnaturalExpressions.first.naturalAlternative, 'it was pouring rain outside');
      expect(result.authenticAdvancedVersion, contains('relentless downpour'));
      expect(result.extractedCorpus.length, 2);
      expect(result.extractedCorpus.first.expression, 'clock out');
    });

    test('should parse inquiry JSON response correctly', () {
      final inquiryJson = {
        AiContracts.keyInquiryReply: 'overtime 在现代英语中通常作副词或名词使用，作动词显得生硬。',
        AiContracts.keyInquiryKeyTakeaway: '表达“加班”更常用 work overtime 或 clock extra hours。',
        AiContracts.keyInquiryExamples: [
          'I had to work overtime yesterday.',
          'They put in two hours of overtime.'
        ],
        AiContracts.keyExtractedCorpus: [
          {
            'expression': 'put in overtime',
            'phonetic': '/pʊt ɪn ˈoʊvərtaɪm/',
            'meaning': '投入加班时间',
            'usageContext': '常见职场地道搭配',
          }
        ],
      };

      final response = InquiryStructuredResponse.fromJson(inquiryJson);

      expect(response.reply, contains('overtime 在现代英语中'));
      expect(response.keyTakeaway, contains('work overtime'));
      expect(response.examples.length, 2);
      expect(response.extractedCorpus.length, 1);
      expect(response.extractedCorpus.first.expression, 'put in overtime');
    });
  });
}
