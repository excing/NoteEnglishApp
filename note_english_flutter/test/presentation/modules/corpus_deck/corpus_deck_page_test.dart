import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:note_english_flutter/application/corpus/corpus_deck_cubit.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_item.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_source.dart';
import 'package:note_english_flutter/domain/models/corpus/mastery_status.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';
import 'package:note_english_flutter/presentation/modules/corpus_deck/corpus_deck_page.dart';

class MockCorpusRepository extends Mock implements ICorpusRepository {}

void main() {
  late MockCorpusRepository mockRepo;

  setUp(() {
    mockRepo = MockCorpusRepository();
  });

  testWidgets('CorpusDeckPage displays phonetic text with professional non-italic style and font fallbacks',
      (tester) async {
    final item = CorpusItem(
      id: 'test-1',
      expression: 'so many',
      phonetic: '/soʊ ˈmɛni/',
      meaning: '很多',
      usageContext: '用于可数名词',
      masteryStatus: MasteryStatus.encountered,
      reviewCount: 0,
      source: CorpusSource(
        diaryId: 'diary-1',
        sourceSnippet: 'I find so many channels',
        sourceType: CorpusSourceType.analysis,
        createdAt: DateTime.now(),
      ),
    );

    when(() => mockRepo.getAllCorpus()).thenAnswer((_) async => [item]);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeTokens.createThemeData(isDark: false),
        home: BlocProvider<CorpusDeckCubit>(
          create: (_) => CorpusDeckCubit(corpusRepository: mockRepo),
          child: const CorpusDeckPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final phoneticFinder = find.text('/soʊ ˈmɛni/');
    expect(phoneticFinder, findsOneWidget);

    final Text textWidget = tester.widget<Text>(phoneticFinder);
    expect(textWidget.style?.fontStyle, equals(FontStyle.normal));
    expect(
      textWidget.style?.fontFamilyFallback,
      containsAll([
        '.AppleSystemUIFont',
        'Helvetica Neue',
        'Arial',
        'Lucida Grande',
        'sans-serif',
      ]),
    );
  });
}
