import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:note_english_flutter/domain/errors/ai_failure.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/gateways/weather_gateway.dart';
import 'package:note_english_flutter/domain/models/analysis/diary_analysis_result.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_draft.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_item.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_source.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/models/weather/current_weather_report.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';
import 'package:note_english_flutter/domain/services/editorial_analysis_service.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';

class MockAiGateway extends Mock implements IAiGateway {}
class MockAiConfigRepository extends Mock implements IAiConfigRepository {}
class MockCorpusRepository extends Mock implements ICorpusRepository {}
class MockDiaryRepository extends Mock implements IDiaryRepository {}
class MockWeatherGateway extends Mock implements IWeatherGateway {}

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
        sourceType: CorpusSourceType.analysis,
        createdAt: DateTime.now(),
      ),
    ));
  });

  group('EditorialAnalysisService Tests (TDD - Unified Single Source of Truth)', () {
    late MockAiGateway mockAiGateway;
    late MockAiConfigRepository mockConfigRepo;
    late MockCorpusRepository mockCorpusRepo;
    late MockDiaryRepository mockDiaryRepo;
    late MockWeatherGateway mockWeatherGateway;
    late EditorialAnalysisService service;

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
      mockWeatherGateway = MockWeatherGateway();

      service = EditorialAnalysisService(
        aiGateway: mockAiGateway,
        configRepository: mockConfigRepo,
        corpusRepository: mockCorpusRepo,
        diaryRepository: mockDiaryRepo,
        weatherGateway: mockWeatherGateway,
      );
    });

    test('should throw FormatException if rawText is blank', () async {
      expect(
        () => service.executeAnalysis(rawText: '   '),
        throwsA(isA<FormatException>()),
      );
      verifyZeroInteractions(mockAiGateway);
    });

    test('should throw AiConfigNotSetFailure if AI config is unconfigured', () async {
      when(() => mockConfigRepo.getConfig()).thenAnswer(
        (_) async => const AiProfileConfig(apiKey: '', baseUrl: '', selectedModel: ''),
      );

      expect(
        () => service.executeAnalysis(rawText: '我们应该处理这个问题'),
        throwsA(isA<AiConfigNotSetFailure>()),
      );
    });

    test('should auto fetch weather when metadata lacks realtime weather, call AI, save entry & corpus', () async {
      when(() => mockConfigRepo.getConfig()).thenAnswer((_) async => validConfig);
      when(() => mockCorpusRepo.getExistingExpressions()).thenAnswer((_) async => {});
      when(() => mockCorpusRepo.saveBatch(any())).thenAnswer((_) async {});
      when(() => mockDiaryRepo.saveEntry(any())).thenAnswer((_) async {});

      when(() => mockWeatherGateway.fetchWeatherAuto()).thenAnswer(
        (_) async => CurrentWeatherReport(
          condition: WeatherCondition.sunny,
          temperature: 26.5,
          apparentTemperature: 27.0,
          relativeHumidity: 60,
          precipitation: 0.0,
          isDay: true,
          weatherCode: 0,
          locationName: 'Shenzhen',
          latitude: 22.54,
          longitude: 114.05,
          fetchedAt: DateTime.now(),
        ),
      );

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

      final result = await service.executeAnalysis(
        rawText: '我们应该立即处理这个问题',
        sourceType: CorpusSourceType.quickPolish,
      );

      // 验证快捷重塑文本
      expect(result.polishedText, 'We should address this issue without delay.');
      expect(result.analysisResult.extractedCorpus.length, 1);
      expect(result.silentCorpusCount, 1);

      // 验证天气获取被触发，且更新写入随笔
      verify(() => mockWeatherGateway.fetchWeatherAuto()).called(1);
      expect(result.entry.metadata.temperature, 26.5);
      expect(result.entry.metadata.location, 'Shenzhen');
      expect(result.entry.status, DiaryAnalysisStatus.completed);

      // 验证随笔入库存盘
      verify(() => mockDiaryRepo.saveEntry(any())).called(greaterThanOrEqualTo(1));

      // 验证语料入库
      verify(() => mockCorpusRepo.saveBatch(any())).called(1);
    });

    test('should NOT fetch weather again if existingEntry already hasRealtimeWeather', () async {
      when(() => mockConfigRepo.getConfig()).thenAnswer((_) async => validConfig);
      when(() => mockCorpusRepo.getExistingExpressions()).thenAnswer((_) async => {});
      when(() => mockCorpusRepo.saveBatch(any())).thenAnswer((_) async {});
      when(() => mockDiaryRepo.saveEntry(any())).thenAnswer((_) async {});

      const expectedAnalysis = DiaryAnalysisResult(
        originalStyleEnglishVersion: 'Hello.',
        authenticAdvancedVersion: 'Greetings.',
        extractedCorpus: [],
      );

      when(() => mockAiGateway.analyzeDiary(
            promptBundle: any(named: 'promptBundle'),
            config: any(named: 'config'),
          )).thenAnswer((_) async => expectedAnalysis);

      final existingEntry = DiaryEntry.create(
        content: 'Hello',
        metadata: DiaryMetadata(
          recordedAt: DateTime.now(),
          temperature: 20.0,
          location: 'Beijing',
        ),
      );

      final result = await service.executeAnalysis(
        rawText: 'Hello',
        existingEntry: existingEntry,
      );

      expect(result.polishedText, 'Greetings.');
      verifyZeroInteractions(mockWeatherGateway);
    });
  });
}
