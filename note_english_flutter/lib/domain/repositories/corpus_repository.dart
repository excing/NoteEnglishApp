import 'package:note_english_flutter/domain/models/corpus/corpus_item.dart';
import 'package:note_english_flutter/domain/models/corpus/mastery_status.dart';

/// 语料资产持久化仓储接口 (DDD Repository Interface)
abstract class ICorpusRepository {
  /// 获取所有已收录语料
  Future<List<CorpusItem>> getAllCorpus();

  /// 批量入库新语料
  Future<void> saveBatch(List<CorpusItem> items);

  /// 保存或更新单个语料
  Future<void> save(CorpusItem item);

  /// 更新语料掌握状态与复习计数
  Future<void> updateMastery(String id, MasteryStatus status);

  /// 获取所有已知语料的表达式集合 (用于去重)
  Future<Set<String>> getExistingExpressions();

  /// 依据随笔 ID 查找关联语料
  Future<List<CorpusItem>> getCorpusByDiaryId(String diaryId);

  /// 响应式监听语料数据流
  Stream<List<CorpusItem>> watchAllCorpus();
}
