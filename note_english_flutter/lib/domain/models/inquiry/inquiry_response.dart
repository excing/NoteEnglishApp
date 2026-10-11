import 'package:equatable/equatable.dart';
import 'package:note_english_flutter/domain/contracts/ai_contracts.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_draft.dart';

/// 追问 AI 返回的结构化数据实体
class InquiryStructuredResponse extends Equatable {
  final String reply;
  final String keyTakeaway;
  final List<String> examples;
  final List<CorpusItemDraft> extractedCorpus;

  const InquiryStructuredResponse({
    required this.reply,
    required this.keyTakeaway,
    this.examples = const [],
    this.extractedCorpus = const [],
  });

  /// 是否有示例展示
  bool get hasExamples => examples.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      AiContracts.keyInquiryReply: reply,
      AiContracts.keyInquiryKeyTakeaway: keyTakeaway,
      AiContracts.keyInquiryExamples: examples,
      AiContracts.keyExtractedCorpus:
          extractedCorpus.map((e) => e.toJson()).toList(),
    };
  }

  factory InquiryStructuredResponse.fromJson(Map<String, dynamic> json) {
    final rawExamples = json[AiContracts.keyInquiryExamples] as List<dynamic>? ?? [];
    final rawCorpus = json[AiContracts.keyExtractedCorpus] as List<dynamic>? ?? [];

    return InquiryStructuredResponse(
      reply: json[AiContracts.keyInquiryReply] as String? ?? '',
      keyTakeaway: json[AiContracts.keyInquiryKeyTakeaway] as String? ?? '',
      examples: rawExamples.map((e) => e.toString()).toList(),
      extractedCorpus: rawCorpus
          .whereType<Map<String, dynamic>>()
          .map(CorpusItemDraft.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [reply, keyTakeaway, examples, extractedCorpus];
}
