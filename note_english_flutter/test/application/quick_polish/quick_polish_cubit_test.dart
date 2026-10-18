import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:note_english_flutter/application/quick_polish/quick_polish_cubit.dart';
import 'package:note_english_flutter/application/quick_polish/quick_polish_state.dart';
import 'package:note_english_flutter/domain/errors/ai_failure.dart';
import 'package:note_english_flutter/domain/gateways/quick_polish_platform_gateway.dart';
import 'package:note_english_flutter/domain/models/analysis/diary_analysis_result.dart';
import 'package:note_english_flutter/domain/models/analysis/editorial_execution_result.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_source.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/services/editorial_analysis_service.dart';
import 'package:note_english_flutter/infrastructure/storage/file_storage_engine.dart';

class MockQuickPolishPlatformGateway extends Mock implements IQuickPolishPlatformGateway {}
class MockEditorialAnalysisService extends Mock implements EditorialAnalysisService {}
class MockStorageEngine extends Mock implements IStorageEngine {}

void main() {
  setUpAll(() {
    registerFallbackValue(CorpusSourceType.quickPolish);
  });

  group('QuickPolishCubit Tests (TDD - Unified EditorialAnalysisService)', () {
    late MockQuickPolishPlatformGateway mockGateway;
    late MockEditorialAnalysisService mockService;
    late MockStorageEngine mockStorage;
    late QuickPolishCubit cubit;
    late QuickPolishTextHandler capturedHandler;

    setUp(() {
      mockGateway = MockQuickPolishPlatformGateway();
      mockService = MockEditorialAnalysisService();
      mockStorage = MockStorageEngine();

      when(() => mockGateway.setQuickPolishHandler(any())).thenAnswer((invocation) {
        capturedHandler = invocation.positionalArguments[0] as QuickPolishTextHandler;
      });
      when(() => mockGateway.initialize()).thenAnswer((_) async {});
      when(() => mockGateway.isAccessibilityGranted()).thenAnswer((_) async => true);
      when(() => mockGateway.setQuickPolishEnabled(any())).thenAnswer((_) async {});
      when(() => mockGateway.requestAccessibilityPermission()).thenAnswer((_) async {});
      when(() => mockGateway.showNotification(
            title: any(named: 'title'),
            body: any(named: 'body'),
          )).thenAnswer((_) async {});

      when(() => mockStorage.readString(any())).thenAnswer((_) async => null);
      when(() => mockStorage.writeString(any(), any())).thenAnswer((_) async {});

      cubit = QuickPolishCubit(
        platformGateway: mockGateway,
        editorialAnalysisService: mockService,
        storageEngine: mockStorage,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is idle and handler is registered with disabled by default', () {
      expect(cubit.state.status, QuickPolishStatus.idle);
      expect(cubit.state.isEnabled, isFalse);
      expect(cubit.state.isAccessibilityGranted, isTrue);
      verify(() => mockGateway.setQuickPolishHandler(any())).called(1);
    });

    test('initialize defaults to disabled when no storage record exists', () async {
      when(() => mockStorage.readString('quick_polish_enabled')).thenAnswer((_) async => null);

      await cubit.initialize();

      expect(cubit.state.isEnabled, isFalse);
      verify(() => mockGateway.initialize()).called(1);
      verify(() => mockGateway.setQuickPolishEnabled(false)).called(1);
      verifyNever(() => mockGateway.isAccessibilityGranted());
    });

    test('initialize loads enabled state when stored value is true', () async {
      when(() => mockStorage.readString('quick_polish_enabled')).thenAnswer((_) async => 'true');

      await cubit.initialize();

      expect(cubit.state.isEnabled, isTrue);
      verify(() => mockGateway.initialize()).called(1);
      verify(() => mockGateway.setQuickPolishEnabled(true)).called(1);
      verify(() => mockGateway.isAccessibilityGranted()).called(1);
    });

    test('toggleEnabled(false) updates state, persists, and notifies gateway', () async {
      await cubit.toggleEnabled(false);

      expect(cubit.state.isEnabled, isFalse);
      verify(() => mockStorage.writeString('quick_polish_enabled', 'false')).called(1);
      verify(() => mockGateway.setQuickPolishEnabled(false)).called(1);

      // When disabled, handling request should immediately return original text without calling service
      final returned = await capturedHandler('hello world');
      expect(returned, 'hello world');
      verifyNever(() => mockService.executeAnalysis(
            rawText: any(named: 'rawText'),
            sourceType: any(named: 'sourceType'),
          ));
    });

    test('toggleEnabled(true) persists and actively triggers accessibility check', () async {
      await cubit.toggleEnabled(false);
      reset(mockGateway);
      when(() => mockGateway.setQuickPolishEnabled(any())).thenAnswer((_) async {});
      when(() => mockGateway.isAccessibilityGranted()).thenAnswer((_) async => false);

      await cubit.toggleEnabled(true);

      expect(cubit.state.isEnabled, isTrue);
      expect(cubit.state.isAccessibilityGranted, isFalse);
      verify(() => mockStorage.writeString('quick_polish_enabled', 'true')).called(1);
      verify(() => mockGateway.setQuickPolishEnabled(true)).called(1);
      verify(() => mockGateway.isAccessibilityGranted()).called(1);
    });

    test('requestAccessibilityPermission delegates to platform gateway', () async {
      await cubit.requestAccessibilityPermission();
      verify(() => mockGateway.requestAccessibilityPermission()).called(1);
    });

    test('openAppInFinder delegates to platform gateway', () async {
      when(() => mockGateway.openAppInFinder()).thenAnswer((_) async {});
      await cubit.openAppInFinder();
      verify(() => mockGateway.openAppInFinder()).called(1);
    });

    test('successful polish transitions through processing to success and returns polished text', () async {
      await cubit.toggleEnabled(true);
      final mockResult = EditorialExecutionResult(
        entry: DiaryEntry.create(
          content: '今天下雨',
          metadata: DiaryMetadata(recordedAt: DateTime.now()),
        ),
        analysisResult: const DiaryAnalysisResult(
          originalStyleEnglishVersion: 'It rains today.',
          authenticAdvancedVersion: 'It is pouring rain today.',
          extractedCorpus: [],
        ),
      );
      when(() => mockService.executeAnalysis(
            rawText: '今天下雨',
            sourceType: CorpusSourceType.quickPolish,
          )).thenAnswer((_) async => mockResult);

      final returnedText = await capturedHandler('今天下雨');

      expect(returnedText, 'It is pouring rain today.');
      expect(cubit.state.status, QuickPolishStatus.success);
      expect(cubit.state.lastResult, mockResult);
      verify(() => mockGateway.showNotification(
            title: 'OtterJot 润色完成',
            body: any(named: 'body'),
          )).called(1);
    });

    test('failure during polish transitions to failure and safely returns original text', () async {
      await cubit.toggleEnabled(true);
      when(() => mockService.executeAnalysis(
            rawText: '测试文本',
            sourceType: CorpusSourceType.quickPolish,
          )).thenThrow(
        const AiConfigNotSetFailure('API Key 未设置'),
      );

      final returnedText = await capturedHandler('测试文本');

      expect(returnedText, '测试文本');
      expect(cubit.state.status, QuickPolishStatus.failure);
      expect(cubit.state.errorMessage, contains('API Key 未设置'));
      verify(() => mockGateway.showNotification(
            title: 'OtterJot 润色提示',
            body: any(named: 'body', that: contains('API Key 未设置')),
          )).called(1);
    });

    test('checks accessibility permission and updates state', () async {
      when(() => mockGateway.isAccessibilityGranted()).thenAnswer((_) async => false);

      await cubit.checkAccessibilityPermission();

      expect(cubit.state.isAccessibilityGranted, isFalse);
    });

    test('relaunchApp delegates to platform gateway', () async {
      when(() => mockGateway.relaunchApp()).thenAnswer((_) async {});

      await cubit.relaunchApp();

      verify(() => mockGateway.relaunchApp()).called(1);
    });
  });
}
