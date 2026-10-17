import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:note_english_flutter/domain/errors/ai_failure.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_draft.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_item.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_source.dart';
import 'package:note_english_flutter/domain/models/quick_polish/quick_polish_result.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';
import 'package:note_english_flutter/domain/services/quick_polish_service.dart';

class MockAiGateway extends Mock implements IAiGateway {}
class MockAiConfigRepository extends Mock implements IAiConfigRepository {}
class MockCorpusRepository extends Mock implements ICorpusRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const PromptBundle(systemPrompt: '', userMessage: ''));
    registerFallbackValue(const AiProfileConfig(
      apiKey: '',
      baseUrl: '',
      selectedModel: '',
    ));
    registerFallbackValue(CorpusItem.create(
      expression: '',
      phonetic: '',
      meaning: '',
      usageContext: '',
      source: CorpusSource(
        diaryId: '',
        sourceSnippet: '',
        sourceType: CorpusSourceType.quickPolish,
        createdAt: DateTime.now(),
      ),
    ));
  });

  group('QuickPolishService Tests (TDD)', () {
    late MockAiGateway mockAiGateway;
    late MockAiConfigRepository mockConfigRepo;
    late MockCorpusRepository mockCorpusRepo;
    late QuickPolishService service;

    const validConfig = AiProfileConfig(
      apiKey: 'sk-test-key-123',
      baseUrl: 'https://api.openai.com/v1',
      selectedModel: 'gpt-4o',
    );

    setUp(() {
      mockAiGateway = MockAiGateway();
      mockConfigRepo = MockAiConfigRepository();
      mockCorpusRepo = MockCorpusRepository();

      service = QuickPolishService(
        aiGateway: mockAiGateway,
        configRepository: mockConfigRepo,
        corpusRepository: mockCorpusRepo,
      );
    });

    test('should return original text immediately if input is blank', () async {
      final result = await service.executeQuickPolish('   ');
      expect(result.originalText, '   ');
      expect(result.polishedText, '   ');
      verifyZeroInteractions(mockAiGateway);
    });

    test('should throw AiConfigNotSetFailure if AI config is unconfigured', () async {
      when(() => mockConfigRepo.getConfig()).thenAnswer(
        (_) async => const AiProfileConfig(apiKey: '', baseUrl: '', selectedModel: ''),
      );

      expect(
        () => service.executeQuickPolish('我们应该处理这个问题'),
        throwsA(isA<AiConfigNotSetFailure>()),
      );
    });

    test('should call AI gateway and silently save extracted corpus', () async {
      when(() => mockConfigRepo.getConfig()).thenAnswer((_) async => validConfig);
      when(() => mockCorpusRepo.getAllCorpus()).thenAnswer((_) async => []);
      when(() => mockCorpusRepo.save(any())).thenAnswer((_) async {});

      const expectedResult = QuickPolishResult(
        originalText: '我们应该立即处理这个问题',
        polishedText: 'We should address this issue without delay.',
        extractedCorpus: [
          CorpusItemDraft(
            expression: 'without delay',
            phonetic: '/wɪˈðaʊt dɪˈleɪ/',
            meaning: '立即、毫不延迟',
            usageContext: '用于商务和正式沟通中替代 immediately',
          ),
        ],
        durationMs: 450,
      );

      when(() => mockAiGateway.quickPolish(
            promptBundle: any(named: 'promptBundle'),
            config: any(named: 'config'),
            originalText: any(named: 'originalText'),
          )).thenAnswer((_) async => expectedResult);

      final result = await service.executeQuickPolish('我们应该立即处理这个问题');

      expect(result.polishedText, 'We should address this issue without delay.');
      expect(result.extractedCorpus.length, 1);
      verify(() => mockCorpusRepo.save(any(that: isA<CorpusItem>()))).called(1);
    });

    test('should not fail quick polish if corpus repo throws error', () async {
      when(() => mockConfigRepo.getConfig()).thenAnswer((_) async => validConfig);
      when(() => mockCorpusRepo.getAllCorpus()).thenThrow(Exception('DB error'));

      const expectedResult = QuickPolishResult(
        originalText: '你好',
        polishedText: 'Hello there.',
        extractedCorpus: [
          CorpusItemDraft(
            expression: 'Hello there',
            phonetic: '',
            meaning: '你好',
            usageContext: '',
          ),
        ],
      );

      when(() => mockAiGateway.quickPolish(
            promptBundle: any(named: 'promptBundle'),
            config: any(named: 'config'),
            originalText: any(named: 'originalText'),
          )).thenAnswer((_) async => expectedResult);

      final result = await service.executeQuickPolish('你好');
      expect(result.polishedText, 'Hello there.');
    });
  });
}
