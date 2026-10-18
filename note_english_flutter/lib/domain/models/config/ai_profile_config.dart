import 'package:equatable/equatable.dart';
import 'package:note_english_flutter/domain/models/config/ai_provider_type.dart';
import 'package:note_english_flutter/domain/models/config/built_in_ai_service.dart';

/// 用户自定义 AI 接口配置聚合根
class AiProfileConfig extends Equatable {
  final String serviceId;
  final AiProviderType providerType;
  final String baseUrl;
  final String apiKey;
  final String selectedModel;
  final String customSystemPrompt;
  final Map<String, String> customHeaders;
  final bool isDeepThinking;

  const AiProfileConfig({
    this.serviceId = 'ovh_ai',
    this.providerType = AiProviderType.openAiCompatible,
    this.baseUrl = 'https://oai.endpoints.kepler.ai.cloud.ovh.net/v1',
    this.apiKey = '',
    this.selectedModel = 'Qwen3.8-27B',
    this.customSystemPrompt = '',
    this.customHeaders = const {},
    this.isDeepThinking = false,
  });

  /// 当前预设服务是否要求必须提供 API Key
  bool get isApiKeyRequired {
    final service = BuiltInAiService.findById(serviceId);
    if (service != BuiltInAiService.custom) {
      return service.requiresApiKey;
    }
    return BuiltInAiService.findByBaseUrl(baseUrl).requiresApiKey;
  }

  /// 是否具备发送调用的基础凭据 (免 Key 服务只需 Base URL 不为空)
  bool get isConfigured {
    if (baseUrl.trim().isEmpty) return false;
    if (isApiKeyRequired) {
      return apiKey.trim().isNotEmpty;
    }
    return true;
  }

  AiProfileConfig copyWith({
    String? serviceId,
    AiProviderType? providerType,
    String? baseUrl,
    String? apiKey,
    String? selectedModel,
    String? customSystemPrompt,
    Map<String, String>? customHeaders,
    bool? isDeepThinking,
  }) {
    return AiProfileConfig(
      serviceId: serviceId ?? this.serviceId,
      providerType: providerType ?? this.providerType,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      selectedModel: selectedModel ?? this.selectedModel,
      customSystemPrompt: customSystemPrompt ?? this.customSystemPrompt,
      customHeaders: customHeaders ?? this.customHeaders,
      isDeepThinking: isDeepThinking ?? this.isDeepThinking,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'providerType': providerType.name,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'selectedModel': selectedModel,
      'customSystemPrompt': customSystemPrompt,
      'customHeaders': customHeaders,
      'isDeepThinking': isDeepThinking,
    };
  }

  factory AiProfileConfig.fromJson(Map<String, dynamic> json) {
    final loadedBaseUrl = json['baseUrl'] as String? ?? 'https://oai.endpoints.kepler.ai.cloud.ovh.net/v1';
    final loadedServiceId = json['serviceId'] as String? ??
        BuiltInAiService.findByBaseUrl(loadedBaseUrl).id;

    return AiProfileConfig(
      serviceId: loadedServiceId,
      providerType: AiProviderType.values.firstWhere(
        (e) => e.name == json['providerType'],
        orElse: () => AiProviderType.openAiCompatible,
      ),
      baseUrl: loadedBaseUrl,
      apiKey: json['apiKey'] as String? ?? '',
      selectedModel: json['selectedModel'] as String? ?? 'Qwen3.8-27B',
      customSystemPrompt: json['customSystemPrompt'] as String? ?? '',
      customHeaders: (json['customHeaders'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
      isDeepThinking: json['isDeepThinking'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        serviceId,
        providerType,
        baseUrl,
        apiKey,
        selectedModel,
        customSystemPrompt,
        customHeaders,
        isDeepThinking,
      ];
}
