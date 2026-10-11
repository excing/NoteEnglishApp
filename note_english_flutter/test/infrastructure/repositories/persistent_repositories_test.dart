import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/domain/models/analysis/diary_analysis_result.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_item.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_source.dart';
import 'package:note_english_flutter/domain/models/corpus/mastery_status.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/models/inquiry/inquiry_response.dart';
import 'package:note_english_flutter/domain/models/inquiry/inquiry_turn.dart';
import 'package:note_english_flutter/infrastructure/repositories/local_corpus_repository.dart';
import 'package:note_english_flutter/infrastructure/repositories/local_diary_repository.dart';
import 'package:note_english_flutter/infrastructure/repositories/secure_ai_config_repository.dart';
import 'package:note_english_flutter/infrastructure/storage/file_storage_engine.dart';

void main() {
  late Directory tempDir;
  late FileStorageEngine storageEngine;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('note_english_repo_test_');
    storageEngine = FileStorageEngine(customDirectory: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Persistent Repositories Integration Tests (TDD)', () {
    test('LocalDiaryRepository persists and restores diaries across instances', () async {
      final repo1 = LocalDiaryRepository(storageEngine: storageEngine);
      final turn = InquiryTurn.create(
        userQuestion: '为什么用 clock out？',
        response: const InquiryStructuredResponse(
          reply: '形象生活',
          keyTakeaway: '动词替换',
        ),
      );
      final entry = DiaryEntry.create(
        content: 'Today I worked late into the rain.',
        metadata: DiaryMetadata(
          recordedAt: DateTime(2026, 10, 11, 20, 0),
          weather: WeatherCondition.rainy,
          wordCount: 7,
        ),
      ).withAnalysisResult(const DiaryAnalysisResult(
        originalStyleEnglishVersion: 'I worked late.',
        authenticAdvancedVersion: 'Clocked out late.',
      )).withInquiryTurn(turn);

      await repo1.saveEntry(entry);

      // 验证通过另一个全新实例（模拟应用关闭重启）读取持久化数据
      final repo2 = LocalDiaryRepository(storageEngine: storageEngine);
      final entries = await repo2.getAllEntries();

      expect(entries.length, 1);
      final restored = entries.first;
      expect(restored.id, entry.id);
      expect(restored.content, 'Today I worked late into the rain.');
      expect(restored.metadata.weather, WeatherCondition.rainy);
      expect(restored.analysisResult?.authenticAdvancedVersion, 'Clocked out late.');
      expect(restored.inquiryHistory.length, 1);
      expect(restored.inquiryHistory.first.userQuestion, '为什么用 clock out？');
    });

    test('LocalCorpusRepository persists items and mastery state changes across instances', () async {
      final repo1 = LocalCorpusRepository(storageEngine: storageEngine);
      final item = CorpusItem.create(
        expression: 'clock out',
        phonetic: '/klɒk aʊt/',
        meaning: '打卡下班',
        usageContext: '口语动词',
        source: CorpusSource(
          diaryId: 'd1',
          sourceSnippet: 'worked late',
          sourceType: CorpusSourceType.analysis,
          createdAt: DateTime(2026, 10, 11, 12, 0),
        ),
      );

      await repo1.save(item);
      await repo1.updateMastery(item.id, MasteryStatus.internalized);

      // 新建实例模拟重启
      final repo2 = LocalCorpusRepository(storageEngine: storageEngine);
      final all = await repo2.getAllCorpus();

      expect(all.length, 1);
      expect(all.first.expression, 'clock out');
      expect(all.first.masteryStatus, MasteryStatus.internalized);
      expect(all.first.reviewCount, 1);
    });

    test('SecureAiConfigRepository persists AI profile configuration across instances', () async {
      final repo1 = SecureAiConfigRepository(storageEngine: storageEngine);
      const customConfig = AiProfileConfig(
        baseUrl: 'https://api.my-ai-proxy.com/v1',
        apiKey: 'sk-user-secret-key-12345',
        selectedModel: 'deepseek-chat',
        customSystemPrompt: '你是一名毒舌主编',
      );

      await repo1.saveConfig(customConfig);

      // 新建实例模拟重启
      final repo2 = SecureAiConfigRepository(storageEngine: storageEngine);
      final loaded = await repo2.getConfig();

      expect(loaded.baseUrl, 'https://api.my-ai-proxy.com/v1');
      expect(loaded.apiKey, 'sk-user-secret-key-12345');
      expect(loaded.selectedModel, 'deepseek-chat');
      expect(loaded.customSystemPrompt, '你是一名毒舌主编');
      expect(loaded.isConfigured, isTrue);
    });
  });
}
