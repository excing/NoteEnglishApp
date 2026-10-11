import 'package:equatable/equatable.dart';
import 'package:note_english_flutter/domain/models/config/ai_provider_type.dart';

/// 用户自定义 AI 接口配置聚合根
class AiProfileConfig extends Equatable {
  final AiProviderType providerType;
  final String baseUrl;
  final String apiKey;
  final String selectedModel;
  final String customSystemPrompt;
  final Map<String, String> customHeaders;

  const AiProfileConfig({
    this.providerType = AiProviderType.openAiCompatible,
    this.baseUrl = 'https://api.openai.com/v1',
    this.apiKey = '',
    this.selectedModel = '',
    this.customSystemPrompt = '',
    this.customHeaders = const {},
  });

  /// 是否具备发送调用的基础凭据
  bool get isConfigured => apiKey.trim().isNotEmpty && baseUrl.trim().isNotEmpty;

  AiProfileConfig copyWith({
    AiProviderType? providerType,
    String? baseUrl,
    String? apiKey,
    String? selectedModel,
    String? customSystemPrompt,
    Map<String, String>? customHeaders,
  }) {
    return AiProfileConfig(
      providerType: providerType ?? this.providerType,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      selectedModel: selectedModel ?? this.selectedModel,
      customSystemPrompt: customSystemPrompt ?? this.customSystemPrompt,
      customHeaders: customHeaders ?? this.customHeaders,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'providerType': providerType.name,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'selectedModel': selectedModel,
      'customSystemPrompt': customSystemPrompt,
      'customHeaders': customHeaders,
    };
  }

  factory AiProfileConfig.fromJson(Map<String, dynamic> json) {
    return AiProfileConfig(
      providerType: AiProviderType.values.firstWhere(
        (e) => e.name == json['providerType'],
        orElse: () => AiProviderType.openAiCompatible,
      ),
      baseUrl: json['baseUrl'] as String? ?? 'https://api.openai.com/v1',
      apiKey: json['apiKey'] as String? ?? '',
      selectedModel: json['selectedModel'] as String? ?? 'gpt-4o',
      customSystemPrompt: json['customSystemPrompt'] as String? ?? '',
      customHeaders: (json['customHeaders'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
    );
  }

  @override
  List<Object?> get props => [
        providerType,
        baseUrl,
        apiKey,
        selectedModel,
        customSystemPrompt,
        customHeaders,
      ];
}
