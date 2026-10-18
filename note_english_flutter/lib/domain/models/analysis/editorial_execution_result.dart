import 'package:equatable/equatable.dart';
import 'package:note_english_flutter/domain/models/analysis/diary_analysis_result.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';

/// 统一主编梳理与快捷润色执行结果对象
class EditorialExecutionResult extends Equatable {
  final DiaryEntry entry;
  final DiaryAnalysisResult analysisResult;
  final int silentCorpusCount;

  const EditorialExecutionResult({
    required this.entry,
    required this.analysisResult,
    this.silentCorpusCount = 0,
  });

  /// 地道化重塑文本（用于系统划词原地替换：优先进阶版，次优原味版，兜底原文）
  String get polishedText {
    final advanced = analysisResult.authenticAdvancedVersion.trim();
    if (advanced.isNotEmpty) return advanced;
    final originalStyle = analysisResult.originalStyleEnglishVersion.trim();
    if (originalStyle.isNotEmpty) return originalStyle;
    return entry.content;
  }

  @override
  List<Object?> get props => [entry, analysisResult, silentCorpusCount];
}
