import 'package:equatable/equatable.dart';

/// 不地道的英文表达及解释实体/值对象
class UnnaturalExpressionItem extends Equatable {
  final String original;
  final String naturalAlternative;
  final String mindsetBridge;

  const UnnaturalExpressionItem({
    required this.original,
    required this.naturalAlternative,
    required this.mindsetBridge,
  });

  Map<String, dynamic> toJson() {
    return {
      'original': original,
      'naturalAlternative': naturalAlternative,
      'mindsetBridge': mindsetBridge,
    };
  }

  factory UnnaturalExpressionItem.fromJson(Map<String, dynamic> json) {
    return UnnaturalExpressionItem(
      original: json['original'] as String? ?? '',
      naturalAlternative: json['naturalAlternative'] as String? ?? '',
      mindsetBridge: json['mindsetBridge'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [original, naturalAlternative, mindsetBridge];
}
