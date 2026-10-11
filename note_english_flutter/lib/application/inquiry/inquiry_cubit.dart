import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_english_flutter/domain/errors/ai_failure.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_source.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/inquiry/inquiry_response.dart';
import 'package:note_english_flutter/domain/models/inquiry/inquiry_turn.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';
import 'package:note_english_flutter/domain/services/corpus_ingestion_service.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';

/// 追问状态
class InquiryState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<InquiryTurn> history;
  final int silentCorpusCount;

  const InquiryState({
    this.isLoading = false,
    this.errorMessage,
    this.history = const [],
    this.silentCorpusCount = 0,
  });

  InquiryState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<InquiryTurn>? history,
    int? silentCorpusCount,
  }) {
    return InquiryState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      history: history ?? this.history,
      silentCorpusCount: silentCorpusCount ?? this.silentCorpusCount,
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, history, silentCorpusCount];
}

/// 追问管理 Cubit
class InquiryCubit extends Cubit<InquiryState> {
  final IDiaryRepository _diaryRepository;
  final ICorpusRepository _corpusRepository;
  final IAiConfigRepository _configRepository;
  final IAiGateway _aiGateway;
  final PromptTemplateEngine _promptEngine;
  final CorpusIngestionService _corpusService;

  InquiryCubit({
    required IDiaryRepository diaryRepository,
    required ICorpusRepository corpusRepository,
    required IAiConfigRepository configRepository,
    required IAiGateway aiGateway,
    PromptTemplateEngine promptEngine = const PromptTemplateEngine(),
    CorpusIngestionService corpusService = const CorpusIngestionService(),
    List<InquiryTurn> initialHistory = const [],
  })  : _diaryRepository = diaryRepository,
        _corpusRepository = corpusRepository,
        _configRepository = configRepository,
        _aiGateway = aiGateway,
        _promptEngine = promptEngine,
        _corpusService = corpusService,
        super(InquiryState(history: initialHistory));

  /// 向 AI 发起情境追问
  Future<void> askQuestion({
    required String question,
    required DiaryEntry currentEntry,
  }) async {
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty) return;

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final config = await _configRepository.getConfig();
      if (!config.isConfigured) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: '尚未配置 AI 接口，请先在右上角【设置】中配置 API Key 与端点',
        ));
        return;
      }

      final historyTurns = state.history
          .map((t) => HistoryTurnItem(
                question: t.userQuestion,
                answer: t.response.reply,
              ))
          .toList();

      final analysisContext = currentEntry.analysisResult != null
          ? currentEntry.analysisResult!.toJson().toString()
          : '暂无梳理结果';

      final promptBundle = _promptEngine.buildInquiryPromptBundle(
        diaryContent: currentEntry.content,
        analysisContext: analysisContext,
        historyTurns: historyTurns,
        userQuestion: trimmedQuestion,
        customSystemPrompt: config.customSystemPrompt,
      );

      final response = await _aiGateway.inquire(
        promptBundle: promptBundle,
        config: config,
      );

      // 追问中提取的语料静默自动入库
      int newCorpusCount = 0;
      if (response.extractedCorpus.isNotEmpty) {
        final existing = await _corpusRepository.getExistingExpressions();
        final corpusSource = CorpusSource(
          diaryId: currentEntry.id,
          sourceSnippet: trimmedQuestion,
          sourceType: CorpusSourceType.inquiry,
          createdAt: DateTime.now(),
        );

        final items = _corpusService.ingestDrafts(
          drafts: response.extractedCorpus,
          source: corpusSource,
          existingExpressions: existing,
        );

        if (items.isNotEmpty) {
          await _corpusRepository.saveBatch(items);
          newCorpusCount = items.length;
        }
      }

      final turn = InquiryTurn.create(
        userQuestion: trimmedQuestion,
        response: response,
      );

      final updatedHistory = [...state.history, turn];
      final updatedEntry = currentEntry.withInquiryTurn(turn);
      await _diaryRepository.saveEntry(updatedEntry);

      emit(state.copyWith(
        isLoading: false,
        history: updatedHistory,
        silentCorpusCount: newCorpusCount,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e is AiFailure ? e.message : '追问解答失败: $e',
      ));
    }
  }
}
