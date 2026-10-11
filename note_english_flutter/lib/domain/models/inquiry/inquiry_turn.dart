import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:note_english_flutter/domain/models/inquiry/inquiry_response.dart';

/// 单轮用户追问实体
class InquiryTurn extends Equatable {
  final String id;
  final String userQuestion;
  final InquiryStructuredResponse response;
  final DateTime timestamp;

  const InquiryTurn({
    required this.id,
    required this.userQuestion,
    required this.response,
    required this.timestamp,
  });

  factory InquiryTurn.create({
    required String userQuestion,
    required InquiryStructuredResponse response,
  }) {
    return InquiryTurn(
      id: const Uuid().v4(),
      userQuestion: userQuestion.trim(),
      response: response,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userQuestion': userQuestion,
      'response': response.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory InquiryTurn.fromJson(Map<String, dynamic> json) {
    return InquiryTurn(
      id: json['id'] as String? ?? const Uuid().v4(),
      userQuestion: json['userQuestion'] as String? ?? '',
      response: InquiryStructuredResponse.fromJson(
        json['response'] as Map<String, dynamic>? ?? {},
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, userQuestion, response, timestamp];
}
