import 'package:equatable/equatable.dart';

/// 内置预设 AI 服务单一信源定义
class BuiltInAiService extends Equatable {
  final String id;
  final String name;
  final String baseUrl;
  final bool requiresApiKey;
  final String defaultModel;
  final List<String> presetModels;
  final String description;

  const BuiltInAiService({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.requiresApiKey,
    required this.defaultModel,
    this.presetModels = const [],
    this.description = '',
  });

  /// OVHcloud AI 官方免 API key 开放端点
  static const BuiltInAiService ovhAi = BuiltInAiService(
    id: 'ovh_ai',
    name: 'OVHcloud AI (免 API Key)',
    baseUrl: 'https://oai.endpoints.kepler.ai.cloud.ovh.net/v1',
    requiresApiKey: false,
    defaultModel: 'Qwen3.8-27B',
    presetModels: [
      'Qwen3.8-27B',
      'meta-llama/Meta-Llama-3.1-70B-Instruct',
      'Mistral-7B-Instruct-v0.2',
      'meta-llama/Meta-Llama-3-8B-Instruct',
    ],
    description: '免 API Key',
  );

  /// OpenAI 官方
  static const BuiltInAiService openAi = BuiltInAiService(
    id: 'openai',
    name: 'OpenAI 官方',
    baseUrl: 'https://api.openai.com/v1',
    requiresApiKey: true,
    defaultModel: 'gpt-4o',
    presetModels: [
      'gpt-4o',
      'gpt-4o-mini',
      'gpt-4-turbo',
    ],
    description: 'OpenAI 官方开放接口 (需提供有效 API Key)',
  );

  /// DeepSeek 官方
  static const BuiltInAiService deepSeek = BuiltInAiService(
    id: 'deepseek',
    name: 'DeepSeek',
    baseUrl: 'https://api.deepseek.com/v1',
    requiresApiKey: true,
    defaultModel: 'deepseek-chat',
    presetModels: [
      'deepseek-chat',
      'deepseek-reasoner',
    ],
    description: 'DeepSeek 开放接口 (需提供有效 API Key)',
  );

  /// 自定义 OpenAI 兼容端点
  static const BuiltInAiService custom = BuiltInAiService(
    id: 'custom',
    name: '自定义 (OpenAI 兼容协议)',
    baseUrl: '',
    requiresApiKey: true,
    defaultModel: '',
    presetModels: [],
    description: '支持任意兼容 OpenAI 标准协议的中转或自建网关',
  );

  /// 默认 AI 预设服务
  static const BuiltInAiService defaultService = ovhAi;

  /// 系统内置支持的所有服务定义单一信源 (OVH AI 作为首选默认)
  static const List<BuiltInAiService> allServices = [
    ovhAi,
    openAi,
    deepSeek,
    custom,
  ];

  /// 根据 Base URL 查找对应的服务，未匹配则返回 custom
  static BuiltInAiService findByBaseUrl(String url) {
    final normalized = _normalize(url);
    if (normalized.isEmpty) return custom;
    for (final service in allServices) {
      if (service.baseUrl.isNotEmpty && _normalize(service.baseUrl) == normalized) {
        return service;
      }
    }
    return custom;
  }

  /// 根据 ID 查找服务，未匹配则返回 custom
  static BuiltInAiService findById(String? id) {
    if (id == null || id.isEmpty) return custom;
    for (final service in allServices) {
      if (service.id == id) {
        return service;
      }
    }
    return custom;
  }

  static String _normalize(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        baseUrl,
        requiresApiKey,
        defaultModel,
        presetModels,
        description,
      ];
}
