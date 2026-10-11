import 'package:equatable/equatable.dart';

/// 待入库的语料草稿值对象 (从 AI 结构化输出中自动抽取)
class CorpusItemDraft extends Equatable {
  final String expression;
  final String phonetic;
  final String meaning;
  final String usageContext;

  const CorpusItemDraft({
    required this.expression,
    required this.phonetic,
    required this.meaning,
    required this.usageContext,
  });

  Map<String, dynamic> toJson() {
    return {
      'expression': expression,
      'phonetic': phonetic,
      'meaning': meaning,
      'usageContext': usageContext,
    };
  }

  factory CorpusItemDraft.fromJson(Map<String, dynamic> json) {
    return CorpusItemDraft(
      expression: json['expression'] as String? ?? '',
      phonetic: json['phonetic'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      usageContext: json['usageContext'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [expression, phonetic, meaning, usageContext];
}
