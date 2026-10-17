import 'dart:async';
import 'dart:convert';
import 'package:note_english_flutter/domain/models/corpus/corpus_item.dart';
import 'package:note_english_flutter/domain/models/corpus/mastery_status.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';
import 'package:note_english_flutter/infrastructure/storage/file_storage_engine.dart';

/// 本地响应式持久化语料库仓储实现 (支持全平台)
class LocalCorpusRepository implements ICorpusRepository {
  static const String _storageKey = 'corpus_v1.json';

  final IStorageEngine? _storageEngine;
  final Map<String, CorpusItem> _items = {};
  final _controller = StreamController<List<CorpusItem>>.broadcast();
  bool _initialized = false;

  LocalCorpusRepository({
    List<CorpusItem>? initialItems,
    IStorageEngine? storageEngine,
  }) : _storageEngine = storageEngine {
    if (initialItems != null) {
      for (final item in initialItems) {
        _items[item.id] = item;
      }
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;

    if (_storageEngine != null) {
      try {
        final raw = await _storageEngine.readString(_storageKey);
        if (raw != null && raw.trim().isNotEmpty) {
          final decoded = json.decode(raw);
          if (decoded is List) {
            for (final item in decoded) {
              if (item is Map<String, dynamic>) {
                final corpus = CorpusItem.fromJson(item);
                _items.putIfAbsent(corpus.id, () => corpus);
              }
            }
          }
        }
      } catch (_) {
        // 容错降级
      }
    }
  }

  Future<void> _persist() async {
    if (_storageEngine == null) return;
    try {
      final list = _items.values.map((e) => e.toJson()).toList();
      await _storageEngine.writeString(_storageKey, json.encode(list));
    } catch (_) {}
  }

  @override
  Future<List<CorpusItem>> getAllCorpus() async {
    await _ensureInitialized();
    final list = _items.values.toList()
      ..sort((a, b) => b.source.createdAt.compareTo(a.source.createdAt));
    return list;
  }

  @override
  Future<List<CorpusItem>> getCorpusByDiaryId(String diaryId) async {
    await _ensureInitialized();
    final list = _items.values
        .where((e) => e.source.diaryId == diaryId)
        .toList()
      ..sort((a, b) => b.source.createdAt.compareTo(a.source.createdAt));
    return list;
  }

  @override
  Future<void> saveBatch(List<CorpusItem> items) async {
    await _ensureInitialized();
    for (final item in items) {
      _items[item.id] = item;
    }
    await _persist();
    _emit();
  }

  @override
  Future<void> save(CorpusItem item) async {
    await _ensureInitialized();
    _items[item.id] = item;
    await _persist();
    _emit();
  }

  @override
  Future<void> updateMastery(String id, MasteryStatus status) async {
    await _ensureInitialized();
    final existing = _items[id];
    if (existing != null) {
      _items[id] = existing.copyWith(
        masteryStatus: status,
        reviewCount: existing.reviewCount + 1,
        lastReviewedAt: DateTime.now(),
      );
      await _persist();
      _emit();
    }
  }

  @override
  Future<Set<String>> getExistingExpressions() async {
    await _ensureInitialized();
    return _items.values
        .map((e) => e.expression.trim().toLowerCase())
        .toSet();
  }

  Future<void> delete(String id) async {
    await _ensureInitialized();
    _items.remove(id);
    await _persist();
    _emit();
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
