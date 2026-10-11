import 'package:equatable/equatable.dart';

/// 非英文字词翻译及解释实体/值对象
class NonEnglishTranslationItem extends Equatable {
  final String original;
  final String meaning;
  final String explanation;

  const NonEnglishTranslationItem({
    required this.original,
    required this.meaning,
    required this.explanation,
  });

  Map<String, dynamic> toJson() {
    return {
      'original': original,
      'meaning': meaning,
      'explanation': explanation,
    };
  }

  factory NonEnglishTranslationItem.fromJson(Map<String, dynamic> json) {
    return NonEnglishTranslationItem(
      original: json['original'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [original, meaning, explanation];
}
