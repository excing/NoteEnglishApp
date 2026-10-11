import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_item.dart';
import 'package:note_english_flutter/domain/models/corpus/mastery_status.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';

/// 语料库卡片与复习状态
class CorpusDeckState extends Equatable {
  final List<CorpusItem> items;
  final bool isLoading;
  final String? errorMessage;

  const CorpusDeckState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CorpusDeckState copyWith({
    List<CorpusItem>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CorpusDeckState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [items, isLoading, errorMessage];
}

/// 语料库卡片与复习管理 Cubit
class CorpusDeckCubit extends Cubit<CorpusDeckState> {
  final ICorpusRepository _corpusRepository;

  CorpusDeckCubit({required ICorpusRepository corpusRepository})
      : _corpusRepository = corpusRepository,
        super(const CorpusDeckState()) {
    loadAll();
  }

  /// 加载所有语料
  Future<void> loadAll() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final items = await _corpusRepository.getAllCorpus();
      emit(state.copyWith(items: items, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: '加载语料库失败: $e'));
    }
  }

  /// 更新单条语料掌握程度
  Future<void> updateMastery({
    required String id,
    required MasteryStatus status,
  }) async {
    try {
      await _corpusRepository.updateMastery(id, status);
      await loadAll();
    } catch (e) {
      emit(state.copyWith(errorMessage: '更新掌握状态失败: $e'));
    }
  }
}
