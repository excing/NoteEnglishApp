import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:note_english_flutter/app/service_locator.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
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

import 'package:note_english_flutter/domain/gateways/weather_gateway.dart';

class MockAiGateway extends Mock implements IAiGateway {}
class MockWeatherGateway extends Mock implements IWeatherGateway {}

void main() {
  late MockAiGateway mockAiGateway;
  late IDiaryRepository diaryRepo;
  late ICorpusRepository corpusRepo;
  late IAiConfigRepository configRepo;

  setUpAll(() {
    registerFallbackValue(const AiProfileConfig());
  });

  setUp(() async {
    mockAiGateway = MockAiGateway();
    diaryRepo = LocalDiaryRepository();
    corpusRepo = LocalCorpusRepository();
    configRepo = SecureAiConfigRepository();

    await sl.reset();
    sl.registerLazySingleton<PromptTemplateEngine>(() => const PromptTemplateEngine());
    sl.registerLazySingleton<IDiaryRepository>(() => diaryRepo);
    sl.registerLazySingleton<ICorpusRepository>(() => corpusRepo);
    sl.registerLazySingleton<IAiConfigRepository>(() => configRepo);
    sl.registerLazySingleton<IAiGateway>(() => mockAiGateway);
    sl.registerLazySingleton<IWeatherGateway>(() => MockWeatherGateway());
  });

  testWidgets('Bug Regression: Settings should immediately show persisted values on FIRST launch after restart',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // ==========================================
    // Phase 1: 第一次启动，保存用户自定义设置
    // ==========================================
    final initialEntry = DiaryEntry.create(
      content: 'Hello world',
      metadata: DiaryMetadata(
        recordedAt: DateTime.now(),
        weather: WeatherCondition.sunny,
        wordCount: 2,
      ),
    );

    final initialConfig = await configRepo.getConfig();
    await tester.pumpWidget(NoteEnglishApp(
      initialEntry: initialEntry,
      initialConfig: initialConfig,
    ));
    await tester.pumpAndSettle();

    // 打开设置
    await tester.tap(find.byKey(const ValueKey('ai_settings_button')));
    await tester.pumpAndSettle();

    // 输入自定义配置
    await tester.enterText(
        find.byKey(const ValueKey('setting_field_Base URL')), 'https://api.deepseek.com/v1');
    await tester.enterText(
        find.byKey(const ValueKey('setting_field_API Key')), 'sk-custom-deepseek-key');
    await tester.enterText(
        find.byKey(const ValueKey('setting_field_模型名称')), 'deepseek-chat');
    await tester.pumpAndSettle();

    // 点击保存
    await tester.tap(find.byKey(const ValueKey('save_settings_button')));
    await tester.pumpAndSettle();

    // 验证仓储已完成物理持久化
    final savedInRepo = await configRepo.getConfig();
    expect(savedInRepo.baseUrl, 'https://api.deepseek.com/v1');
    expect(savedInRepo.apiKey, 'sk-custom-deepseek-key');
    expect(savedInRepo.selectedModel, 'deepseek-chat');

    // ==========================================
    // Phase 2: 模拟 App 关闭与重新冷启动 (Relaunch)
    // ==========================================
    // 清除 Widget 树
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    // 重新从持久化仓储预加载配置 (对应 main.dart 的 startNoteEnglishApp 逻辑)
    final relaunchedConfig = await configRepo.getConfig();
    expect(relaunchedConfig.baseUrl, 'https://api.deepseek.com/v1');

    await tester.pumpWidget(NoteEnglishApp(
      initialEntry: initialEntry,
      initialConfig: relaunchedConfig,
    ));
    await tester.pumpAndSettle();

    // ==========================================
    // Phase 3: 重启后【第一次】打开设置
    // 关键验证：必须立即显示保存的配置，绝不能显示默认值！
    // ==========================================
    await tester.tap(find.byKey(const ValueKey('ai_settings_button')));
    await tester.pumpAndSettle();

    // 验证输入框中首次展示的值
    final baseUrlField = tester.widget<TextFormField>(
        find.byKey(const ValueKey('setting_field_Base URL')));
    final apiKeyField = tester.widget<TextFormField>(
        find.byKey(const ValueKey('setting_field_API Key')));
    final modelField = tester.widget<TextFormField>(
        find.byKey(const ValueKey('setting_field_模型名称')));

    expect(baseUrlField.controller?.text, 'https://api.deepseek.com/v1',
        reason: '首次打开设置时，Base URL 必须立即显示保存的值');
    expect(apiKeyField.controller?.text, 'sk-custom-deepseek-key',
        reason: '首次打开设置时，API Key 必须立即显示保存的值');
    expect(modelField.controller?.text, 'deepseek-chat',
        reason: '首次打开设置时，模型名称必须立即显示保存的值');

    // 关闭并第二次打开，验证稳定性
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ai_settings_button')));
    await tester.pumpAndSettle();

    final baseUrlFieldSecond = tester.widget<TextFormField>(
        find.byKey(const ValueKey('setting_field_Base URL')));
    expect(baseUrlFieldSecond.controller?.text, 'https://api.deepseek.com/v1');
  });
}
