import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:note_english_flutter/app/service_locator.dart';
import 'package:note_english_flutter/domain/contracts/ai_contracts.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/models/analysis/correction_item.dart';
import 'package:note_english_flutter/domain/models/analysis/diary_analysis_result.dart';
import 'package:note_english_flutter/domain/models/analysis/translation_item.dart';
import 'package:note_english_flutter/domain/models/analysis/unnatural_expression_item.dart';
import 'package:note_english_flutter/domain/models/config/ai_model_descriptor.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_draft.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/models/inquiry/inquiry_response.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';
import 'package:note_english_flutter/infrastructure/repositories/local_corpus_repository.dart';
import 'package:note_english_flutter/infrastructure/repositories/local_diary_repository.dart';
import 'package:note_english_flutter/infrastructure/repositories/secure_ai_config_repository.dart';
import 'package:note_english_flutter/domain/gateways/weather_gateway.dart';
import 'package:note_english_flutter/main.dart';

class MockAiGateway extends Mock implements IAiGateway {}
class MockWeatherGateway extends Mock implements IWeatherGateway {}

void main() {
  late MockAiGateway mockAiGateway;
  late IDiaryRepository diaryRepo;
  late ICorpusRepository corpusRepo;
  late IAiConfigRepository configRepo;

  setUpAll(() {
    registerFallbackValue(const PromptBundle(systemPrompt: '', userMessage: ''));
    registerFallbackValue(const AiProfileConfig());
  });

  setUp(() async {
    mockAiGateway = MockAiGateway();
    diaryRepo = LocalDiaryRepository();
    corpusRepo = LocalCorpusRepository();
    configRepo = SecureAiConfigRepository();

    // 预置已配置的 API
    await configRepo.saveConfig(const AiProfileConfig(
      baseUrl: 'https://api.openai.com/v1',
      apiKey: 'test-key',
      selectedModel: 'gpt-4o',
    ));

    // 重置并注册服务定位器
    await sl.reset();
    sl.registerLazySingleton<PromptTemplateEngine>(() => const PromptTemplateEngine());
    sl.registerLazySingleton<IDiaryRepository>(() => diaryRepo);
    sl.registerLazySingleton<ICorpusRepository>(() => corpusRepo);
    sl.registerLazySingleton<IAiConfigRepository>(() => configRepo);
    sl.registerLazySingleton<IAiGateway>(() => mockAiGateway);
    sl.registerLazySingleton<IWeatherGateway>(() => MockWeatherGateway());
  });

  testWidgets('Complete user flow: Write -> Analyze -> Inspect -> Inquire -> Review Corpus',
      (WidgetTester tester) async {
    // 1. Mock AI 梳理响应
    const mockAnalysis = DiaryAnalysisResult(
      nonEnglishItems: [
        NonEnglishTranslationItem(
          original: '深烘焙',
          meaning: 'dark roast',
          explanation: '咖啡豆烘焙程度',
        ),
      ],
      incorrectExpressions: [
        ExpressionCorrectionItem(
          original: 'Today work overtime',
          correction: 'I worked overtime today',
          explanation: '缺少主语，叙述过去事件需用过去式',
        ),
      ],
      originalStyleEnglishVersion:
          'I worked overtime until 9pm today, and it was raining heavily outside.',
      unnaturalExpressions: [
        UnnaturalExpressionItem(
          original: 'outside is raining heavily',
          naturalAlternative: 'it was pouring rain outside',
          mindsetBridge: '英文习惯以 it 为天气主语，或使用 pour 生动描述雨势',
        ),
      ],
      authenticAdvancedVersion:
          'Clocked out after nine tonight into a relentless downpour. Bone-tired, yet grounded by the deep aroma of dark roast.',
      extractedCorpus: [
        CorpusItemDraft(
          expression: 'relentless downpour',
          phonetic: '/rɪˈlentləs ˈdaʊnpɔːr/',
          meaning: '倾盆大雨',
          usageContext: '极具文学质感的暴雨意象搭配',
        ),
      ],
    );

    when(() => mockAiGateway.analyzeDiary(
          promptBundle: any(named: 'promptBundle'),
          config: any(named: 'config'),
        )).thenAnswer((_) async => mockAnalysis);

    // 2. Mock 追问响应
    const mockInquiryResp = InquiryStructuredResponse(
      reply: 'clock out 是极为地道的职场口语动词，替代抽象的 work overtime，生活画面跃然纸上。',
      keyTakeaway: '用具象动作动词 (clock out) 替代抽象描述 (finish work)。',
      examples: [
        'I usually clock out at 6 PM sharp.',
        'Don\'t forget to clock out before leaving.',
      ],
      extractedCorpus: [
        CorpusItemDraft(
          expression: 'clock out',
          phonetic: '/klɒk aʊt/',
          meaning: '打卡下班',
          usageContext: '常见日常口语动词短语',
        )
      ],
    );

    when(() => mockAiGateway.inquire(
          promptBundle: any(named: 'promptBundle'),
          config: any(named: 'config'),
        )).thenAnswer((_) async => mockInquiryResp);

    // 3. 启动应用
    final initialEntry = DiaryEntry.create(
      content: 'Today work overtime until 9pm, outside is raining heavily. 深烘焙手冲让人放松。',
      metadata: DiaryMetadata(
        recordedAt: DateTime(2026, 10, 10, 21, 30),
        weather: WeatherCondition.rainy,
        wordCount: 15,
      ),
    );

    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(NoteEnglishApp(initialEntry: initialEntry));
    await tester.pumpAndSettle();

    // 验证随笔书房正常渲染
    expect(find.text('呼叫主编梳理'), findsOneWidget);
    expect(find.textContaining('深烘焙手冲让人放松'), findsOneWidget);

    // 4. 点击呼叫主编梳理
    await tester.tap(find.text('呼叫主编梳理'));
    await tester.pump(); // 进入 analyzing 状态
    await tester.pumpAndSettle(); // 分析完成

    // 5. 验证 5 大结构化呈现卡片
    expect(find.text('非英文字词翻译及解释'), findsOneWidget);
    expect(find.text('深烘焙'), findsOneWidget);
    expect(find.text('→  dark roast'), findsOneWidget);

    expect(find.text('不正确的英文表达及解释'), findsOneWidget);
    expect(find.textContaining('I worked overtime today'), findsOneWidget);

    expect(find.text('原文风格的英文版本 (保留你的本真口吻)'), findsOneWidget);

    expect(find.text('思维桥梁 (Mindset Bridge) 与进阶版本'), findsOneWidget);
    expect(find.textContaining('it was pouring rain outside'), findsOneWidget);

    expect(find.textContaining('地道英文表达的进阶版本'), findsOneWidget);
    expect(find.textContaining('relentless downpour'), findsWidgets);

    // 验证自动语料入库反馈微徽章
    expect(find.textContaining('已自动将 1 条核心生动表达收录进专属语料库'), findsOneWidget);

    // 6. 新交互验证：无需单独进入界面，追问输入框直接在 AI 梳理界面下方置底
    expect(find.byKey(const ValueKey('inquiry_input_field')), findsOneWidget);
    expect(find.text('主编追问与语感切磋'), findsOneWidget);

    // 直接在置底输入框输入追问内容
    await tester.enterText(
        find.byKey(const ValueKey('inquiry_input_field')),
        '为什么用 clock out 比 work overtime 更好？');
    await tester.pumpAndSettle();

    // 点击置底发送按钮
    await tester.tap(find.byKey(const ValueKey('send_inquiry_button')));
    await tester.pump();
    await tester.pumpAndSettle();

    // 验证追问结构化结果直接呈现在梳理视窗中 (无需单独弹窗或关闭操作)
    expect(find.textContaining('clock out 是极为地道的职场口语动词'), findsOneWidget);
    expect(find.textContaining('核心重点:'), findsOneWidget);
    expect(find.textContaining('延伸应用示例：'), findsOneWidget);
    expect(find.textContaining('I usually clock out at 6 PM sharp.'), findsOneWidget);

    // 7. 进入专属语料库页面
    await tester.tap(find.byKey(const ValueKey('corpus_deck_button')));
    await tester.pumpAndSettle();

    expect(find.text('专属生活语料库'), findsOneWidget);
    // 验证梳理与追问中自动入库的语料已被收录
    expect(find.text('relentless downpour'), findsOneWidget);
    expect(find.text('clock out'), findsOneWidget);
    expect(find.textContaining('打卡下班'), findsOneWidget);
    expect(find.textContaining('倾盆大雨'), findsOneWidget);
  });
}
