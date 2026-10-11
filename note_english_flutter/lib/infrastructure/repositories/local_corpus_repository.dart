import 'dart:async';
import 'package:note_english_flutter/domain/models/corpus/corpus_item.dart';
import 'package:note_english_flutter/domain/models/corpus/mastery_status.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';

/// 本地响应式语料库仓储实现 (支持全平台)
class LocalCorpusRepository implements ICorpusRepository {
  final Map<String, CorpusItem> _items = {};
  final _controller = StreamController<List<CorpusItem>>.broadcast();

  LocalCorpusRepository({List<CorpusItem>? initialItems}) {
    if (initialItems != null) {
      for (final item in initialItems) {
        _items[item.id] = item;
      }
    }
  }

  @override
  Future<List<CorpusItem>> getAllCorpus() async {
    final list = _items.values.toList()
      ..sort((a, b) => b.source.createdAt.compareTo(a.source.createdAt));
    return list;
  }

  @override
  Future<void> saveBatch(List<CorpusItem> items) async {
    for (final item in items) {
      _items[item.id] = item;
    }
    _emit();
  }

  @override
  Future<void> save(CorpusItem item) async {
    _items[item.id] = item;
    _emit();
  }

  @override
  Future<void> updateMastery(String id, MasteryStatus status) async {
    final existing = _items[id];
    if (existing != null) {
      _items[id] = existing.copyWith(
        masteryStatus: status,
        reviewCount: existing.reviewCount + 1,
        lastReviewedAt: DateTime.now(),
      );
      _emit();
    }
  }

  @override
  Future<Set<String>> getExistingExpressions() async {
    return _items.values
        .map((e) => e.expression.trim().toLowerCase())
        .toSet();
  }

  @override
  Future<List<CorpusItem>> getCorpusByDiaryId(String diaryId) async {
    return _items.values
        .where((e) => e.source.diaryId == diaryId)
        .toList();
  }

  @override
  Stream<List<CorpusItem>> watchAllCorpus() async* {
    yield await getAllCorpus();
    yield* _controller.stream;
  }

  void _emit() {
    final list = _items.values.toList()
      ..sort((a, b) => b.source.createdAt.compareTo(a.source.createdAt));
    _controller.add(list);
  }

  void dispose() {
    _controller.close();
  }
}
