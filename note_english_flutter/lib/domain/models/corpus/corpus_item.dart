import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:note_english_flutter/domain/models/corpus/corpus_source.dart';
import 'package:note_english_flutter/domain/models/corpus/mastery_status.dart';

/// 语料资产聚合根
class CorpusItem extends Equatable {
  final String id;
  final String expression;
  final String phonetic;
  final String meaning;
  final String usageContext;
  final CorpusSource source;
  final MasteryStatus masteryStatus;
  final int reviewCount;
  final DateTime? lastReviewedAt;

  const CorpusItem({
    required this.id,
    required this.expression,
    required this.phonetic,
    required this.meaning,
    required this.usageContext,
    required this.source,
    this.masteryStatus = MasteryStatus.encountered,
    this.reviewCount = 0,
    this.lastReviewedAt,
  });

  factory CorpusItem.create({
    required String expression,
    required String phonetic,
    required String meaning,
    required String usageContext,
    required CorpusSource source,
  }) {
    return CorpusItem(
      id: const Uuid().v4(),
      expression: expression.trim(),
      phonetic: phonetic.trim(),
      meaning: meaning.trim(),
      usageContext: usageContext.trim(),
      source: source,
      masteryStatus: MasteryStatus.encountered,
      reviewCount: 0,
      lastReviewedAt: null,
    );
  }

  CorpusItem copyWith({
    String? expression,
    String? phonetic,
    String? meaning,
    String? usageContext,
    CorpusSource? source,
    MasteryStatus? masteryStatus,
    int? reviewCount,
    DateTime? lastReviewedAt,
  }) {
    return CorpusItem(
      id: id,
      expression: expression ?? this.expression,
      phonetic: phonetic ?? this.phonetic,
      meaning: meaning ?? this.meaning,
      usageContext: usageContext ?? this.usageContext,
      source: source ?? this.source,
      masteryStatus: masteryStatus ?? this.masteryStatus,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expression': expression,
      'phonetic': phonetic,
      'meaning': meaning,
      'usageContext': usageContext,
      'source': source.toJson(),
      'masteryStatus': masteryStatus.name,
      'reviewCount': reviewCount,
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
    };
  }

  factory CorpusItem.fromJson(Map<String, dynamic> json) {
    return CorpusItem(
      id: json['id'] as String? ?? const Uuid().v4(),
      expression: json['expression'] as String? ?? '',
      phonetic: json['phonetic'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      usageContext: json['usageContext'] as String? ?? '',
      source: json['source'] != null
          ? CorpusSource.fromJson(json['source'] as Map<String, dynamic>)
          : CorpusSource(
              diaryId: '',
              sourceSnippet: '',
              sourceType: CorpusSourceType.analysis,
              createdAt: DateTime.now(),
            ),
      masteryStatus: MasteryStatus.fromString(json['masteryStatus'] as String?),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      lastReviewedAt: json['lastReviewedAt'] != null
          ? DateTime.parse(json['lastReviewedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        expression,
        phonetic,
        meaning,
        usageContext,
        source,
        masteryStatus,
        reviewCount,
        lastReviewedAt,
      ];
}
