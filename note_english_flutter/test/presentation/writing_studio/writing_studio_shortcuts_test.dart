import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:note_english_flutter/app/service_locator.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/gateways/weather_gateway.dart';
import 'package:note_english_flutter/domain/models/analysis/diary_analysis_result.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';
import 'package:note_english_flutter/infrastructure/repositories/local_corpus_repository.dart';
import 'package:note_english_flutter/infrastructure/repositories/local_diary_repository.dart';
import 'package:note_english_flutter/infrastructure/repositories/secure_ai_config_repository.dart';
import 'package:note_english_flutter/main.dart';
import 'package:note_english_flutter/presentation/modules/corpus_deck/corpus_deck_page.dart';
import 'package:note_english_flutter/presentation/modules/editorial_inspector/editorial_inspector_view.dart';
import 'package:note_english_flutter/presentation/modules/settings_studio/ai_settings_dialog.dart';

class MockAiGateway extends Mock implements IAiGateway {}
class MockWeatherGateway extends Mock implements IWeatherGateway {}

void main() {
  late MockAiGateway mockAiGateway;
  late MockWeatherGateway mockWeatherGateway;
  late IDiaryRepository diaryRepo;
  late ICorpusRepository corpusRepo;
  late IAiConfigRepository configRepo;

  final testEntry = DiaryEntry.create(
    content: 'Reviewing shortcuts and productivity in writing.',
    metadata: DiaryMetadata(
      recordedAt: DateTime(2026, 10, 13, 15, 0),
      weather: WeatherCondition.sunny,
      wordCount: 7,
    ),
  );

  const mockAnalysis = DiaryAnalysisResult(
    nonEnglishItems: [],
    incorrectExpressions: [],
    originalStyleEnglishVersion: 'Reviewing shortcuts and productivity.',
    unnaturalExpressions: [],
    authenticAdvancedVersion: 'Exploring keyboard shortcuts for peak productivity.',
    extractedCorpus: [],
  );

  setUpAll(() {
    registerFallbackValue(const PromptBundle(systemPrompt: '', userMessage: ''));
    registerFallbackValue(const AiProfileConfig());
  });

  setUp(() async {
    mockAiGateway = MockAiGateway();
    mockWeatherGateway = MockWeatherGateway();
    diaryRepo = LocalDiaryRepository();
    corpusRepo = LocalCorpusRepository();
    configRepo = SecureAiConfigRepository();

    await configRepo.saveConfig(const AiProfileConfig(
      baseUrl: 'https://api.openai.com/v1',
      apiKey: 'test-key',
    ));
    await diaryRepo.saveEntry(testEntry);

    await sl.reset();
    sl.registerLazySingleton<PromptTemplateEngine>(() => const PromptTemplateEngine());
    sl.registerLazySingleton<IDiaryRepository>(() => diaryRepo);
    sl.registerLazySingleton<ICorpusRepository>(() => corpusRepo);
    sl.registerLazySingleton<IAiConfigRepository>(() => configRepo);
    sl.registerLazySingleton<IAiGateway>(() => mockAiGateway);
    sl.registerLazySingleton<IWeatherGateway>(() => mockWeatherGateway);

    when(() => mockAiGateway.analyzeDiary(
          promptBundle: any(named: 'promptBundle'),
          config: any(named: 'config'),
        )).thenAnswer((_) async => mockAnalysis);
  });

  group('快捷键系统全量验证 (Keyboard Shortcuts & Productivity)', () {
    testWidgets('Cmd/Ctrl + B 以及 Cmd/Ctrl + [: 快捷切换左边栏展开与收起',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(NoteEnglishApp(initialEntry: testEntry));
      await tester.pumpAndSettle();

      // 默认左边栏展开
      expect(find.text('OtterJot'), findsOneWidget);

      // 聚焦主编辑区输入框以接收键盘快捷键
      await tester.tap(find.byKey(const ValueKey('diary_input_field')));
      await tester.pump();

      // 按下 Cmd/Ctrl + B 收起左边栏
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();

      // 验证收起滑出
      expect(find.text('OtterJot'), findsNothing);

      // 按下 Cmd/Ctrl + [ 重新展开左边栏
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();

      // 验证重新滑入展开
      expect(find.text('OtterJot'), findsOneWidget);

      // 按下 Cmd/Ctrl + \ 再次收起左边栏
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.backslash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();
      expect(find.text('OtterJot'), findsNothing);

      // 按下 Cmd/Ctrl + Shift + L 再次展开左边栏
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();
      expect(find.text('OtterJot'), findsOneWidget);
    });

    testWidgets('非桌面端 (平板/分屏宽度 800px) 下 Cmd/Ctrl + B 快捷打开与收起侧边栏抽屉',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(NoteEnglishApp(initialEntry: testEntry));
      await tester.pumpAndSettle();

      // 非桌面端默认抽屉未打开
      expect(find.text('OtterJot'), findsNothing);

      // 按下 Cmd + B 快捷呼出抽屉
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();

      // 验证抽屉已打开且呈现“OtterJot”
      expect(find.text('OtterJot'), findsOneWidget);

      // 再次按下 Cmd + B 快捷关闭抽屉
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();

      // 验证抽屉已关闭
      expect(find.text('OtterJot'), findsNothing);
    });

    testWidgets('Cmd/Ctrl + J 以及 Cmd/Ctrl + ]: 快捷切换右边栏 (AI 视窗) 展开与收起',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(NoteEnglishApp(initialEntry: testEntry));
      await tester.pumpAndSettle();

      // 默认右边栏收起
      expect(find.byType(EditorialInspectorView), findsNothing);

      // 按下 Cmd + J 展开右边栏
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();

      // 验证右侧 AI 视窗已展开
      expect(find.byKey(const ValueKey('right_pane_resize_handle')), findsOneWidget);

      // 按下 Cmd + ] 再次收起右边栏
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.bracketRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();

      // 验证右侧 AI 视窗已收起
      expect(find.byType(EditorialInspectorView), findsNothing);
    });

    testWidgets('Cmd/Ctrl + N: 快捷新建随笔',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(NoteEnglishApp(initialEntry: testEntry));
      await tester.pumpAndSettle();

      final inputFinder = find.byKey(const ValueKey('diary_input_field'));
      expect(inputFinder, findsOneWidget);

      // 验证当前编辑稿纸内容为初始随笔
      final initialEditable = tester.widget<TextField>(inputFinder);
      expect(initialEditable.controller?.text,
          equals('Reviewing shortcuts and productivity in writing.'));

      // 点击输入框确保获焦
      await tester.tap(inputFinder);
      await tester.pump();

      // 按下 Cmd/Ctrl + N 快捷新建随笔
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();

      // 验证已创建新随笔，且输入框清空为新草稿
      final freshEditable = tester.widget<TextField>(inputFinder);
      expect(freshEditable.controller?.text, isEmpty);
    });

    testWidgets('Cmd/Ctrl + Enter: 呼叫主编梳理',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(NoteEnglishApp(initialEntry: testEntry));
      await tester.pumpAndSettle();

      // 按下 Cmd + Enter
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pump();
      await tester.pumpAndSettle();

      // 验证 AI 分析已触发且呈现润色重塑卡片
      verify(() => mockAiGateway.analyzeDiary(
            promptBundle: any(named: 'promptBundle'),
            config: any(named: 'config'),
          )).called(1);
      expect(find.byType(EditorialInspectorView), findsOneWidget);
    });

    testWidgets('Cmd/Ctrl + K: 快捷打开语料库页面',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(NoteEnglishApp(initialEntry: testEntry));
      await tester.pumpAndSettle();

      expect(find.byType(CorpusDeckPage), findsNothing);

      // 按下 Cmd + K
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();

      // 验证跳转至语料库页面
      expect(find.byType(CorpusDeckPage), findsOneWidget);
    });

    testWidgets('Cmd/Ctrl + ,: 快捷打开主编设置弹窗',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(NoteEnglishApp(initialEntry: testEntry));
      await tester.pumpAndSettle();

      expect(find.byType(AiSettingsDialog), findsNothing);

      // 按下 Cmd + ,
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.comma);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();

      // 验证弹出设置对话框
      expect(find.byType(AiSettingsDialog), findsOneWidget);
    });
  });
}
