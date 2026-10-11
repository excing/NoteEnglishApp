import 'package:equatable/equatable.dart';
import 'package:note_english_flutter/domain/contracts/ai_contracts.dart';
import 'package:note_english_flutter/domain/models/analysis/correction_item.dart';
import 'package:note_english_flutter/domain/models/analysis/translation_item.dart';
import 'package:note_english_flutter/domain/models/analysis/unnatural_expression_item.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_draft.dart';

/// 随笔梳理结构化结果聚合实体
class DiaryAnalysisResult extends Equatable {
  final List<NonEnglishTranslationItem> nonEnglishItems;
  final List<ExpressionCorrectionItem> incorrectExpressions;
  final String originalStyleEnglishVersion;
  final List<UnnaturalExpressionItem> unnaturalExpressions;
  final String authenticAdvancedVersion;
  final List<CorpusItemDraft> extractedCorpus;

  const DiaryAnalysisResult({
    this.nonEnglishItems = const [],
    this.incorrectExpressions = const [],
    required this.originalStyleEnglishVersion,
    this.unnaturalExpressions = const [],
    required this.authenticAdvancedVersion,
    this.extractedCorpus = const [],
  });

  /// 业务便捷判断：若无非英文字词，UI 层自适应不予显示
  bool get hasNonEnglishItems => nonEnglishItems.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      AiContracts.keyNonEnglish: nonEnglishItems.map((e) => e.toJson()).toList(),
      AiContracts.keyIncorrectExpressions:
          incorrectExpressions.map((e) => e.toJson()).toList(),
      AiContracts.keyOriginalStyleVersion: originalStyleEnglishVersion,
      AiContracts.keyUnnaturalExpressions:
          unnaturalExpressions.map((e) => e.toJson()).toList(),
      AiContracts.keyAuthenticAdvancedVersion: authenticAdvancedVersion,
      AiContracts.keyExtractedCorpus:
          extractedCorpus.map((e) => e.toJson()).toList(),
    };
  }

  factory DiaryAnalysisResult.fromJson(Map<String, dynamic> json) {
    final rawNonEnglish = json[AiContracts.keyNonEnglish] as List<dynamic>? ?? [];
    final rawIncorrect =
        json[AiContracts.keyIncorrectExpressions] as List<dynamic>? ?? [];
    final rawUnnatural =
        json[AiContracts.keyUnnaturalExpressions] as List<dynamic>? ?? [];
    final rawCorpus = json[AiContracts.keyExtractedCorpus] as List<dynamic>? ?? [];

    return DiaryAnalysisResult(
      nonEnglishItems: rawNonEnglish
          .whereType<Map<String, dynamic>>()
          .map(NonEnglishTranslationItem.fromJson)
          .toList(),
      incorrectExpressions: rawIncorrect
          .whereType<Map<String, dynamic>>()
          .map(ExpressionCorrectionItem.fromJson)
          .toList(),
      originalStyleEnglishVersion:
          json[AiContracts.keyOriginalStyleVersion] as String? ?? '',
      unnaturalExpressions: rawUnnatural
          .whereType<Map<String, dynamic>>()
          .map(UnnaturalExpressionItem.fromJson)
          .toList(),
      authenticAdvancedVersion:
          json[AiContracts.keyAuthenticAdvancedVersion] as String? ?? '',
      extractedCorpus: rawCorpus
          .whereType<Map<String, dynamic>>()
          .map(CorpusItemDraft.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        nonEnglishItems,
        incorrectExpressions,
        originalStyleEnglishVersion,
        unnaturalExpressions,
        authenticAdvancedVersion,
        extractedCorpus,
      ];
}
