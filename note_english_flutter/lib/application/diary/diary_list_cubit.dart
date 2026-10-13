import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';

/// 随笔列表与管理状态 (Diary List State)
class DiaryListState extends Equatable {
  final List<DiaryEntry> entries;
  final String searchQuery;
  final String? activeEntryId;
  final bool isLoading;
  final String? errorMessage;

  const DiaryListState({
    this.entries = const [],
    this.searchQuery = '',
    this.activeEntryId,
    this.isLoading = false,
    this.errorMessage,
  });

  /// 依据搜索词过滤随笔
  List<DiaryEntry> get filteredEntries {
    if (searchQuery.trim().isEmpty) {
      return entries;
    }
    final query = searchQuery.toLowerCase().trim();
    return entries.where((e) {
      final contentMatches = e.content.toLowerCase().contains(query);
      final weatherMatches = e.metadata.weather.label.toLowerCase().contains(query);
      return contentMatches || weatherMatches;
    }).toList();
  }

  DiaryListState copyWith({
    List<DiaryEntry>? entries,
    String? searchQuery,
    String? activeEntryId,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DiaryListState(
      entries: entries ?? this.entries,
      searchQuery: searchQuery ?? this.searchQuery,
      activeEntryId: activeEntryId ?? this.activeEntryId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        entries,
        searchQuery,
        activeEntryId,
        isLoading,
        errorMessage,
      ];
}

/// 随笔列表与生命周期管理 Cubit
class DiaryListCubit extends Cubit<DiaryListState> {
  final IDiaryRepository _diaryRepository;
  StreamSubscription<List<DiaryEntry>>? _subscription;

  DiaryListCubit({
    required IDiaryRepository diaryRepository,
    String? initialActiveEntryId,
  })  : _diaryRepository = diaryRepository,
        super(DiaryListState(activeEntryId: initialActiveEntryId)) {
    _startWatching();
  }

  void _startWatching() {
    _subscription = _diaryRepository.watchAllEntries().listen(
      (updatedEntries) {
        emit(state.copyWith(
          entries: updatedEntries,
          isLoading: false,
        ));
      },
      onError: (err) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: '实时同步随笔失败: $err',
        ));
      },
    );
  }

  /// 手动载入所有随笔
  Future<void> loadEntries() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final list = await _diaryRepository.getAllEntries();
      emit(state.copyWith(entries: list, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: '获取随笔列表失败: $e'));
    }
  }

  /// 设置搜索关键词
  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  /// 设置当前正在编辑的活跃随笔 ID
  void setActiveEntryId(String id) {
    emit(state.copyWith(activeEntryId: id));
  }

  /// 创建全新随笔并存盘
  Future<DiaryEntry> createEntry({WeatherCondition? weather}) async {
    final newEntry = DiaryEntry.create(
      content: '',
      metadata: DiaryMetadata(
        recordedAt: DateTime.now(),
        weather: weather ?? WeatherCondition.sunny,
      ),
    );
    await _diaryRepository.saveEntry(newEntry);
    emit(state.copyWith(activeEntryId: newEntry.id));
    return newEntry;
  }

  /// 删除指定随笔
  Future<void> deleteEntry(String id) async {
    try {
      await _diaryRepository.deleteEntry(id);
    } catch (e) {
      emit(state.copyWith(errorMessage: '删除随笔失败: $e'));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
