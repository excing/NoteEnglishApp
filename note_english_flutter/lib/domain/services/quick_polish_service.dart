import 'package:note_english_flutter/domain/errors/ai_failure.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_source.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/quick_polish/quick_polish_result.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';
import 'package:note_english_flutter/domain/services/corpus_ingestion_service.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';

/// 全局快捷润色领域服务 (集成用户日记与 AI 主编梳理闭环)
class QuickPolishService {
  final IAiGateway _aiGateway;
  final IAiConfigRepository _configRepository;
  final ICorpusRepository _corpusRepository;
  final IDiaryRepository? _diaryRepository;
  final PromptTemplateEngine _promptTemplateEngine;
  final CorpusIngestionService _corpusIngestionService;

  const QuickPolishService({
    required IAiGateway aiGateway,
    required IAiConfigRepository configRepository,
    required ICorpusRepository corpusRepository,
    IDiaryRepository? diaryRepository,
    PromptTemplateEngine promptTemplateEngine = const PromptTemplateEngine(),
    CorpusIngestionService corpusIngestionService = const CorpusIngestionService(),
  })  : _aiGateway = aiGateway,
        _configRepository = configRepository,
        _corpusRepository = corpusRepository,
        _diaryRepository = diaryRepository,
        _promptTemplateEngine = promptTemplateEngine,
        _corpusIngestionService = corpusIngestionService;

  /// 执行快捷润色：执行完整的 AI 主编梳理流程，自动生成随笔笔记落库，并沉淀高价值语料
  Future<QuickPolishResult> executeQuickPolish(String rawText) async {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      return QuickPolishResult(
        originalText: rawText,
        polishedText: rawText,
      );
    }

    final config = await _configRepository.getConfig();
    if (!config.isConfigured) {
      throw const AiConfigNotSetFailure('AI 配置未就绪，请先在 OtterJot 设置中填写 API Key');
    }

    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .length;
    final metadata = DiaryMetadata(
      recordedAt: DateTime.now(),
      wordCount: words,
    );

    // 1. 装配完整的主编梳理提示词
    final promptBundle = _promptTemplateEngine.buildAnalysisPromptBundle(
      metadata: metadata,
      diaryContent: trimmed,
      customSystemPrompt: config.customSystemPrompt,
    );

    // 2. 调用 AI 网关执行主编深度梳理
    final analysisResult = await _aiGateway.analyzeDiary(
      promptBundle: promptBundle,
      config: config,
    );

    // 3. 提取母语级地道英文（若为空则回退原汁原味版或原文）
    final polishedText = analysisResult.authenticAdvancedVersion.trim().isNotEmpty
        ? analysisResult.authenticAdvancedVersion.trim()
        : (analysisResult.originalStyleEnglishVersion.trim().isNotEmpty
            ? analysisResult.originalStyleEnglishVersion.trim()
            : rawText);

    // 4. 将用户本次润色内容作为一篇全新随笔/笔记落库保存
    final entry = DiaryEntry.create(
      content: trimmed,
      metadata: metadata,
    ).withAnalysisResult(analysisResult);

    if (_diaryRepository != null) {
      try {
        await _diaryRepository.saveEntry(entry);
      } catch (_) {
        // 日记落库失败不阻断输入框的原地替换
      }
    }

    // 5. 将主编梳理提炼的高价值语料静默存入语料库
    if (analysisResult.extractedCorpus.isNotEmpty) {
      try {
        final existingExpressions = await _corpusRepository.getExistingExpressions();
        final newItems = _corpusIngestionService.ingestDrafts(
          drafts: analysisResult.extractedCorpus,
          source: CorpusSource(
            diaryId: entry.id,
            sourceSnippet: trimmed.length > 60 ? '${trimmed.substring(0, 60)}...' : trimmed,
            sourceType: CorpusSourceType.quickPolish,
            createdAt: DateTime.now(),
          ),
          existingExpressions: existingExpressions,
        );

        if (newItems.isNotEmpty) {
          await _corpusRepository.saveBatch(newItems);
        }
      } catch (_) {
        // 语料入库失败不阻断文本替换
      }
    }

    return QuickPolishResult(
      originalText: rawText,
      polishedText: polishedText,
      extractedCorpus: analysisResult.extractedCorpus,
    );
  }
}
