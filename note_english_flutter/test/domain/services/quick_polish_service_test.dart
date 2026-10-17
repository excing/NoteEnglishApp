import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:note_english_flutter/domain/errors/ai_failure.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_draft.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_item.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_source.dart';
import 'package:note_english_flutter/domain/models/analysis/diary_analysis_result.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';
import 'package:note_english_flutter/domain/services/quick_polish_service.dart';

class MockAiGateway extends Mock implements IAiGateway {}
class MockAiConfigRepository extends Mock implements IAiConfigRepository {}
class MockCorpusRepository extends Mock implements ICorpusRepository {}
class MockDiaryRepository extends Mock implements IDiaryRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const PromptBundle(systemPrompt: '', userMessage: ''));
    registerFallbackValue(const AiProfileConfig(
      apiKey: '',
      baseUrl: '',
      selectedModel: '',
    ));
    registerFallbackValue(DiaryEntry.create(
      content: '',
      metadata: DiaryMetadata(recordedAt: DateTime.now()),
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
    late MockDiaryRepository mockDiaryRepo;
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
      mockDiaryRepo = MockDiaryRepository();

      service = QuickPolishService(
        aiGateway: mockAiGateway,
        configRepository: mockConfigRepo,
        corpusRepository: mockCorpusRepo,
        diaryRepository: mockDiaryRepo,
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

    test('should call AI gateway analyzeDiary, save diary entry to diaryRepo, and silently save extracted corpus', () async {
      when(() => mockConfigRepo.getConfig()).thenAnswer((_) async => validConfig);
      when(() => mockCorpusRepo.getExistingExpressions()).thenAnswer((_) async => {});
      when(() => mockCorpusRepo.saveBatch(any())).thenAnswer((_) async {});
      when(() => mockDiaryRepo.saveEntry(any())).thenAnswer((_) async {});

      const expectedAnalysis = DiaryAnalysisResult(
        originalStyleEnglishVersion: 'We should solve this problem immediately.',
        authenticAdvancedVersion: 'We should address this issue without delay.',
        extractedCorpus: [
          CorpusItemDraft(
            expression: 'without delay',
            phonetic: '/wɪˈðaʊt dɪˈleɪ/',
            meaning: '立即、毫不延迟',
            usageContext: '用于商务和正式沟通中替代 immediately',
          ),
        ],
      );

      when(() => mockAiGateway.analyzeDiary(
            promptBundle: any(named: 'promptBundle'),
            config: any(named: 'config'),
          )).thenAnswer((_) async => expectedAnalysis);

      final result = await service.executeQuickPolish('我们应该立即处理这个问题');

      expect(result.polishedText, 'We should address this issue without delay.');
      expect(result.extractedCorpus.length, 1);

      // 验证已自动落库保存为日记条目，供日记列表实时展示
      final capturedEntry = verify(() => mockDiaryRepo.saveEntry(captureAny())).captured.first as DiaryEntry;
      expect(capturedEntry.content, '我们应该立即处理这个问题');
      expect(capturedEntry.status, DiaryAnalysisStatus.completed);
      expect(capturedEntry.analysisResult?.authenticAdvancedVersion, 'We should address this issue without delay.');

      // 验证语料库同步批量入库
      verify(() => mockCorpusRepo.saveBatch(any(that: isNotEmpty))).called(1);
    });

    test('should not fail quick polish if diary repo or corpus repo throws error', () async {
      when(() => mockConfigRepo.getConfig()).thenAnswer((_) async => validConfig);
      when(() => mockCorpusRepo.getExistingExpressions()).thenThrow(Exception('DB error'));
      when(() => mockDiaryRepo.saveEntry(any())).thenThrow(Exception('Disk full'));

      const expectedAnalysis = DiaryAnalysisResult(
        originalStyleEnglishVersion: 'Hello there.',
        authenticAdvancedVersion: 'Hello there, how are you?',
        extractedCorpus: [
          CorpusItemDraft(
            expression: 'Hello there',
            phonetic: '',
            meaning: '你好',
            usageContext: '',
          ),
        ],
      );

      when(() => mockAiGateway.analyzeDiary(
            promptBundle: any(named: 'promptBundle'),
            config: any(named: 'config'),
          )).thenAnswer((_) async => expectedAnalysis);

      final result = await service.executeQuickPolish('你好');
      expect(result.polishedText, 'Hello there, how are you?');
    });
  });
}
