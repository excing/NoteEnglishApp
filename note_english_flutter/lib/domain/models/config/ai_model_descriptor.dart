import 'package:equatable/equatable.dart';

/// 动态获取的模型描述信息
class AiModelDescriptor extends Equatable {
  final String id;
  final String? ownedBy;
  final String? description;

  const AiModelDescriptor({
    required this.id,
    this.ownedBy,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownedBy': ownedBy,
      'description': description,
    };
  }

  factory AiModelDescriptor.fromJson(Map<String, dynamic> json) {
    return AiModelDescriptor(
      id: json['id'] as String? ?? '',
      ownedBy: json['owned_by'] as String? ?? json['ownedBy'] as String?,
      description: json['description'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, ownedBy, description];
}
