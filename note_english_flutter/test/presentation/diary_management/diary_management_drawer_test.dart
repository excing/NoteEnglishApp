import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:note_english_flutter/application/diary/diary_list_cubit.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/domain/models/analysis/diary_analysis_result.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';
import 'package:note_english_flutter/presentation/modules/diary_management/diary_management_drawer.dart';

class MockDiaryRepository extends Mock implements IDiaryRepository {}

void main() {
  late MockDiaryRepository diaryRepo;

  final entry1 = DiaryEntry.create(
    content: 'First rainy note in the evening.',
    metadata: DiaryMetadata(
      recordedAt: DateTime(2026, 10, 10, 20, 0),
      weather: WeatherCondition.rainy,
      wordCount: 6,
    ),
  ).withAnalysisResult(const DiaryAnalysisResult(
    originalStyleEnglishVersion: 'First rainy note in the evening.',
    authenticAdvancedVersion: 'Evening rain fallen soft.',
  ));

  final entry2 = DiaryEntry.create(
    content: 'Second morning coffee notes.',
    metadata: DiaryMetadata(
      recordedAt: DateTime(2026, 10, 11, 8, 30),
      weather: WeatherCondition.sunny,
      wordCount: 4,
    ),
  );

  setUpAll(() {
    registerFallbackValue(entry1);
  });

  setUp(() {
    diaryRepo = MockDiaryRepository();
    when(() => diaryRepo.watchAllEntries())
        .thenAnswer((_) => Stream.value([entry2, entry1]));
    when(() => diaryRepo.getAllEntries())
        .thenAnswer((_) async => [entry2, entry1]);
    when(() => diaryRepo.saveEntry(any())).thenAnswer((_) async {});
    when(() => diaryRepo.deleteEntry(any())).thenAnswer((_) async {});
  });

  Widget buildTestWidget({
    required DiaryListCubit cubit,
    void Function(DiaryEntry)? onSelect,
    void Function(DiaryEntry)? onCreated,
    VoidCallback? onOpenCorpus,
    VoidCallback? onOpenSettings,
  }) {
    return MaterialApp(
      theme: AppThemeTokens.createThemeData(isDark: false),
      home: Scaffold(
        drawer: BlocProvider.value(
          value: cubit,
          child: DiaryManagementDrawer(
            onSelectEntry: onSelect,
            onEntryCreated: onCreated,
            onOpenCorpus: onOpenCorpus,
            onOpenSettings: onOpenSettings,
          ),
        ),
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  group('DiaryManagementDrawer Widget Tests (TDD)', () {
    testWidgets('renders list of entries, search input and new diary button',
        (tester) async {
      final cubit = DiaryListCubit(
        diaryRepository: diaryRepo,
        initialActiveEntryId: entry2.id,
      );

      await tester.pumpWidget(buildTestWidget(cubit: cubit));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('OtterJot'), findsOneWidget);
      expect(find.byKey(const ValueKey('new_diary_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('search_diary_input')), findsOneWidget);

      expect(find.textContaining('Second morning coffee notes.'), findsOneWidget);
      expect(find.textContaining('First rainy note in the evening.'), findsOneWidget);
      expect(find.text('已梳理'), findsOneWidget);
      expect(find.text('当前编辑'), findsOneWidget);
    });

    testWidgets('filters entries by search query', (tester) async {
      final cubit = DiaryListCubit(
        diaryRepository: diaryRepo,
        initialActiveEntryId: entry2.id,
      );

      await tester.pumpWidget(buildTestWidget(cubit: cubit));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const ValueKey('search_diary_input')), 'rainy');
      await tester.pumpAndSettle();

      expect(find.textContaining('First rainy note'), findsOneWidget);
      expect(find.textContaining('Second morning coffee'), findsNothing);
    });

    testWidgets('clicking entry calls onSelectEntry callback', (tester) async {
      final cubit = DiaryListCubit(
        diaryRepository: diaryRepo,
        initialActiveEntryId: entry2.id,
      );
      DiaryEntry? selected;

      await tester.pumpWidget(buildTestWidget(
        cubit: cubit,
        onSelect: (entry) => selected = entry,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('First rainy note'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.id, entry1.id);
    });

    testWidgets('clicking delete button opens confirmation dialog and deletes',
        (tester) async {
      final cubit = DiaryListCubit(
        diaryRepository: diaryRepo,
        initialActiveEntryId: entry2.id,
      );

      await tester.pumpWidget(buildTestWidget(cubit: cubit));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final deleteBtn = find.byKey(ValueKey('delete_diary_button_${entry1.id}'));
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('确认删除随笔'), findsOneWidget);
      await tester.tap(find.text('确认删除'));
      await tester.pumpAndSettle();

      verify(() => diaryRepo.deleteEntry(entry1.id)).called(1);
    });

    testWidgets('clicking new diary button creates a new entry and invokes callback',
        (tester) async {
      final cubit = DiaryListCubit(
        diaryRepository: diaryRepo,
        initialActiveEntryId: entry2.id,
      );
      DiaryEntry? created;

      await tester.pumpWidget(buildTestWidget(
        cubit: cubit,
        onCreated: (entry) => created = entry,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('new_diary_button')));
      await tester.pumpAndSettle();

      verify(() => diaryRepo.saveEntry(any())).called(1);
      expect(created, isNotNull);
    });

    testWidgets('clicking corpus and settings footer buttons invokes callbacks',
        (tester) async {
      final cubit = DiaryListCubit(
        diaryRepository: diaryRepo,
        initialActiveEntryId: entry2.id,
      );
      bool corpusOpened = false;
      bool settingsOpened = false;

      await tester.pumpWidget(buildTestWidget(
        cubit: cubit,
        onOpenCorpus: () => corpusOpened = true,
        onOpenSettings: () => settingsOpened = true,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // 验证底部常驻入口渲染
      expect(find.byKey(const ValueKey('corpus_deck_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('ai_settings_button')), findsOneWidget);

      // 点击语料库
      await tester.tap(find.byKey(const ValueKey('corpus_deck_button')));
      await tester.pumpAndSettle();
      expect(corpusOpened, isTrue);

      // 重新打开抽屉并点击设置
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ai_settings_button')));
      await tester.pumpAndSettle();
      expect(settingsOpened, isTrue);
    });
  });
}
