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
    DiaryEditorialCubit.lastUserSelectedLocation = null;
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
            .having((s) => s.status, 'status', DiaryAnalysisStatus.failed)
            .having(
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
      'should fetch and apply realtime weather by explicitly given cityName',
      setUp: () {
        when(() => diaryRepo.saveEntry(any())).thenAnswer((_) async {});
      },
      build: () {
        final weatherGateway = MockWeatherGateway();
        when(() => weatherGateway.fetchWeatherByCity('Shanghai')).thenAnswer(
          (_) async => CurrentWeatherReport(
            condition: WeatherCondition.sunny,
            temperature: 24.5,
            apparentTemperature: 23.8,
            relativeHumidity: 50,
            precipitation: 0.0,
            isDay: true,
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
            .having((s) => s.entry.metadata.location, 'location', 'Shanghai')
            .having((s) => s.entry.metadata.temperature, 'temperature', 24.5)
            .having((s) => s.entry.metadata.apparentTemperature, 'apparentTemperature', 23.8)
            .having((s) => s.entry.metadata.humidity, 'humidity', 50)
            .having((s) => s.entry.metadata.isDay, 'isDay', isTrue),
      ],
      verify: (_) {
        verify(() => diaryRepo.saveEntry(any())).called(1);
      },
    );

    blocTest<DiaryEditorialCubit, DiaryEditorialState>(
      '原本选择的位置，再点“自动获取实时天气”时必须保持该位置，绝不变成默认北京',
      setUp: () {
        when(() => diaryRepo.saveEntry(any())).thenAnswer((_) async {});
      },
      build: () {
        final weatherGateway = MockWeatherGateway();
        // 模拟已存在位置为 'Shenzhen' 的随笔
        final entryWithLocation = initialEntry.copyWith(
          metadata: initialEntry.metadata.copyWith(
            location: 'Shenzhen',
          ),
        );
        when(() => weatherGateway.fetchWeatherByCity('Shenzhen')).thenAnswer(
          (_) async => CurrentWeatherReport(
            condition: WeatherCondition.cloudy,
            temperature: 26.0,
            apparentTemperature: 27.2,
            relativeHumidity: 65,
            precipitation: 0.0,
            isDay: true,
            weatherCode: 2,
            locationName: 'Shenzhen',
            latitude: 22.54,
            longitude: 114.05,
            fetchedAt: DateTime.now(),
          ),
        );
        return DiaryEditorialCubit(
          diaryRepository: diaryRepo,
          corpusRepository: corpusRepo,
          configRepository: configRepo,
          aiGateway: aiGateway,
          weatherGateway: weatherGateway,
          initialEntry: entryWithLocation,
        );
      },
      // 触发无参的“自动获取实时天气”
      act: (cubit) => cubit.fetchAndApplyRealtimeWeather(),
      expect: () => [
        isA<DiaryEditorialState>()
            .having((s) => s.entry.metadata.location, 'location', 'Shenzhen')
            .having((s) => s.entry.metadata.weather, 'weather', WeatherCondition.cloudy)
            .having((s) => s.entry.metadata.temperature, 'temperature', 26.0),
      ],
      verify: (_) {
        verify(() => diaryRepo.saveEntry(any())).called(1);
      },
    );

    blocTest<DiaryEditorialCubit, DiaryEditorialState>(
      '随笔无位置但用户此前曾输入过位置时，自动获取应优先继承用户输入的最后位置',
      setUp: () {
        when(() => diaryRepo.saveEntry(any())).thenAnswer((_) async {});
      },
      build: () {
        final weatherGateway = MockWeatherGateway();
        // 预设用户此前手动输入了 Tokyo
        DiaryEditorialCubit.lastUserSelectedLocation = 'Tokyo';

        when(() => weatherGateway.fetchWeatherByCity('Tokyo')).thenAnswer(
          (_) async => CurrentWeatherReport(
            condition: WeatherCondition.rainy,
            temperature: 18.0,
            apparentTemperature: 17.5,
            relativeHumidity: 80,
            precipitation: 2.5,
            isDay: true,
            weatherCode: 61,
            locationName: 'Tokyo',
            latitude: 35.68,
            longitude: 139.76,
            fetchedAt: DateTime.now(),
          ),
        );
        // 当前随笔无 location
        final entryWithoutLocation = initialEntry.copyWith(
          metadata: initialEntry.metadata.copyWith(
            location: null,
          ),
        );
        return DiaryEditorialCubit(
          diaryRepository: diaryRepo,
          corpusRepository: corpusRepo,
          configRepository: configRepo,
          aiGateway: aiGateway,
          weatherGateway: weatherGateway,
          initialEntry: entryWithoutLocation,
        );
      },
      act: (cubit) => cubit.fetchAndApplyRealtimeWeather(),
      expect: () => [
        isA<DiaryEditorialState>()
            .having((s) => s.entry.metadata.location, 'location', 'Tokyo')
            .having((s) => s.entry.metadata.weather, 'weather', WeatherCondition.rainy),
      ],
      verify: (_) {
        verify(() => diaryRepo.saveEntry(any())).called(1);
      },
    );

    blocTest<DiaryEditorialCubit, DiaryEditorialState>(
      '呼叫主编梳理时，若尚未获取过天气，应自动获取一次实时天气再进行梳理',
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
      build: () {
        final weatherGateway = MockWeatherGateway();
        // 随笔初始没有实时天气数据 (temperature == null)
        final entryWithoutWeather = initialEntry.copyWith(
          metadata: initialEntry.metadata.copyWith(
            temperature: null,
            location: null,
          ),
        );
        when(() => weatherGateway.fetchWeatherAuto()).thenAnswer(
          (_) async => CurrentWeatherReport(
            condition: WeatherCondition.thunderstorm,
            temperature: 28.0,
            apparentTemperature: 30.0,
            relativeHumidity: 88,
            precipitation: 15.0,
            isDay: true,
            weatherCode: 95,
            locationName: 'Guangzhou',
            latitude: 23.13,
            longitude: 113.26,
            fetchedAt: DateTime.now(),
          ),
        );
        return DiaryEditorialCubit(
          diaryRepository: diaryRepo,
          corpusRepository: corpusRepo,
          configRepository: configRepo,
          aiGateway: aiGateway,
          weatherGateway: weatherGateway,
          promptEngine: const PromptTemplateEngine(),
          corpusService: const CorpusIngestionService(),
          initialEntry: entryWithoutWeather,
        );
      },
      act: (cubit) => cubit.requestAiAnalysis(),
      expect: () => [
        isA<DiaryEditorialState>().having(
          (s) => s.status,
          'status',
          DiaryAnalysisStatus.analyzing,
        ),
        // 最终状态：统一服务执行完成后进入 completed，且元数据中包含自动补齐的天气与位置信息
        isA<DiaryEditorialState>()
            .having((s) => s.status, 'status', DiaryAnalysisStatus.completed)
            .having((s) => s.entry.metadata.weather, 'weather', WeatherCondition.thunderstorm)
            .having((s) => s.entry.metadata.location, 'location', 'Guangzhou')
            .having((s) => s.entry.metadata.temperature, 'temperature', 28.0),
      ],
      verify: (cubit) {
        verify(() => cubit.weatherGateway?.fetchWeatherAuto()).called(1);
        verify(() => aiGateway.analyzeDiary(
              promptBundle: any(
                named: 'promptBundle',
                that: isA<PromptBundle>().having(
                  (p) => p.userMessage,
                  'userMessage',
                  contains('Guangzhou'),
                ),
              ),
              config: any(named: 'config'),
            )).called(1);
      },
    );

    blocTest<DiaryEditorialCubit, DiaryEditorialState>(
      '呼叫主编梳理时，若随笔已获取过实时天气，不应重复请求天气网关',
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
      build: () {
        final weatherGateway = MockWeatherGateway();
        // 随笔初始已有实时天气数据 (temperature != null)
        final entryWithWeather = initialEntry.copyWith(
          metadata: initialEntry.metadata.copyWith(
            temperature: 20.0,
            location: 'Beijing',
          ),
        );
        return DiaryEditorialCubit(
          diaryRepository: diaryRepo,
          corpusRepository: corpusRepo,
          configRepository: configRepo,
          aiGateway: aiGateway,
          weatherGateway: weatherGateway,
          promptEngine: const PromptTemplateEngine(),
          corpusService: const CorpusIngestionService(),
          initialEntry: entryWithWeather,
        );
      },
      act: (cubit) => cubit.requestAiAnalysis(),
      expect: () => [
        isA<DiaryEditorialState>().having(
          (s) => s.status,
          'status',
          DiaryAnalysisStatus.analyzing,
        ),
        isA<DiaryEditorialState>()
            .having((s) => s.status, 'status', DiaryAnalysisStatus.completed),
      ],
      verify: (cubit) {
        verifyNever(() => cubit.weatherGateway?.fetchWeatherAuto());
        verifyNever(() => cubit.weatherGateway?.fetchWeatherByCity(any()));
      },
    );

    blocTest<DiaryEditorialCubit, DiaryEditorialState>(
      '呼叫主编梳理时，自动获取天气若失败，应静默降级并不阻断 AI 主编梳理',
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
      build: () {
        final weatherGateway = MockWeatherGateway();
        final entryWithoutWeather = initialEntry.copyWith(
          metadata: initialEntry.metadata.copyWith(
            temperature: null,
          ),
        );
        when(() => weatherGateway.fetchWeatherAuto())
            .thenThrow(Exception('Network error during weather fetch'));
        return DiaryEditorialCubit(
          diaryRepository: diaryRepo,
          corpusRepository: corpusRepo,
          configRepository: configRepo,
          aiGateway: aiGateway,
          weatherGateway: weatherGateway,
          promptEngine: const PromptTemplateEngine(),
          corpusService: const CorpusIngestionService(),
          initialEntry: entryWithoutWeather,
        );
      },
      act: (cubit) => cubit.requestAiAnalysis(),
      expect: () => [
        isA<DiaryEditorialState>().having(
          (s) => s.status,
          'status',
          DiaryAnalysisStatus.analyzing,
        ),
        // 依然顺利完成，状态为 completed
        isA<DiaryEditorialState>()
            .having((s) => s.status, 'status', DiaryAnalysisStatus.completed),
      ],
      verify: (cubit) {
        verify(() => cubit.weatherGateway?.fetchWeatherAuto()).called(1);
        verify(() => aiGateway.analyzeDiary(
              promptBundle: any(named: 'promptBundle'),
              config: any(named: 'config'),
            )).called(1);
      },
    );
  });
}
