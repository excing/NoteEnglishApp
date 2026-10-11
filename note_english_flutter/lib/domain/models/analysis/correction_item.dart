import 'package:equatable/equatable.dart';

/// 不正确的英文表达及解释实体/值对象
class ExpressionCorrectionItem extends Equatable {
  final String original;
  final String correction;
  final String explanation;

  const ExpressionCorrectionItem({
    required this.original,
    required this.correction,
    required this.explanation,
  });

  Map<String, dynamic> toJson() {
    return {
      'original': original,
      'correction': correction,
      'explanation': explanation,
    };
  }

  factory ExpressionCorrectionItem.fromJson(Map<String, dynamic> json) {
    return ExpressionCorrectionItem(
      original: json['original'] as String? ?? '',
      correction: json['correction'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [original, correction, explanation];
}
