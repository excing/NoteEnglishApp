import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:note_english_flutter/domain/models/analysis/diary_analysis_result.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/inquiry/inquiry_turn.dart';

/// 随笔梳理状态
enum DiaryAnalysisStatus {
  draft('草稿'),
  analyzing('主编梳理中'),
  completed('已梳理'),
  failed('梳理失败');

  final String label;
  const DiaryAnalysisStatus(this.label);
}

/// 随笔日记聚合根
class DiaryEntry extends Equatable {
  final String id;
  final String content;
  final DiaryMetadata metadata;
  final DiaryAnalysisStatus status;
  final DiaryAnalysisResult? analysisResult;
  final List<InquiryTurn> inquiryHistory;

  const DiaryEntry({
    required this.id,
    required this.content,
    required this.metadata,
    this.status = DiaryAnalysisStatus.draft,
    this.analysisResult,
    this.inquiryHistory = const [],
  });

  factory DiaryEntry.create({
    required String content,
    required DiaryMetadata metadata,
  }) {
    return DiaryEntry(
      id: const Uuid().v4(),
      content: content,
      metadata: metadata,
      status: DiaryAnalysisStatus.draft,
      analysisResult: null,
      inquiryHistory: const [],
    );
  }

  DiaryEntry copyWith({
    String? id,
    String? content,
    DiaryMetadata? metadata,
    DiaryAnalysisStatus? status,
    DiaryAnalysisResult? analysisResult,
    List<InquiryTurn>? inquiryHistory,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      analysisResult: analysisResult ?? this.analysisResult,
      inquiryHistory: inquiryHistory ?? this.inquiryHistory,
    );
  }

  /// 关联 AI 梳理结果，状态转为 completed
  DiaryEntry withAnalysisResult(DiaryAnalysisResult result) {
    return DiaryEntry(
      id: id,
      content: content,
      metadata: metadata,
      status: DiaryAnalysisStatus.completed,
      analysisResult: result,
      inquiryHistory: inquiryHistory,
    );
  }

  /// 更新状态为梳理中
  DiaryEntry withAnalyzing() {
    return DiaryEntry(
      id: id,
      content: content,
      metadata: metadata,
      status: DiaryAnalysisStatus.analyzing,
      analysisResult: analysisResult,
      inquiryHistory: inquiryHistory,
    );
  }

  /// 更新状态为失败
  DiaryEntry withAnalysisFailed() {
    return DiaryEntry(
      id: id,
      content: content,
      metadata: metadata,
      status: DiaryAnalysisStatus.failed,
      analysisResult: analysisResult,
      inquiryHistory: inquiryHistory,
    );
  }

  /// 追加或更新一轮用户追问
  DiaryEntry withInquiryTurn(InquiryTurn turn) {
    final existingIndex = inquiryHistory.indexWhere((t) => t.id == turn.id);
    final updatedList = existingIndex >= 0
        ? [
            ...inquiryHistory.sublist(0, existingIndex),
            turn,
            ...inquiryHistory.sublist(existingIndex + 1),
          ]
        : [...inquiryHistory, turn];

    return DiaryEntry(
      id: id,
      content: content,
      metadata: metadata,
      status: status,
      analysisResult: analysisResult,
      inquiryHistory: updatedList,
    );
  }

  /// 更新内容
  DiaryEntry withContent(String newContent, int newWordCount) {
    return DiaryEntry(
      id: id,
      content: newContent,
      metadata: metadata.copyWith(wordCount: newWordCount),
      status: status,
      analysisResult: analysisResult,
      inquiryHistory: inquiryHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'metadata': metadata.toJson(),
      'status': status.name,
      'analysisResult': analysisResult?.toJson(),
      'inquiryHistory': inquiryHistory.map((e) => e.toJson()).toList(),
    };
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String? ?? const Uuid().v4(),
      content: json['content'] as String? ?? '',
      metadata: json['metadata'] != null
          ? DiaryMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : DiaryMetadata(recordedAt: DateTime.now()),
      status: DiaryAnalysisStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DiaryAnalysisStatus.draft,
      ),
      analysisResult: json['analysisResult'] != null
          ? DiaryAnalysisResult.fromJson(
              json['analysisResult'] as Map<String, dynamic>)
          : null,
      inquiryHistory: (json['inquiryHistory'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(InquiryTurn.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        content,
        metadata,
        status,
        analysisResult,
        inquiryHistory,
      ];
}
