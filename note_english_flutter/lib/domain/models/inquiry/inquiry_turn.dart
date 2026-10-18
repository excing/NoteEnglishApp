import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:note_english_flutter/domain/models/inquiry/inquiry_response.dart';

/// 追问回合生命周期状态
enum InquiryTurnStatus {
  pending,
  success,
  failed,
}

/// 单轮用户追问实体
class InquiryTurn extends Equatable {
  final String id;
  final String userQuestion;
  final InquiryStructuredResponse? response;
  final InquiryTurnStatus status;
  final String? failureMessage;
  final DateTime timestamp;

  const InquiryTurn({
    required this.id,
    required this.userQuestion,
    this.response,
    this.status = InquiryTurnStatus.success,
    this.failureMessage,
    required this.timestamp,
  });

  bool get isPending => status == InquiryTurnStatus.pending;
  bool get isSuccess => status == InquiryTurnStatus.success;
  bool get isFailed => status == InquiryTurnStatus.failed;

  factory InquiryTurn.create({
    required String userQuestion,
    required InquiryStructuredResponse response,
  }) {
    return InquiryTurn(
      id: const Uuid().v4(),
      userQuestion: userQuestion.trim(),
      response: response,
      status: InquiryTurnStatus.success,
      timestamp: DateTime.now(),
    );
  }

  factory InquiryTurn.pending({
    String? id,
    required String userQuestion,
  }) {
    return InquiryTurn(
      id: id ?? const Uuid().v4(),
      userQuestion: userQuestion.trim(),
      response: null,
      status: InquiryTurnStatus.pending,
      timestamp: DateTime.now(),
    );
  }

  factory InquiryTurn.success({
    required String id,
    required String userQuestion,
    required InquiryStructuredResponse response,
    DateTime? timestamp,
  }) {
    return InquiryTurn(
      id: id,
      userQuestion: userQuestion.trim(),
      response: response,
      status: InquiryTurnStatus.success,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  factory InquiryTurn.failed({
    required String id,
    required String userQuestion,
    required String failureMessage,
    DateTime? timestamp,
  }) {
    return InquiryTurn(
      id: id,
      userQuestion: userQuestion.trim(),
      response: null,
      status: InquiryTurnStatus.failed,
      failureMessage: failureMessage,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  InquiryTurn toSuccess(InquiryStructuredResponse response) {
    return InquiryTurn(
      id: id,
      userQuestion: userQuestion,
      response: response,
      status: InquiryTurnStatus.success,
      failureMessage: null,
      timestamp: timestamp,
    );
  }

  InquiryTurn toFailed(String failureMessage) {
    return InquiryTurn(
      id: id,
      userQuestion: userQuestion,
      response: null,
      status: InquiryTurnStatus.failed,
      failureMessage: failureMessage,
      timestamp: timestamp,
    );
  }

  InquiryTurn toPending() {
    return InquiryTurn(
      id: id,
      userQuestion: userQuestion,
      response: null,
      status: InquiryTurnStatus.pending,
      failureMessage: null,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userQuestion': userQuestion,
      'response': response?.toJson() ?? {},
      'status': status.name,
      'failureMessage': failureMessage,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory InquiryTurn.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String?;
    final status = InquiryTurnStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => InquiryTurnStatus.success,
    );
    final rawResp = json['response'] as Map<String, dynamic>?;
    final hasResp = rawResp != null && rawResp.isNotEmpty;

    return InquiryTurn(
      id: json['id'] as String? ?? const Uuid().v4(),
      userQuestion: json['userQuestion'] as String? ?? '',
      response: hasResp ? InquiryStructuredResponse.fromJson(rawResp) : null,
      status: status,
      failureMessage: json['failureMessage'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, userQuestion, response, status, failureMessage, timestamp];
}
