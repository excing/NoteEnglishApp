import 'package:note_english_flutter/domain/errors/ai_failure.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_source.dart';
import 'package:note_english_flutter/domain/models/quick_polish/quick_polish_result.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';
import 'package:note_english_flutter/domain/services/corpus_ingestion_service.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';

/// 全局快捷快速润色领域服务 (Domain Service)
class QuickPolishService {
  final IAiGateway _aiGateway;
  final IAiConfigRepository _configRepository;
  final ICorpusRepository _corpusRepository;
  final PromptTemplateEngine _promptTemplateEngine;
  final CorpusIngestionService _corpusIngestionService;

  const QuickPolishService({
    required IAiGateway aiGateway,
    required IAiConfigRepository configRepository,
    required ICorpusRepository corpusRepository,
    PromptTemplateEngine promptTemplateEngine = const PromptTemplateEngine(),
    CorpusIngestionService corpusIngestionService = const CorpusIngestionService(),
  })  : _aiGateway = aiGateway,
        _configRepository = configRepository,
        _corpusRepository = corpusRepository,
        _promptTemplateEngine = promptTemplateEngine,
        _corpusIngestionService = corpusIngestionService;

  /// 执行快速润色并将高级表达自动沉淀至语料库
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

    final promptBundle = _promptTemplateEngine.buildQuickPolishPromptBundle(
      selectedText: trimmed,
      customSystemPrompt: config.customSystemPrompt,
    );

    final result = await _aiGateway.quickPolish(
      promptBundle: promptBundle,
      config: config,
      originalText: rawText,
    );

    // 静默高价值语料入库
    if (result.extractedCorpus.isNotEmpty) {
      try {
        final existingCorpus = await _corpusRepository.getAllCorpus();
        final existingSet = existingCorpus.map((e) => e.expression).toSet();

        final newItems = _corpusIngestionService.ingestDrafts(
          drafts: result.extractedCorpus,
          source: CorpusSource(
            diaryId: '',
            sourceSnippet: trimmed.length > 60 ? '${trimmed.substring(0, 60)}...' : trimmed,
            sourceType: CorpusSourceType.quickPolish,
            createdAt: DateTime.now(),
          ),
          existingExpressions: existingSet,
        );

        for (final item in newItems) {
          await _corpusRepository.save(item);
        }
      } catch (_) {
        // 语料入库失败不应中断或影响输入框文本的原地替换
      }
    }

    return result;
  }
}
