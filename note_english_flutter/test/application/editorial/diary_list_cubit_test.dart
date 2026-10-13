import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:note_english_flutter/application/diary/diary_list_cubit.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';

class MockDiaryRepository extends Mock implements IDiaryRepository {}

void main() {
  late MockDiaryRepository diaryRepo;
  late StreamController<List<DiaryEntry>> entriesStreamController;

  final entry1 = DiaryEntry.create(
    content: 'First entry about rainy morning.',
    metadata: DiaryMetadata(
      recordedAt: DateTime(2026, 10, 10, 9, 0),
      weather: WeatherCondition.rainy,
      wordCount: 5,
    ),
  );

  final entry2 = DiaryEntry.create(
    content: 'Second entry enjoying hot coffee.',
    metadata: DiaryMetadata(
      recordedAt: DateTime(2026, 10, 11, 15, 30),
      weather: WeatherCondition.sunny,
      wordCount: 5,
    ),
  );

  setUpAll(() {
    registerFallbackValue(entry1);
  });

  setUp(() {
    diaryRepo = MockDiaryRepository();
    entriesStreamController = StreamController<List<DiaryEntry>>.broadcast();
    when(() => diaryRepo.watchAllEntries())
        .thenAnswer((_) => entriesStreamController.stream);
    when(() => diaryRepo.getAllEntries())
        .thenAnswer((_) async => [entry2, entry1]);
    when(() => diaryRepo.saveEntry(any())).thenAnswer((_) async {});
    when(() => diaryRepo.deleteEntry(any())).thenAnswer((_) async {});
  });

  tearDown(() {
    entriesStreamController.close();
  });

  group('DiaryListCubit TDD Tests', () {
    test('initial state has correct defaults', () {
      final cubit = DiaryListCubit(diaryRepository: diaryRepo);
      expect(cubit.state.entries, isEmpty);
      expect(cubit.state.searchQuery, isEmpty);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.activeEntryId, isNull);
    });

    blocTest<DiaryListCubit, DiaryListState>(
      'loads entries and listens to repository updates',
      build: () => DiaryListCubit(diaryRepository: diaryRepo),
      act: (cubit) async {
        await cubit.loadEntries();
      },
      expect: () => [
        isA<DiaryListState>().having((s) => s.isLoading, 'isLoading', isTrue),
        isA<DiaryListState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.entries.length, 'entries.length', 2),
      ],
    );

    blocTest<DiaryListCubit, DiaryListState>(
      'filters entries based on searchQuery',
      build: () => DiaryListCubit(diaryRepository: diaryRepo),
      seed: () => DiaryListState(
        entries: [entry2, entry1],
        activeEntryId: entry2.id,
      ),
      act: (cubit) => cubit.setSearchQuery('coffee'),
      expect: () => [
        isA<DiaryListState>()
            .having((s) => s.searchQuery, 'query', 'coffee')
            .having((s) => s.filteredEntries.length, 'filtered length', 1)
            .having(
              (s) => s.filteredEntries.first.content,
              'content',
              contains('coffee'),
            ),
      ],
    );

    blocTest<DiaryListCubit, DiaryListState>(
      'creates a new diary entry, saves to repository, and sets as active',
      build: () => DiaryListCubit(diaryRepository: diaryRepo),
      act: (cubit) async {
        final created = await cubit.createEntry(weather: WeatherCondition.cloudy);
        expect(created.metadata.weather, WeatherCondition.cloudy);
      },
      verify: (_) {
        verify(() => diaryRepo.saveEntry(any())).called(1);
      },
    );

    blocTest<DiaryListCubit, DiaryListState>(
      'deletes an entry from repository',
      build: () => DiaryListCubit(diaryRepository: diaryRepo),
      act: (cubit) => cubit.deleteEntry(entry1.id),
      verify: (_) {
        verify(() => diaryRepo.deleteEntry(entry1.id)).called(1);
      },
    );

    blocTest<DiaryListCubit, DiaryListState>(
      'updates activeEntryId correctly',
      build: () => DiaryListCubit(diaryRepository: diaryRepo),
      act: (cubit) => cubit.setActiveEntryId(entry2.id),
      expect: () => [
        isA<DiaryListState>().having((s) => s.activeEntryId, 'activeEntryId', entry2.id),
      ],
    );
  });
}
