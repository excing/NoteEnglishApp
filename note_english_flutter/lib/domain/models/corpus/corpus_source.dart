import 'package:equatable/equatable.dart';

/// 语料来源类型
enum CorpusSourceType {
  analysis('随笔梳理'),
  inquiry('交互追问'),
  quickPolish('快捷润色');

  final String label;
  const CorpusSourceType(this.label);
}

/// 语料来源溯源值对象
class CorpusSource extends Equatable {
  final String diaryId;
  final String sourceSnippet;
  final CorpusSourceType sourceType;
  final DateTime createdAt;

  const CorpusSource({
    required this.diaryId,
    required this.sourceSnippet,
    required this.sourceType,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'diaryId': diaryId,
      'sourceSnippet': sourceSnippet,
      'sourceType': sourceType.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CorpusSource.fromJson(Map<String, dynamic> json) {
    final typeName = json['sourceType'] as String?;
    final resolvedType = CorpusSourceType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => CorpusSourceType.analysis,
    );

    return CorpusSource(
      diaryId: json['diaryId'] as String? ?? '',
      sourceSnippet: json['sourceSnippet'] as String? ?? '',
      sourceType: resolvedType,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [diaryId, sourceSnippet, sourceType, createdAt];
}
