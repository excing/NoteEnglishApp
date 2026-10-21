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
import 'package:note_english_flutter/domain/services/editorial_analysis_service.dart';
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
  final IWeatherGateway? _weatherGateway;
  IWeatherGateway? get weatherGateway => _weatherGateway;
  final EditorialAnalysisService _editorialAnalysisService;
  EditorialAnalysisService get editorialAnalysisService => _editorialAnalysisService;

  /// 用户最后一次手动指定或确认的位置（内存持久化，用于跨随笔或新建随笔时记忆用户常用城市）
  static String? lastUserSelectedLocation;

  DiaryEditorialCubit({
    required IDiaryRepository diaryRepository,
    required ICorpusRepository corpusRepository,
    required IAiConfigRepository configRepository,
    required IAiGateway aiGateway,
    IWeatherGateway? weatherGateway,
    PromptTemplateEngine promptEngine = const PromptTemplateEngine(),
    CorpusIngestionService corpusService = const CorpusIngestionService(),
    EditorialAnalysisService? editorialAnalysisService,
    required DiaryEntry initialEntry,
  })  : _diaryRepository = diaryRepository,
        _weatherGateway = weatherGateway,
        _editorialAnalysisService = editorialAnalysisService ??
            EditorialAnalysisService(
              aiGateway: aiGateway,
              configRepository: configRepository,
              corpusRepository: corpusRepository,
              diaryRepository: diaryRepository,
              weatherGateway: weatherGateway,
              promptTemplateEngine: promptEngine,
              corpusIngestionService: corpusService,
            ),
        super(DiaryEditorialState(
          entry: initialEntry,
          status: initialEntry.status,
        )) {
    if (initialEntry.metadata.location?.trim().isNotEmpty == true) {
      lastUserSelectedLocation = initialEntry.metadata.location!.trim();
    }
  }

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
    if (newEntry.metadata.location?.trim().isNotEmpty == true) {
      lastUserSelectedLocation = newEntry.metadata.location!.trim();
    }
    emit(DiaryEditorialState(
      entry: newEntry,
      status: newEntry.status,
    ));
  }

  /// 切换天气
  void updateWeather(WeatherCondition weather) {
    final updated = state.entry.copyWith(
      metadata: state.entry.metadata.copyWith(
        weather: weather,
        detailedWeather: weather.label,
      ),
    );
    emit(state.copyWith(entry: updated));
    _diaryRepository.saveEntry(updated);
  }

  /// 获取并自动应用真实实时天气 (Open-Meteo)
  ///
  /// 若用户指定了 [cityName]，则优先按指定城市获取并记录为用户位置；
  /// 若未指定 [cityName]：
  /// - 优先继承当前随笔原本已有的 [location]；
  /// - 其次继承用户此前输入/选择过的最后位置 [lastUserSelectedLocation]；
  /// - 仅在完全没有任何已知用户输入位置时，才降级执行全局自动定位/默认城市。
  /// [silentOnError] 为 true 时，如果获取天气失败将静默处理，不发射 errorMessage。
  Future<void> fetchAndApplyRealtimeWeather({
    String? cityName,
    bool silentOnError = false,
  }) async {
    if (_weatherGateway == null) return;
    try {
      final effectiveCity = cityName?.trim().isNotEmpty == true
          ? cityName!.trim()
          : (state.entry.metadata.location?.trim().isNotEmpty == true
              ? state.entry.metadata.location!.trim()
              : (lastUserSelectedLocation?.trim().isNotEmpty == true
                  ? lastUserSelectedLocation!.trim()
                  : null));

      CurrentWeatherReport report;
      if (effectiveCity != null) {
        try {
          report = await _weatherGateway.fetchWeatherByCity(effectiveCity);
          lastUserSelectedLocation = report.locationName ?? effectiveCity;
        } catch (_) {
          // 位置是「继承」来的（IP 反查得到的乡镇/区县名，例如 "Haidong Zhen"
          // 或 "市南区"）时常无法被地理编码解析。此时不应直接报错，而是降级为
          // IP/默认坐标自动定位；只有用户显式输入的城市才把错误抛给用户。
          if (cityName != null) rethrow;
          report = await _weatherGateway.fetchWeatherAuto();
          lastUserSelectedLocation = report.locationName ?? effectiveCity;
        }
      } else {
        report = await _weatherGateway.fetchWeatherAuto();
      }
      final updated = state.entry.copyWith(
        metadata: state.entry.metadata.copyWith(
          weather: report.condition,
          location: report.locationName ?? effectiveCity,
          temperature: report.temperature,
          apparentTemperature: report.apparentTemperature,
          humidity: report.relativeHumidity,
          isDay: report.isDay,
          detailedWeather: report.effectiveDetailedDescription,
        ),
      );
      emit(state.copyWith(entry: updated, errorMessage: null));
      await _diaryRepository.saveEntry(updated);
    } catch (e) {
      if (!silentOnError) {
        emit(state.copyWith(errorMessage: '获取实时天气失败: $e'));
      }
    }
  }

  /// 呼叫主编：发起 AI 梳理 (委托统一 EditorialAnalysisService 单一信源入口)
  Future<void> requestAiAnalysis() async {
    final content = state.entry.content.trim();
    if (content.isEmpty) {
      emit(state.copyWith(errorMessage: '请先写下您的随笔再呼叫主编'));
      return;
    }

    emit(state.copyWith(status: DiaryAnalysisStatus.analyzing, errorMessage: null));

    try {
      final result = await _editorialAnalysisService.executeAnalysis(
        rawText: content,
        existingEntry: state.entry,
        cityName: state.entry.metadata.location ?? lastUserSelectedLocation,
        sourceType: CorpusSourceType.analysis,
      );

      emit(state.copyWith(
        entry: result.entry,
        status: DiaryAnalysisStatus.completed,
        silentCorpusCount: result.silentCorpusCount,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DiaryAnalysisStatus.failed,
        errorMessage: e is AiFailure
            ? e.message
            : (e is FormatException ? e.message : '主编梳理失败: $e'),
      ));
    }
  }
}
