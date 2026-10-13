import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:note_english_flutter/app/service_locator.dart';
import 'package:note_english_flutter/domain/contracts/ai_contracts.dart';
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
import 'package:note_english_flutter/presentation/modules/editorial_inspector/editorial_inspector_view.dart';
import 'package:note_english_flutter/presentation/modules/diary_management/diary_management_drawer.dart';

class MockAiGateway extends Mock implements IAiGateway {}
class MockWeatherGateway extends Mock implements IWeatherGateway {}

void main() {
  late MockAiGateway mockAiGateway;
  late IDiaryRepository diaryRepo;
  late ICorpusRepository corpusRepo;
  late IAiConfigRepository configRepo;

  final testEntry = DiaryEntry.create(
    content: 'Studying English and sipping hot tea on a quiet afternoon.',
    metadata: DiaryMetadata(
      recordedAt: DateTime(2026, 10, 13, 14, 0),
      weather: WeatherCondition.sunny,
      wordCount: 11,
    ),
  );

  const mockAnalysis = DiaryAnalysisResult(
    nonEnglishItems: [],
    incorrectExpressions: [],
    originalStyleEnglishVersion: 'Studying English and enjoying tea.',
    unnaturalExpressions: [],
    authenticAdvancedVersion: 'Immersed in English studies while savoring a cup of hot tea.',
    extractedCorpus: [],
  );

  setUpAll(() {
    registerFallbackValue(const PromptBundle(systemPrompt: '', userMessage: ''));
    registerFallbackValue(const AiProfileConfig());
  });

  setUp(() async {
    mockAiGateway = MockAiGateway();
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
    sl.registerLazySingleton<IWeatherGateway>(() => MockWeatherGateway());

    when(() => mockAiGateway.analyzeDiary(
          promptBundle: any(named: 'promptBundle'),
          config: any(named: 'config'),
        )).thenAnswer((_) async => mockAnalysis);
  });

  group('三栏响应式自适应布局验证 (TDD Specifications)', () {
    testWidgets('桌面尺寸 (Desktop: width >= 1024): 默认显示左边栏和主区域，点击梳理显示右边栏实现三栏',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(NoteEnglishApp(initialEntry: testEntry));
      await tester.pumpAndSettle();

      // 1. 验证默认展示：左边栏 (随笔列表) 常驻显示
      expect(find.text('随笔手账'), findsOneWidget);
      expect(find.text('新建随笔'), findsOneWidget);

      // 2. 验证主区域 (编辑) 显示
      expect(find.byKey(const ValueKey('diary_input_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('call_editor_button')), findsOneWidget);

      // 3. 验证默认右边栏 (AI 视窗) 处于收起隐藏状态
      expect(find.byKey(const ValueKey('close_ai_sidebar_button')), findsNothing);
      expect(find.byType(EditorialInspectorView), findsNothing);

      // 4. 点击“呼叫主编梳理”
      await tester.tap(find.byKey(const ValueKey('call_editor_button')));
      await tester.pump(); // analyzing 状态
      await tester.pumpAndSettle(); // 分析完成

      // 5. 验证三栏并存：左边栏 + 主区域 + 右边栏同时呈现
      expect(find.text('随笔手账'), findsOneWidget); // 左边栏
      expect(find.byKey(const ValueKey('diary_input_field')), findsOneWidget); // 主区域
      expect(find.text('主编梳理与追问'), findsOneWidget); // 右边栏顶部标题
      expect(find.byType(EditorialInspectorView), findsOneWidget); // 右边栏AI内容
      expect(find.byKey(const ValueKey('close_ai_sidebar_button')), findsOneWidget); // 右边栏收起按钮

      // 6. 点击右边栏收起按钮
      await tester.tap(find.byKey(const ValueKey('close_ai_sidebar_button')));
      await tester.pumpAndSettle();

      // 右边栏收起，恢复为左边栏+主区域
      expect(find.text('随笔手账'), findsOneWidget);
      expect(find.byKey(const ValueKey('diary_input_field')), findsOneWidget);
      expect(find.byType(EditorialInspectorView), findsNothing);

      // 7. 测试左侧边栏快捷折叠与恢复
      await tester.tap(find.byKey(const ValueKey('diary_drawer_button')));
      await tester.pumpAndSettle();
      expect(find.text('随笔手账'), findsNothing); // 左边栏折叠

      await tester.tap(find.byKey(const ValueKey('diary_drawer_button')));
      await tester.pumpAndSettle();
      expect(find.text('随笔手账'), findsOneWidget); // 左边栏恢复展开
    });

    testWidgets('平板尺寸 (Tablet: 720 <= width < 1024): 笔记列表侧滑，默认主区域，点击梳理右边栏显示',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(860, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(NoteEnglishApp(initialEntry: testEntry));
      await tester.pumpAndSettle();

      // 1. 平板默认仅展示主区域，左边栏非常驻
      expect(find.byKey(const ValueKey('diary_input_field')), findsOneWidget);
      expect(find.text('随笔手账'), findsNothing);
      expect(find.byKey(const ValueKey('close_ai_sidebar_button')), findsNothing);

      // 2. 点击左上角抽屉按钮，笔记列表从左侧滑出 (Drawer)
      await tester.tap(find.byKey(const ValueKey('diary_drawer_button')));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsOneWidget);
      expect(find.text('随笔手账'), findsOneWidget);

      // 关闭抽屉 (点击遮罩)
      await tester.tapAt(const Offset(800, 300));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsNothing);

      // 3. 点击“呼叫主编梳理”
      await tester.tap(find.byKey(const ValueKey('call_editor_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      // 4. 验证平板端双栏并排：主区域 + 右边栏 (AI)
      expect(find.byKey(const ValueKey('diary_input_field')), findsOneWidget);
      expect(find.text('主编梳理与追问'), findsOneWidget);
      expect(find.byType(EditorialInspectorView), findsOneWidget);

      // 5. 点击收起右边栏
      await tester.tap(find.byKey(const ValueKey('close_ai_sidebar_button')));
      await tester.pumpAndSettle();
      expect(find.byType(EditorialInspectorView), findsNothing);
    });

    testWidgets('手机尺寸 (Mobile: width < 720): 经典单栏心流设计，笔记列表侧滑，AI 从底部滑出',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(NoteEnglishApp(initialEntry: testEntry));
      await tester.pumpAndSettle();

      // 1. 默认展示纯净单栏主区域
      expect(find.byKey(const ValueKey('diary_input_field')), findsOneWidget);
      expect(find.text('随笔手账'), findsNothing);
      expect(find.byKey(const ValueKey('close_ai_sidebar_button')), findsNothing);

      // 2. 点击左上角呼出侧滑抽屉
      await tester.tap(find.byKey(const ValueKey('diary_drawer_button')));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsOneWidget);
      expect(find.text('随笔手账'), findsOneWidget);

      // 关闭抽屉
      await tester.tapAt(const Offset(350, 400));
      await tester.pumpAndSettle();

      // 3. 点击“呼叫主编梳理”
      await tester.tap(find.byKey(const ValueKey('call_editor_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      // 4. 验证移动端单栏下方展示温润展开条：“主编润色重塑已就绪 · 查看洞察”
      expect(find.text('主编润色重塑已就绪 · 查看洞察'), findsOneWidget);

      // 5. 点击该条目，AI 梳理视窗从底部滑出 (Modal Bottom Sheet)
      await tester.tap(find.text('主编润色重塑已就绪 · 查看洞察'));
      await tester.pumpAndSettle();

      expect(find.byType(EditorialInspectorView), findsOneWidget);
      expect(find.textContaining('Immersed in English studies'), findsOneWidget);
    });

    testWidgets('桌面尺寸下支持用户自由拖拽调整左右边栏宽度，并双击恢复默认',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(NoteEnglishApp(initialEntry: testEntry));
      await tester.pumpAndSettle();

      final leftHandleFinder = find.byKey(const ValueKey('left_pane_resize_handle'));
      expect(leftHandleFinder, findsOneWidget);

      // 1. 验证左边栏初始默认宽度 (320px)
      var drawerSize = tester.getSize(find.byType(DiaryManagementDrawer));
      expect(drawerSize.width, equals(320.0));

      // 2. 向右拖拽左手柄 60px -> 边栏宽度变宽 (> 320px)
      await tester.drag(leftHandleFinder, const Offset(60, 0));
      await tester.pumpAndSettle();
      drawerSize = tester.getSize(find.byType(DiaryManagementDrawer));
      expect(drawerSize.width, greaterThan(320.0));

      // 3. 双击手柄 -> 恢复默认 320px
      await tester.tap(leftHandleFinder);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(leftHandleFinder);
      await tester.pumpAndSettle();
      drawerSize = tester.getSize(find.byType(DiaryManagementDrawer));
      expect(drawerSize.width, equals(320.0));

      // 4. 展开右边栏 (呼叫主编梳理)
      await tester.tap(find.byKey(const ValueKey('call_editor_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      final rightHandleFinder = find.byKey(const ValueKey('right_pane_resize_handle'));
      expect(rightHandleFinder, findsOneWidget);

      // 5. 验证右边栏初始默认宽度 (380px)
      final rightInspectorFinder = find.byType(EditorialInspectorView);
      var rightInspectorSize = tester.getSize(rightInspectorFinder);
      expect(rightInspectorSize.width, equals(380.0));

      // 6. 向左拖拽右手柄 60px (增大右边栏宽度 > 380px)
      await tester.drag(rightHandleFinder, const Offset(-60, 0));
      await tester.pumpAndSettle();
      rightInspectorSize = tester.getSize(rightInspectorFinder);
      expect(rightInspectorSize.width, greaterThan(380.0));

      // 7. 双击右手柄 -> 恢复默认 380px
      await tester.tap(rightHandleFinder);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(rightHandleFinder);
      await tester.pumpAndSettle();
      rightInspectorSize = tester.getSize(rightInspectorFinder);
      expect(rightInspectorSize.width, equals(380.0));
    });

    testWidgets('极限拖拽与窄屏情况下，主区域严格保持最小可视宽度 (380px)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768); // 临界桌面尺寸
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(NoteEnglishApp(initialEntry: testEntry));
      await tester.pumpAndSettle();

      // 打开右边栏
      await tester.tap(find.byKey(const ValueKey('call_editor_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      final leftHandleFinder = find.byKey(const ValueKey('left_pane_resize_handle'));
      final rightHandleFinder = find.byKey(const ValueKey('right_pane_resize_handle'));

      // 极限向右拖拽左手柄 800px (试图挤压主区域)
      await tester.drag(leftHandleFinder, const Offset(800, 0));
      await tester.pumpAndSettle();

      // 极限向左拖拽右手柄 800px (试图进一步挤压主区域)
      await tester.drag(rightHandleFinder, const Offset(-800, 0));
      await tester.pumpAndSettle();

      // 验证主书写输入区域的宽度绝对不低于 380px
      final inputFieldFinder = find.byKey(const ValueKey('diary_input_field'));
      final inputFieldSize = tester.getSize(inputFieldFinder);
      // 输入框在主区域内部且包含水平 padding (32*2 = 64)，因此输入框宽度 + 64 >= 380
      expect(inputFieldSize.width + 64.0, greaterThanOrEqualTo(380.0));
    });
  });
}
