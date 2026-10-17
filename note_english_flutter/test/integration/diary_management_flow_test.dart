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

    await configRepo.saveConfig(const AiProfileConfig(
      baseUrl: 'https://api.openai.com/v1',
      apiKey: 'test-key',
    ));

    await sl.reset();
    sl.registerLazySingleton<PromptTemplateEngine>(() => const PromptTemplateEngine());
    sl.registerLazySingleton<IDiaryRepository>(() => diaryRepo);
    sl.registerLazySingleton<ICorpusRepository>(() => corpusRepo);
    sl.registerLazySingleton<IAiConfigRepository>(() => configRepo);
    sl.registerLazySingleton<IAiGateway>(() => mockAiGateway);
    sl.registerLazySingleton<IWeatherGateway>(() => MockWeatherGateway());
  });

  testWidgets(
      'Full Note Management Journey: Browse list -> Switch note -> Quick new note -> Delete note',
      (WidgetTester tester) async {
    final entry1 = DiaryEntry.create(
      content: 'Note 1: Working on English writing.',
      metadata: DiaryMetadata(
        recordedAt: DateTime(2026, 10, 10, 10, 0),
        weather: WeatherCondition.sunny,
        wordCount: 6,
      ),
    );

    final entry2 = DiaryEntry.create(
      content: 'Note 2: Rainy cafe afternoon reading.',
      metadata: DiaryMetadata(
        recordedAt: DateTime(2026, 10, 11, 15, 0),
        weather: WeatherCondition.rainy,
        wordCount: 5,
      ),
    );

    await diaryRepo.saveEntry(entry1);
    await diaryRepo.saveEntry(entry2);

    await tester.pumpWidget(NoteEnglishApp(
      initialEntry: entry2,
      initialConfig: const AiProfileConfig(apiKey: 'key', baseUrl: 'url'),
    ));
    await tester.pumpAndSettle();

    // 1. 验证当前书房显示 Note 2
    expect(find.textContaining('Rainy cafe afternoon'), findsOneWidget);

    // 2. 点击随笔抽屉按钮展开管理抽屉
    final drawerBtn = find.byKey(const ValueKey('diary_drawer_button'));
    expect(drawerBtn, findsOneWidget);
    await tester.tap(drawerBtn);
    await tester.pumpAndSettle();

    // 3. 抽屉内应显示两篇随笔
    expect(find.text('OtterJot'), findsOneWidget);
    expect(find.text('2 篇'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.textContaining('Note 1: Working on English writing.'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.textContaining('Note 2: Rainy cafe afternoon reading.'),
      ),
      findsOneWidget,
    );

    // 4. 搜索过滤
    await tester.enterText(
        find.byKey(const ValueKey('search_diary_input')), 'English');
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.textContaining('Note 1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.textContaining('Note 2'),
      ),
      findsNothing,
    );

    // 5. 点击 Note 1 切换
    await tester.tap(find.textContaining('Note 1'));
    await tester.pumpAndSettle();

    // 抽屉收起，书房当前正文已无缝切换为 Note 1
    expect(find.textContaining('Note 1: Working on English writing.'), findsOneWidget);

    // 6. 快捷新建随笔
    final quickNewBtn = find.byKey(const ValueKey('quick_new_diary_button'));
    expect(quickNewBtn, findsOneWidget);
    await tester.tap(quickNewBtn);
    await tester.pumpAndSettle();

    // 此时应生成空白随笔
    final inputField = find.byKey(const ValueKey('diary_input_field'));
    expect(inputField, findsOneWidget);
    await tester.enterText(inputField, 'Note 3: Brand new diary entry!');
    await tester.pumpAndSettle();

    // 7. 再次打开抽屉验证总数为 3 篇，并测试删除
    await tester.tap(find.byKey(const ValueKey('diary_drawer_button')));
    await tester.pumpAndSettle();
    expect(find.text('3 篇'), findsOneWidget);

    // 删除 Note 1
    final deleteNote1Btn = find.byKey(ValueKey('delete_diary_button_${entry1.id}'));
    expect(deleteNote1Btn, findsOneWidget);
    await tester.tap(deleteNote1Btn);
    await tester.pumpAndSettle();

    // 确认删除弹窗
    expect(find.text('确认删除随笔'), findsOneWidget);
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();

    // 验证 Note 1 已从列表移除
    expect(find.textContaining('Note 1: Working on English writing.'), findsNothing);
    final remainingInRepo = await diaryRepo.getAllEntries();
    expect(remainingInRepo.any((e) => e.id == entry1.id), isFalse);
  });
}
