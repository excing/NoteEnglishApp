import 'package:equatable/equatable.dart';
import 'package:note_english_flutter/domain/contracts/ai_contracts.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_draft.dart';

/// 快捷快速润色结果实体
class QuickPolishResult extends Equatable {
  final String originalText;
  final String polishedText;
  final List<CorpusItemDraft> extractedCorpus;
  final int durationMs;

  const QuickPolishResult({
    required this.originalText,
    required this.polishedText,
    this.extractedCorpus = const [],
    this.durationMs = 0,
  });

  factory QuickPolishResult.fromJson({
    required Map<String, dynamic> json,
    required String originalText,
    int durationMs = 0,
  }) {
    final rawCorpus = json[AiContracts.keyExtractedCorpus] as List<dynamic>? ?? [];
    final corpusList = rawCorpus
        .whereType<Map<String, dynamic>>()
        .map(CorpusItemDraft.fromJson)
        .toList();

    return QuickPolishResult(
      originalText: originalText,
      polishedText: json[AiContracts.keyQuickPolishedText] as String? ?? originalText,
      extractedCorpus: corpusList,
      durationMs: durationMs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      AiContracts.keyQuickPolishedText: polishedText,
      AiContracts.keyExtractedCorpus: extractedCorpus.map((e) => e.toJson()).toList(),
      'durationMs': durationMs,
    };
  }

  @override
  List<Object?> get props => [originalText, polishedText, extractedCorpus, durationMs];
}
