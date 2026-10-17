import 'dart:async';
import 'dart:convert';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';
import 'package:note_english_flutter/infrastructure/storage/file_storage_engine.dart';

/// 本地响应式持久化随笔仓储实现 (支持全平台)
class LocalDiaryRepository implements IDiaryRepository {
  static const String _storageKey = 'diaries_v1.json';

  final IStorageEngine? _storageEngine;
  final Map<String, DiaryEntry> _entries = {};
  final _controller = StreamController<List<DiaryEntry>>.broadcast();
  bool _initialized = false;

  LocalDiaryRepository({
    List<DiaryEntry>? initialEntries,
    IStorageEngine? storageEngine,
  }) : _storageEngine = storageEngine {
    if (initialEntries != null) {
      for (final entry in initialEntries) {
        _entries[entry.id] = entry;
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
                final entry = DiaryEntry.fromJson(item);
                // 仅当内存中不存在时载入，不覆盖显式传入的 initialEntries
                _entries.putIfAbsent(entry.id, () => entry);
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
      final list = _entries.values.map((e) => e.toJson()).toList();
      await _storageEngine.writeString(_storageKey, json.encode(list));
    } catch (_) {}
  }

  @override
  Future<List<DiaryEntry>> getAllEntries() async {
    await _ensureInitialized();
    final list = _entries.values.toList()
      ..sort((a, b) => b.metadata.recordedAt.compareTo(a.metadata.recordedAt));
    return list;
  }

  @override
  Future<DiaryEntry?> getEntryById(String id) async {
    await _ensureInitialized();
    return _entries[id];
  }

  @override
  Future<void> saveEntry(DiaryEntry entry) async {
    await _ensureInitialized();
    _entries[entry.id] = entry;
    await _persist();
    _emit();
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _ensureInitialized();
    _entries.remove(id);
    await _persist();
    _emit();
  }

  @override
  Stream<List<DiaryEntry>> watchAllEntries() async* {
    yield await getAllEntries();
    yield* _controller.stream;
  }

  void _emit() {
    final list = _entries.values.toList()
      ..sort((a, b) => b.metadata.recordedAt.compareTo(a.metadata.recordedAt));
    _controller.add(list);
  }

  void dispose() {
    _controller.close();
  }
}
