import 'package:note_english_flutter/domain/models/corpus/corpus_draft.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_item.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_source.dart';

/// 语料入库与去重领域服务 (Domain Service)
class CorpusIngestionService {
  const CorpusIngestionService();

  /// 将 AI 梳理或追问返回的草稿转化为正式的语料资产
  /// [existingExpressions]: 用户已有语料库中的词汇集合 (小写)，用于自动去重
  List<CorpusItem> ingestDrafts({
    required List<CorpusItemDraft> drafts,
    required CorpusSource source,
    required Set<String> existingExpressions,
  }) {
    final result = <CorpusItem>[];
    final normalizedExisting =
        existingExpressions.map((e) => e.trim().toLowerCase()).toSet();

    for (final draft in drafts) {
      final normalizedExpr = draft.expression.trim().toLowerCase();
      if (normalizedExpr.isEmpty) continue;

      // 若已有库中已收录，则跳过避免重复打扰
      if (normalizedExisting.contains(normalizedExpr)) {
        continue;
      }

      final item = CorpusItem.create(
        expression: draft.expression.trim(),
        phonetic: draft.phonetic.trim(),
        meaning: draft.meaning.trim(),
        usageContext: draft.usageContext.trim(),
        source: source,
      );

      result.add(item);
      // 同时记录进本次批处理，防止单次响应内部重复
      normalizedExisting.add(normalizedExpr);
    }

    return result;
  }
}
