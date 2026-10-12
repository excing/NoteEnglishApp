import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:note_english_flutter/application/inquiry/inquiry_cubit.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/domain/contracts/ai_contracts.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';
import 'package:note_english_flutter/domain/models/analysis/diary_analysis_result.dart';
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
}
