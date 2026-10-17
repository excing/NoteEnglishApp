import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/domain/models/analysis/diary_analysis_result.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_draft.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_source.dart';
import 'package:note_english_flutter/domain/models/corpus/mastery_status.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/services/corpus_ingestion_service.dart';

void main() {
  group('CorpusIngestionService Tests (TDD)', () {
    late CorpusIngestionService service;

    setUp(() {
      service = const CorpusIngestionService();
    });

    test('should transform drafts into CorpusItems with source anchors', () {
      final drafts = [
        const CorpusItemDraft(
          expression: 'relentless downpour',
          phonetic: '/rɪˈlentləs ˈdaʊnpɔːr/',
          meaning: '倾盆大雨',
          usageContext: '替代简单的 rain heavily',
        ),
        const CorpusItemDraft(
          expression: 'clock out',
          phonetic: '/klɒk aʊt/',
          meaning: '打卡下班',
          usageContext: '动词质感强烈',
        ),
      ];

      final source = CorpusSource(
        diaryId: 'diary-123',
        sourceSnippet: 'outside is raining heavily',
        sourceType: CorpusSourceType.analysis,
        createdAt: DateTime(2026, 10, 10, 21, 30),
      );

      final items = service.ingestDrafts(
        drafts: drafts,
        source: source,
        existingExpressions: {'clock out'}, // 模拟已存在 "clock out"
      );

      // 去重：因为 "clock out" 已存在，应只生成新入库的 "relentless downpour"
      expect(items.length, 1);
      final newItem = items.first;
      expect(newItem.expression, 'relentless downpour');
      expect(newItem.masteryStatus, MasteryStatus.encountered);
      expect(newItem.source.diaryId, 'diary-123');
      expect(newItem.source.sourceType, CorpusSourceType.analysis);
    });
  });

  group('DiaryEntry Aggregate Root Tests', () {
    test('should create diary entry and attach analysis result immutably', () {
      final entry = DiaryEntry.create(
        content: 'Today is a great day.',
        metadata: DiaryMetadata(
          recordedAt: DateTime(2026, 10, 10),
          weather: WeatherCondition.sunny,
          wordCount: 5,
        ),
      );

      expect(entry.status, DiaryAnalysisStatus.draft);
      expect(entry.analysisResult, isNull);

      const mockAnalysis = DiaryAnalysisResult(
        originalStyleEnglishVersion: 'Today was a wonderful day.',
        authenticAdvancedVersion: 'The day unfolded wonderfully.',
      );

      final updatedEntry = entry.withAnalysisResult(mockAnalysis);

      expect(updatedEntry.status, DiaryAnalysisStatus.completed);
      expect(updatedEntry.analysisResult, mockAnalysis);
      // 原实体保持不可变性
      expect(entry.status, DiaryAnalysisStatus.draft);
      expect(entry.analysisResult, isNull);
    });
  });
}
