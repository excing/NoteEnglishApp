import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:note_english_flutter/application/editorial/diary_editorial_cubit.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/models/analysis/diary_analysis_result.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_draft.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';
import 'package:note_english_flutter/domain/services/corpus_ingestion_service.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';

import 'package:note_english_flutter/domain/gateways/weather_gateway.dart';
import 'package:note_english_flutter/domain/models/weather/current_weather_report.dart';

class MockDiaryRepository extends Mock implements IDiaryRepository {}
class MockCorpusRepository extends Mock implements ICorpusRepository {}
class MockAiConfigRepository extends Mock implements IAiConfigRepository {}
class MockAiGateway extends Mock implements IAiGateway {}
class MockWeatherGateway extends Mock implements IWeatherGateway {}

void main() {
  late MockDiaryRepository diaryRepo;
  late MockCorpusRepository corpusRepo;
  late MockAiConfigRepository configRepo;
  late MockAiGateway aiGateway;

  setUpAll(() {
    registerFallbackValue(const PromptBundle(systemPrompt: '', userMessage: ''));
    registerFallbackValue(const AiProfileConfig());
    registerFallbackValue(DiaryEntry.create(
      content: '',
      metadata: DiaryMetadata(recordedAt: DateTime.now()),
    ));
  });

  setUp(() {
    diaryRepo = MockDiaryRepository();
    corpusRepo = MockCorpusRepository();
    configRepo = MockAiConfigRepository();
    aiGateway = MockAiGateway();
  });

  group('DiaryEditorialCubit Tests (TDD)', () {
    final initialEntry = DiaryEntry.create(
      content: 'Today work overtime until 9pm.',
      metadata: DiaryMetadata(
        recordedAt: DateTime(2026, 10, 10, 21, 30),
        weather: WeatherCondition.rainy,
        wordCount: 6,
      ),
    );

    const mockAnalysis = DiaryAnalysisResult(
      originalStyleEnglishVersion: 'I worked overtime until 9pm today.',
      authenticAdvancedVersion: 'Clocked out after nine into the rain.',
      extractedCorpus: [
        CorpusItemDraft(
          expression: 'clock out',
          phonetic: '/klɒk aʊt/',
          meaning: '打卡下班',
          usageContext: '生动职场口语',
        )
      ],
    );

    blocTest<DiaryEditorialCubit, DiaryEditorialState>(
      'should analyze diary and automatically ingest extracted corpus into corpus repository',
      setUp: () {
        when(() => configRepo.getConfig()).thenAnswer(
          (_) async => const AiProfileConfig(apiKey: 'key', baseUrl: 'https://api.test.com'),
        );
        when(() => aiGateway.analyzeDiary(
              promptBundle: any(named: 'promptBundle'),
              config: any(named: 'config'),
            )).thenAnswer((_) async => mockAnalysis);
        when(() => corpusRepo.getExistingExpressions())
            .thenAnswer((_) async => <String>{});
        when(() => corpusRepo.saveBatch(any())).thenAnswer((_) async {});
        when(() => diaryRepo.saveEntry(any())).thenAnswer((_) async {});
      },
      build: () => DiaryEditorialCubit(
        diaryRepository: diaryRepo,
        corpusRepository: corpusRepo,
        configRepository: configRepo,
        aiGateway: aiGateway,
        promptEngine: const PromptTemplateEngine(),
        corpusService: const CorpusIngestionService(),
        initialEntry: initialEntry,
      ),
      act: (cubit) => cubit.requestAiAnalysis(),
      expect: () => [
        isA<DiaryEditorialState>().having(
          (s) => s.status,
          'status',
          DiaryAnalysisStatus.analyzing,
        ),
        isA<DiaryEditorialState>()
            .having((s) => s.status, 'status', DiaryAnalysisStatus.completed)
            .having(
              (s) => s.entry.analysisResult?.authenticAdvancedVersion,
              'advancedVersion',
              contains('Clocked out'),
            )
            .having((s) => s.silentCorpusCount, 'silentCorpusCount', 1),
      ],
      verify: (_) {
        // 验证语料库自动批量保存被触发了
        verify(() => corpusRepo.saveBatch(any())).called(1);
        verify(() => diaryRepo.saveEntry(any())).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<DiaryEditorialCubit, DiaryEditorialState>(
      'should emit failed and clear message when config is not configured',
      setUp: () {
        when(() => configRepo.getConfig()).thenAnswer(
          (_) async => const AiProfileConfig(apiKey: '', baseUrl: ''),
        );
      },
      build: () => DiaryEditorialCubit(
        diaryRepository: diaryRepo,
        corpusRepository: corpusRepo,
        configRepository: configRepo,
        aiGateway: aiGateway,
        promptEngine: const PromptTemplateEngine(),
        corpusService: const CorpusIngestionService(),
        initialEntry: initialEntry,
      ),
      act: (cubit) => cubit.requestAiAnalysis(),
      expect: () => [
        isA<DiaryEditorialState>().having(
          (s) => s.status,
          'status',
          DiaryAnalysisStatus.analyzing,
        ),
        isA<DiaryEditorialState>()
          ..having((s) => s.status, 'status', DiaryAnalysisStatus.failed)
          ..having(
            (s) => s.errorMessage,
            'errorMessage',
            contains('尚未配置 AI 接口'),
          ),
      ],
      verify: (_) {
        verifyNever(() => aiGateway.analyzeDiary(
              promptBundle: any(named: 'promptBundle'),
              config: any(named: 'config'),
            ));
      },
    );

    blocTest<DiaryEditorialCubit, DiaryEditorialState>(
      'should switch and load new entry state when loadEntry is called',
      build: () => DiaryEditorialCubit(
        diaryRepository: diaryRepo,
        corpusRepository: corpusRepo,
        configRepository: configRepo,
        aiGateway: aiGateway,
        initialEntry: initialEntry,
      ),
      act: (cubit) {
        final newEntry = DiaryEntry.create(
          content: 'Brand new loaded note.',
          metadata: DiaryMetadata(
            recordedAt: DateTime(2026, 10, 12, 10, 0),
            weather: WeatherCondition.sunny,
            wordCount: 4,
          ),
        );
        cubit.loadEntry(newEntry);
      },
      expect: () => [
        isA<DiaryEditorialState>()
            .having((s) => s.entry.content, 'content', 'Brand new loaded note.')
            .having((s) => s.status, 'status', DiaryAnalysisStatus.draft),
      ],
    );

    blocTest<DiaryEditorialCubit, DiaryEditorialState>(
      'should fetch and apply realtime weather from weather gateway',
      setUp: () {
        when(() => diaryRepo.saveEntry(any())).thenAnswer((_) async {});
      },
      build: () {
        final weatherGateway = MockWeatherGateway();
        when(() => weatherGateway.fetchWeatherByCity('Shanghai')).thenAnswer(
          (_) async => CurrentWeatherReport(
            condition: WeatherCondition.sunny,
            temperature: 24.5,
            weatherCode: 0,
            locationName: 'Shanghai',
            latitude: 31.23,
            longitude: 121.47,
            fetchedAt: DateTime.now(),
          ),
        );
        return DiaryEditorialCubit(
          diaryRepository: diaryRepo,
          corpusRepository: corpusRepo,
          configRepository: configRepo,
          aiGateway: aiGateway,
          weatherGateway: weatherGateway,
          initialEntry: initialEntry,
        );
      },
      act: (cubit) => cubit.fetchAndApplyRealtimeWeather(cityName: 'Shanghai'),
      expect: () => [
        isA<DiaryEditorialState>()
            .having((s) => s.entry.metadata.weather, 'weather', WeatherCondition.sunny)
            .having((s) => s.entry.metadata.location, 'location', 'Shanghai'),
      ],
      verify: (_) {
        verify(() => diaryRepo.saveEntry(any())).called(1);
      },
    );
  });
}
