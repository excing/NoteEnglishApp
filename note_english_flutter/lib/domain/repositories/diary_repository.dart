import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';

/// 随笔持久化仓储接口 (DDD Repository Interface)
abstract class IDiaryRepository {
  /// 获取所有随笔 (按记录时间倒序)
  Future<List<DiaryEntry>> getAllEntries();

  /// 依据 ID 获取单篇随笔
  Future<DiaryEntry?> getEntryById(String id);

  /// 保存或更新随笔
  Future<void> saveEntry(DiaryEntry entry);

  /// 删除指定随笔
  Future<void> deleteEntry(String id);

  /// 响应式监听所有随笔数据流
  Stream<List<DiaryEntry>> watchAllEntries();
}
