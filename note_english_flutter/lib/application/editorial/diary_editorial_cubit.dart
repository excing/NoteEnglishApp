import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_english_flutter/domain/errors/ai_failure.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_source.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';
import 'package:note_english_flutter/domain/gateways/weather_gateway.dart';
import 'package:note_english_flutter/domain/models/weather/current_weather_report.dart';
import 'package:note_english_flutter/domain/services/corpus_ingestion_service.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';

/// 随笔与 AI 梳理状态
class DiaryEditorialState extends Equatable {
  final DiaryEntry entry;
  final DiaryAnalysisStatus status;
  final String? errorMessage;
  final int silentCorpusCount;

  const DiaryEditorialState({
    required this.entry,
    this.status = DiaryAnalysisStatus.draft,
    this.errorMessage,
    this.silentCorpusCount = 0,
  });

  DiaryEditorialState copyWith({
    DiaryEntry? entry,
    DiaryAnalysisStatus? status,
    String? errorMessage,
    int? silentCorpusCount,
  }) {
    return DiaryEditorialState(
      entry: entry ?? this.entry,
      status: status ?? this.status,
      errorMessage: errorMessage,
      silentCorpusCount: silentCorpusCount ?? this.silentCorpusCount,
    );
  }

  @override
  List<Object?> get props => [entry, status, errorMessage, silentCorpusCount];
}

/// 随笔与 AI 梳理管理 Cubit
class DiaryEditorialCubit extends Cubit<DiaryEditorialState> {
  final IDiaryRepository _diaryRepository;
  final ICorpusRepository _corpusRepository;
  final IAiConfigRepository _configRepository;
  final IAiGateway _aiGateway;
  final IWeatherGateway? _weatherGateway;
  final PromptTemplateEngine _promptEngine;
  final CorpusIngestionService _corpusService;

  DiaryEditorialCubit({
    required IDiaryRepository diaryRepository,
    required ICorpusRepository corpusRepository,
    required IAiConfigRepository configRepository,
    required IAiGateway aiGateway,
    IWeatherGateway? weatherGateway,
    PromptTemplateEngine promptEngine = const PromptTemplateEngine(),
    CorpusIngestionService corpusService = const CorpusIngestionService(),
    required DiaryEntry initialEntry,
  })  : _diaryRepository = diaryRepository,
        _corpusRepository = corpusRepository,
        _configRepository = configRepository,
        _aiGateway = aiGateway,
        _weatherGateway = weatherGateway,
        _promptEngine = promptEngine,
        _corpusService = corpusService,
        super(DiaryEditorialState(
          entry: initialEntry,
          status: initialEntry.status,
        ));

  /// 更新正文与字数
  void updateContent(String newContent) {
    final words = newContent
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .length;
    final updated = state.entry.withContent(newContent, words);
    emit(state.copyWith(entry: updated));
    _diaryRepository.saveEntry(updated);
  }

  /// 切换当前正在编辑的随笔 (无缝载入)
  void loadEntry(DiaryEntry newEntry) {
    emit(DiaryEditorialState(
      entry: newEntry,
      status: newEntry.status,
    ));
  }

  /// 切换天气
  void updateWeather(WeatherCondition weather) {
    final updated = state.entry.copyWith(
      metadata: state.entry.metadata.copyWith(weather: weather),
    );
    emit(state.copyWith(entry: updated));
    _diaryRepository.saveEntry(updated);
  }

  /// 获取并自动应用真实实时天气 (Open-Meteo)
  Future<void> fetchAndApplyRealtimeWeather({String? cityName}) async {
    if (_weatherGateway == null) return;
    try {
      final CurrentWeatherReport report;
      if (cityName != null && cityName.trim().isNotEmpty) {
        report = await _weatherGateway.fetchWeatherByCity(cityName);
      } else {
        report = await _weatherGateway.fetchWeatherAuto();
      }
      final updated = state.entry.copyWith(
        metadata: state.entry.metadata.copyWith(
          weather: report.condition,
          location: report.locationName,
        ),
      );
      emit(state.copyWith(entry: updated, errorMessage: null));
      await _diaryRepository.saveEntry(updated);
    } catch (e) {
      emit(state.copyWith(errorMessage: '获取实时天气失败: $e'));
    }
  }

  /// 呼叫主编：发起 AI 梳理
  Future<void> requestAiAnalysis() async {
    final content = state.entry.content.trim();
    if (content.isEmpty) {
      emit(state.copyWith(errorMessage: '请先写下您的随笔再呼叫主编'));
      return;
    }

    emit(state.copyWith(status: DiaryAnalysisStatus.analyzing, errorMessage: null));

    try {
      final config = await _configRepository.getConfig();
      if (!config.isConfigured) {
        emit(state.copyWith(
          status: DiaryAnalysisStatus.failed,
          errorMessage: '尚未配置 AI 接口，请先点击右上角【设置】配置 API Key 与端点',
        ));
        return;
      }

      final promptBundle = _promptEngine.buildAnalysisPromptBundle(
        metadata: state.entry.metadata,
        diaryContent: content,
        customSystemPrompt: config.customSystemPrompt,
      );

      final analysisResult = await _aiGateway.analyzeDiary(
        promptBundle: promptBundle,
        config: config,
      );

      // 语料静默提取：自动存入用户语料库 (UI 不直接展示在主梳理视图)
      int newCorpusCount = 0;
      if (analysisResult.extractedCorpus.isNotEmpty) {
        final existing = await _corpusRepository.getExistingExpressions();
        final corpusSource = CorpusSource(
          diaryId: state.entry.id,
          sourceSnippet: content.length > 60
              ? '${content.substring(0, 60)}...'
              : content,
          sourceType: CorpusSourceType.analysis,
          createdAt: DateTime.now(),
        );

        final items = _corpusService.ingestDrafts(
          drafts: analysisResult.extractedCorpus,
          source: corpusSource,
          existingExpressions: existing,
        );

        if (items.isNotEmpty) {
          await _corpusRepository.saveBatch(items);
          newCorpusCount = items.length;
        }
      }

      final completedEntry = state.entry.withAnalysisResult(analysisResult);
      await _diaryRepository.saveEntry(completedEntry);

      emit(state.copyWith(
        entry: completedEntry,
        status: DiaryAnalysisStatus.completed,
        silentCorpusCount: newCorpusCount,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DiaryAnalysisStatus.failed,
        errorMessage: e is AiFailure ? e.message : '主编梳理失败: $e',
      ));
    }
  }
}
