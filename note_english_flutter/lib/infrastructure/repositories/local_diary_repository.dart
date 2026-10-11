import 'dart:async';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';

/// 本地响应式随笔仓储实现 (支持全平台)
class LocalDiaryRepository implements IDiaryRepository {
  final Map<String, DiaryEntry> _entries = {};
  final _controller = StreamController<List<DiaryEntry>>.broadcast();

  LocalDiaryRepository({List<DiaryEntry>? initialEntries}) {
    if (initialEntries != null) {
      for (final entry in initialEntries) {
        _entries[entry.id] = entry;
      }
    }
  }

  @override
  Future<List<DiaryEntry>> getAllEntries() async {
    final list = _entries.values.toList()
      ..sort((a, b) => b.metadata.recordedAt.compareTo(a.metadata.recordedAt));
    return list;
  }

  @override
  Future<DiaryEntry?> getEntryById(String id) async {
    return _entries[id];
  }

  @override
  Future<void> saveEntry(DiaryEntry entry) async {
    _entries[entry.id] = entry;
    _emit();
  }

  @override
  Future<void> deleteEntry(String id) async {
    _entries.remove(id);
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
