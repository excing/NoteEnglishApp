import 'package:note_english_flutter/domain/errors/ai_failure.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/gateways/weather_gateway.dart';
import 'package:note_english_flutter/domain/models/analysis/editorial_execution_result.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_source.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/weather/current_weather_report.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';
import 'package:note_english_flutter/domain/services/corpus_ingestion_service.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';

/// 统一主编梳理与快捷润色领域服务 (Single Source of Truth)
///
/// 应用内【呼叫主编】与系统工具栏【快捷润色】统一调用本服务，
/// 保证两者的业务生命周期、天气预检、Prompt 模板、模型调用与入库机制 100% 一致。
class EditorialAnalysisService {
  final IAiGateway _aiGateway;
  final IAiConfigRepository _configRepository;
  final ICorpusRepository _corpusRepository;
  final IDiaryRepository _diaryRepository;
  final IWeatherGateway? _weatherGateway;
  final PromptTemplateEngine _promptTemplateEngine;
  final CorpusIngestionService _corpusIngestionService;

  const EditorialAnalysisService({
    required IAiGateway aiGateway,
    required IAiConfigRepository configRepository,
    required ICorpusRepository corpusRepository,
    required IDiaryRepository diaryRepository,
    IWeatherGateway? weatherGateway,
    PromptTemplateEngine promptTemplateEngine = const PromptTemplateEngine(),
    CorpusIngestionService corpusIngestionService = const CorpusIngestionService(),
  })  : _aiGateway = aiGateway,
        _configRepository = configRepository,
        _corpusRepository = corpusRepository,
        _diaryRepository = diaryRepository,
        _weatherGateway = weatherGateway,
        _promptTemplateEngine = promptTemplateEngine,
        _corpusIngestionService = corpusIngestionService;

  IWeatherGateway? get weatherGateway => _weatherGateway;

  /// 执行统一的主编深度梳理/润色流程
  ///
  /// - [rawText]: 待梳理正文（必填）；
  /// - [existingEntry]: 若在随笔书房中已有当前编辑的随笔，则传入；若在系统栏快捷润色无上下文时传入 null，将自动创建新随笔；
  /// - [cityName]: 用户指定查询天气的城市名称（可选）；
  /// - [sourceType]: 语料入库来源标识（默认 analysis，快捷润色传 quickPolish）。
  Future<EditorialExecutionResult> executeAnalysis({
    required String rawText,
    DiaryEntry? existingEntry,
    String? cityName,
    CorpusSourceType sourceType = CorpusSourceType.analysis,
  }) async {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('请先写下您的随笔再呼叫主编');
    }

    // 1. 校验 AI 配置是否有效
    final config = await _configRepository.getConfig();
    if (!config.isConfigured) {
      throw const AiConfigNotSetFailure('尚未配置 AI 接口，请先点击右上角【设置】配置 API Key 与端点');
    }

    // 2. 统计字数并准备随笔基准对象
    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .length;

    var targetEntry = existingEntry?.withContent(trimmed, words) ??
        DiaryEntry.create(
          content: trimmed,
          metadata: DiaryMetadata(
            recordedAt: DateTime.now(),
            wordCount: words,
          ),
        );

    // 3. 天气微气候预检与补齐：若随笔未获取过真实天气，自动静默获取一次
    if (!targetEntry.metadata.hasRealtimeWeather && _weatherGateway != null) {
      try {
        final effectiveCity = cityName?.trim().isNotEmpty == true
            ? cityName!.trim()
            : (targetEntry.metadata.location?.trim().isNotEmpty == true
                ? targetEntry.metadata.location!.trim()
                : null);

        final CurrentWeatherReport report;
        if (effectiveCity != null) {
          report = await _weatherGateway.fetchWeatherByCity(effectiveCity);
        } else {
          report = await _weatherGateway.fetchWeatherAuto();
        }

        final updatedMetadata = targetEntry.metadata.copyWith(
          weather: report.condition,
          location: report.locationName ?? effectiveCity,
          temperature: report.temperature,
          apparentTemperature: report.apparentTemperature,
          humidity: report.relativeHumidity,
          isDay: report.isDay,
          detailedWeather: report.effectiveDetailedDescription,
        );
        targetEntry = targetEntry.copyWith(metadata: updatedMetadata);
        await _diaryRepository.saveEntry(targetEntry);
      } catch (_) {
        // 天气获取失败静默降级，不阻断主流程
      }
    }

    // 4. 装配统一的主编深度梳理提示词 (Single Source of Truth)
    final promptBundle = _promptTemplateEngine.buildAnalysisPromptBundle(
      metadata: targetEntry.metadata,
      diaryContent: trimmed,
      customSystemPrompt: config.customSystemPrompt,
    );

    // 5. 调用统一 AI 网关进行深度梳理
    final analysisResult = await _aiGateway.analyzeDiary(
      promptBundle: promptBundle,
      config: config,
    );

    // 6. 提炼高价值语料并静默存入用户语料库
    int newCorpusCount = 0;
    if (analysisResult.extractedCorpus.isNotEmpty) {
      try {
        final existing = await _corpusRepository.getExistingExpressions();
        final corpusSource = CorpusSource(
          diaryId: targetEntry.id,
          sourceSnippet: trimmed.length > 60
              ? '${trimmed.substring(0, 60)}...'
              : trimmed,
          sourceType: sourceType,
          createdAt: DateTime.now(),
        );

        final items = _corpusIngestionService.ingestDrafts(
          drafts: analysisResult.extractedCorpus,
          source: corpusSource,
          existingExpressions: existing,
        );

        if (items.isNotEmpty) {
          await _corpusRepository.saveBatch(items);
          newCorpusCount = items.length;
        }
      } catch (_) {
        // 语料入库异常不阻断主流程
      }
    }

    // 7. 随笔深度梳理成果存盘落库
    final completedEntry = targetEntry.withAnalysisResult(analysisResult);
    try {
      await _diaryRepository.saveEntry(completedEntry);
    } catch (_) {
      // 随笔存盘异常不阻断结果返回
    }

    return EditorialExecutionResult(
      entry: completedEntry,
      analysisResult: analysisResult,
      silentCorpusCount: newCorpusCount,
    );
  }
}
