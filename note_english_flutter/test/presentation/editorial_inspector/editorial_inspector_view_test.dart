import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:note_english_flutter/application/inquiry/inquiry_cubit.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/domain/errors/ai_failure.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';
import 'package:note_english_flutter/domain/models/analysis/diary_analysis_result.dart';
import 'package:note_english_flutter/domain/models/analysis/translation_item.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_draft.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_item.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/models/inquiry/inquiry_response.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';
import 'package:note_english_flutter/presentation/modules/editorial_inspector/editorial_inspector_view.dart';

class MockDiaryRepository extends Mock implements IDiaryRepository {}
class MockCorpusRepository extends Mock implements ICorpusRepository {}
class MockAiConfigRepository extends Mock implements IAiConfigRepository {}
class MockAiGateway extends Mock implements IAiGateway {}

void main() {
  late MockDiaryRepository diaryRepo;
  late MockCorpusRepository corpusRepo;
  late MockAiConfigRepository configRepo;
  late MockAiGateway aiGateway;
  late InquiryCubit inquiryCubit;

  final sampleEntry = DiaryEntry.create(
    content: 'Today is rainy day.',
    metadata: DiaryMetadata(
      recordedAt: DateTime(2026, 10, 11),
      weather: WeatherCondition.rainy,
      wordCount: 4,
    ),
  );

  const sampleAnalysis = DiaryAnalysisResult(
    originalStyleEnglishVersion: 'It was a rainy day today.',
    authenticAdvancedVersion: 'A drizzly afternoon washed over the city.',
  );

  setUpAll(() {
    registerFallbackValue(const PromptBundle(systemPrompt: '', userMessage: ''));
    registerFallbackValue(const AiProfileConfig());
    registerFallbackValue(sampleEntry);
    registerFallbackValue(<CorpusItem>[]);
  });

  setUp(() {
    diaryRepo = MockDiaryRepository();
    corpusRepo = MockCorpusRepository();
    configRepo = MockAiConfigRepository();
    aiGateway = MockAiGateway();

    when(() => configRepo.getConfig()).thenAnswer(
      (_) async => const AiProfileConfig(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'test-key',
        selectedModel: 'gpt-4o',
      ),
    );
    when(() => corpusRepo.getExistingExpressions()).thenAnswer((_) async => {});
    when(() => corpusRepo.saveBatch(any())).thenAnswer((_) async {});
    when(() => diaryRepo.saveEntry(any())).thenAnswer((_) async {});

    inquiryCubit = InquiryCubit(
      diaryRepository: diaryRepo,
      corpusRepository: corpusRepo,
      configRepository: configRepo,
      aiGateway: aiGateway,
    );
  });

  tearDown(() {
    inquiryCubit.close();
  });

  testWidgets('EditorialInspectorView should display sticky bottom inquiry input and submit directly in-place',
      (WidgetTester tester) async {
    const mockResp = InquiryStructuredResponse(
      reply: '这里的 drizzle 能够生动传达细雨蒙蒙的意境。',
      keyTakeaway: '用具体天气微动词替代通用的 rain。',
      examples: ['It drizzled throughout the morning.'],
      extractedCorpus: [
        CorpusItemDraft(
          expression: 'drizzly afternoon',
          phonetic: '/ˈdrɪzli ˌɑːftəˈnuːn/',
          meaning: '细雨蒙蒙的午后',
          usageContext: '用于天气场景的生动微表达',
        ),
      ],
    );

    when(() => aiGateway.inquire(
          promptBundle: any(named: 'promptBundle'),
          config: any(named: 'config'),
        )).thenAnswer((_) async => mockResp);

    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeTokens.createThemeData(isDark: false),
        home: Scaffold(
          body: BlocProvider.value(
            value: inquiryCubit,
            child: EditorialInspectorView(
              analysisResult: sampleAnalysis,
              currentEntry: sampleEntry,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. 验证梳理结果卡片呈现
    expect(find.text('纽约客式温和润色与重塑'), findsOneWidget);
    expect(find.text('原文风格的英文版本 (保留你的本真口吻)'), findsOneWidget);

    // 2. 验证新交互：追问输入框直接置底存在，无需点击打开新界面
    final inputFinder = find.byKey(const ValueKey('inquiry_input_field'));
    final buttonFinder = find.byKey(const ValueKey('send_inquiry_button'));
    expect(inputFinder, findsOneWidget);
    expect(buttonFinder, findsOneWidget);

    // 3. 在置底输入框直接输入并发送
    await tester.enterText(inputFinder, 'drizzle 和 rain 有什么语感区别？');
    await tester.pumpAndSettle();

    await tester.tap(buttonFinder);
    await tester.pump(); // 进入 loading
    await tester.pumpAndSettle(); // 回答完成

    // 4. 验证输入框被自动清空
    final textField = tester.widget<TextField>(inputFinder);
    expect(textField.controller?.text, isEmpty);
    expect(inquiryCubit.state.errorMessage, isNull);
    expect(inquiryCubit.state.history.length, 1);

    // 5. 验证追问的结构化解答直接呈现在同一梳理视图内
    expect(find.textContaining('这里的 drizzle 能够生动传达细雨蒙蒙的意境'), findsOneWidget);
    expect(find.textContaining('核心重点:'), findsOneWidget);
    expect(find.textContaining('用具体天气微动词替代通用的 rain'), findsOneWidget);
    expect(find.textContaining('It drizzled throughout the morning.'), findsOneWidget);
    expect(find.textContaining('已收录: drizzly afternoon'), findsOneWidget);
  });

  testWidgets('EditorialInspectorView handles long non-English items without overflow under narrow width',
      (WidgetTester tester) async {
    const analysisWithLongItems = DiaryAnalysisResult(
      originalStyleEnglishVersion: 'English version',
      authenticAdvancedVersion: 'Advanced version',
      nonEnglishItems: [
        NonEnglishTranslationItem(
          original: '侄女',
          meaning: "nieces or nephews (younger siblings' children)",
          explanation: 'A Chinese kinship term referring to family members who are siblings of your siblings.',
        ),
        NonEnglishTranslationItem(
          original: '学校升降机',
          meaning: 'school elevator/lift',
          explanation: "Literal translation of 'school lift' used in the context of discussing transportation.",
        ),
      ],
    );

    tester.view.physicalSize = const Size(280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeTokens.createThemeData(isDark: false),
        home: Scaffold(
          body: BlocProvider.value(
            value: inquiryCubit,
            child: EditorialInspectorView(
              analysisResult: analysisWithLongItems,
              currentEntry: sampleEntry,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('非英文字词翻译及解释'), findsOneWidget);
    expect(find.textContaining('侄女'), findsOneWidget);
    expect(find.textContaining("nieces or nephews"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('EditorialInspectorView should immediately display user question bubble and pending status before AI responds',
      (WidgetTester tester) async {
    // 模拟一个异步延迟响应的 Completer
    final completer = Completer<InquiryStructuredResponse>();
    when(() => aiGateway.inquire(
          promptBundle: any(named: 'promptBundle'),
          config: any(named: 'config'),
        )).thenAnswer((_) => completer.future);

    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeTokens.createThemeData(isDark: false),
        home: Scaffold(
          body: BlocProvider.value(
            value: inquiryCubit,
            child: EditorialInspectorView(
              analysisResult: sampleAnalysis,
              currentEntry: sampleEntry,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final inputFinder = find.byKey(const ValueKey('inquiry_input_field'));
    final buttonFinder = find.byKey(const ValueKey('send_inquiry_button'));

    // 发送提问
    await tester.enterText(inputFinder, '如何用更高级的词汇形容暴风雨？');
    await tester.tap(buttonFinder);
    await tester.pump(); // 触发立即上屏，此时 AI 尚未返回！

    // 1. 验证用户提问气泡立即上屏
    expect(find.text('如何用更高级的词汇形容暴风雨？'), findsOneWidget);

    // 2. 验证正在推敲的专属思考动效展示
    expect(find.text('主编正在推敲语境与近义辨析...'), findsOneWidget);

    // 3. 验证输入框已被清空且处于禁用状态
    final textField = tester.widget<TextField>(inputFinder);
    expect(textField.controller?.text, isEmpty);
    expect(textField.enabled, isFalse);

    // 完成 AI 响应
    completer.complete(const InquiryStructuredResponse(
      reply: '可以使用 tempestuous storm 或者 raging deluge。',
      keyTakeaway: '使用暴烈意象的文学词汇。',
    ));
    await tester.pumpAndSettle();

    // 4. 验证思考动效消失，结构化卡片呈现
    expect(find.text('主编正在推敲语境与近义辨析...'), findsNothing);
    expect(find.textContaining('tempestuous storm'), findsOneWidget);
  });

  testWidgets('EditorialInspectorView should display failure state with retry and restore buttons when inquiry fails',
      (WidgetTester tester) async {
    when(() => aiGateway.inquire(
          promptBundle: any(named: 'promptBundle'),
          config: any(named: 'config'),
        )).thenThrow(const AiNetworkFailure('连接 AI 服务超时'));

    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeTokens.createThemeData(isDark: false),
        home: Scaffold(
          body: BlocProvider.value(
            value: inquiryCubit,
            child: EditorialInspectorView(
              analysisResult: sampleAnalysis,
              currentEntry: sampleEntry,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final inputFinder = find.byKey(const ValueKey('inquiry_input_field'));
    final buttonFinder = find.byKey(const ValueKey('send_inquiry_button'));

    await tester.enterText(inputFinder, '这个短语的文化背景是什么？');
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    // 1. 验证用户提问保留在列表气泡中
    expect(find.text('这个短语的文化背景是什么？'), findsOneWidget);

    // 2. 验证错误提示呈现
    expect(find.textContaining('连接 AI 服务超时'), findsWidgets);

    // 3. 验证重试与回填按钮存在
    final turnId = inquiryCubit.state.history.first.id;
    final retryBtnFinder = find.byKey(ValueKey('retry_inquiry_$turnId'));
    final restoreBtnFinder = find.byKey(ValueKey('restore_inquiry_$turnId'));
    expect(retryBtnFinder, findsOneWidget);
    expect(restoreBtnFinder, findsOneWidget);

    // 4. 测试点击【填回输入框】
    await tester.tap(restoreBtnFinder);
    await tester.pumpAndSettle();
    final restoredField = tester.widget<TextField>(inputFinder);
    expect(restoredField.controller?.text, '这个短语的文化背景是什么？');

    // 5. 测试点击【重试】
    final retryCompleter = Completer<InquiryStructuredResponse>();
    when(() => aiGateway.inquire(
          promptBundle: any(named: 'promptBundle'),
          config: any(named: 'config'),
        )).thenAnswer((_) => retryCompleter.future);

    await tester.tap(retryBtnFinder);
    await tester.pump(); // 进入重试 pending
    expect(find.text('主编正在推敲语境与近义辨析...'), findsOneWidget);

    retryCompleter.complete(const InquiryStructuredResponse(
      reply: '重试成功解答。',
      keyTakeaway: '成功重试要点。',
    ));
    await tester.pumpAndSettle(); // 重试完成
    expect(find.textContaining('重试成功解答。'), findsOneWidget);
    expect(find.textContaining('成功重试要点。'), findsOneWidget);
  });

  testWidgets('EditorialInspectorView should render collapsible thinking process card when present',
      (WidgetTester tester) async {
    const analysisWithThinking = DiaryAnalysisResult(
      originalStyleEnglishVersion: 'Original version',
      authenticAdvancedVersion: 'Advanced version',
      thinkingProcess: 'Step 1: Analyzed metaphor. Step 2: Formulated mindset bridge.',
    );

    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeTokens.createThemeData(isDark: false),
        home: Scaffold(
          body: BlocProvider.value(
            value: inquiryCubit,
            child: EditorialInspectorView(
              analysisResult: analysisWithThinking,
              currentEntry: sampleEntry,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('thinking_process_card')), findsOneWidget);
    expect(find.text('主编深度思考心路'), findsOneWidget);

    // 展开查看思考心路内容
    await tester.tap(find.byKey(const ValueKey('thinking_process_card')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Step 1: Analyzed metaphor'), findsOneWidget);
  });
}
