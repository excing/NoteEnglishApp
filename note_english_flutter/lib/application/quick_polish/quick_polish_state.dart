import 'package:equatable/equatable.dart';
import 'package:note_english_flutter/domain/models/analysis/editorial_execution_result.dart';

enum QuickPolishStatus { idle, processing, success, failure }

class QuickPolishState extends Equatable {
  final QuickPolishStatus status;
  final EditorialExecutionResult? lastResult;
  final String? errorMessage;
  final bool isAccessibilityGranted;
  final bool isEnabled;

  const QuickPolishState({
    this.status = QuickPolishStatus.idle,
    this.lastResult,
    this.errorMessage,
    this.isAccessibilityGranted = true,
    this.isEnabled = false,
  });

  QuickPolishState copyWith({
    QuickPolishStatus? status,
    EditorialExecutionResult? lastResult,
    String? errorMessage,
    bool? isAccessibilityGranted,
    bool? isEnabled,
  }) {
    return QuickPolishState(
      status: status ?? this.status,
      lastResult: lastResult ?? this.lastResult,
      errorMessage: errorMessage,
      isAccessibilityGranted: isAccessibilityGranted ?? this.isAccessibilityGranted,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  List<Object?> get props => [
        status,
        lastResult,
        errorMessage,
        isAccessibilityGranted,
        isEnabled,
      ];
}
