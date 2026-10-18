import 'package:dio/dio.dart';
import 'package:note_english_flutter/domain/errors/ai_failure.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/models/analysis/diary_analysis_result.dart';
import 'package:note_english_flutter/domain/models/config/ai_model_descriptor.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/domain/models/inquiry/inquiry_response.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';
import 'package:note_english_flutter/infrastructure/adapters/ai/robust_json_parser.dart';

/// 真实 OpenAI 兼容协议 AI 防腐适配器实现
/// 坚决杜绝任何假数据兜底，真实请求、严格鉴权、精准透出领域异常
class OpenAiCompatibleAiGateway implements IAiGateway {
  final Dio _dio;

  OpenAiCompatibleAiGateway({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<DiaryAnalysisResult> analyzeDiary({
    required PromptBundle promptBundle,
    required AiProfileConfig config,
  }) async {
    _validateConfig(config);

    final rawText = await _sendChatCompletion(
      promptBundle: promptBundle,
      config: config,
    );

    try {
      final jsonMap = RobustJsonParser.cleanAndParse(rawText);
      return DiaryAnalysisResult.fromJson(jsonMap);
    } catch (e) {
      throw AiResponseParsingFailure(
        '主编梳理结果解析失败: ${e is FormatException ? e.message : e.toString()}',
      );
    }
  }

  @override
  Future<InquiryStructuredResponse> inquire({
    required PromptBundle promptBundle,
    required AiProfileConfig config,
  }) async {
    _validateConfig(config);

    final rawText = await _sendChatCompletion(
      promptBundle: promptBundle,
      config: config,
    );

    try {
      final jsonMap = RobustJsonParser.cleanAndParse(rawText);
      return InquiryStructuredResponse.fromJson(jsonMap);
    } catch (e) {
      throw AiResponseParsingFailure(
        '追问回复解析失败: ${e is FormatException ? e.message : e.toString()}',
      );
    }
  }

  @override
  Future<List<AiModelDescriptor>> fetchAvailableModels({
    required AiProfileConfig config,
  }) async {
    _validateConfig(config);

    final baseUrl = _normalizeBaseUrl(config.baseUrl);
    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      ...config.customHeaders,
    };
    if (config.apiKey.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.apiKey.trim()}';
    }

    try {
      final response = await _dio.get(
        '$baseUrl/models',
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final responseData = response.data;
      if (responseData is Map<String, dynamic> && responseData['data'] is List) {
        final list = responseData['data'] as List;
        final models = list
            .whereType<Map<String, dynamic>>()
            .map(AiModelDescriptor.fromJson)
            .where((m) => m.id.isNotEmpty)
            .toList();

        if (models.isNotEmpty) {
          return models;
        }
      }

      throw const AiResponseParsingFailure('服务商未返回有效的模型列表数据');
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  void _validateConfig(AiProfileConfig config) {
    if (!config.isConfigured) {
      throw const AiConfigNotSetFailure();
    }
    if (config.selectedModel.trim().isEmpty) {
      throw const AiModelNotAvailableFailure('请在设置中选择或指定要使用的 AI 模型');
    }
  }

  /// 底层通用 Chat Completion 调度
  Future<String> _sendChatCompletion({
    required PromptBundle promptBundle,
    required AiProfileConfig config,
  }) async {
    final baseUrl = _normalizeBaseUrl(config.baseUrl);
    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      ...config.customHeaders,
    };
    if (config.apiKey.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.apiKey.trim()}';
    }

    final payload = {
      'model': config.selectedModel.trim(),
      'messages': [
        {'role': 'system', 'content': promptBundle.systemPrompt},
        {'role': 'user', 'content': promptBundle.userMessage},
      ],
      'temperature': 0.7,
      'response_format': {'type': 'json_object'},
    };

    Response response;
    try {
      response = await _dio.post(
        '$baseUrl/chat/completions',
        data: payload,
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
    } on DioException catch (e) {
      // 若第三方模型不支持 response_format，尝试优雅降级重发一次
      if (e.response?.statusCode == 400 &&
          e.response?.data.toString().contains('response_format') == true) {
        try {
          payload.remove('response_format');
          response = await _dio.post(
            '$baseUrl/chat/completions',
            data: payload,
            options: Options(
              headers: headers,
              sendTimeout: const Duration(seconds: 60),
              receiveTimeout: const Duration(seconds: 90),
            ),
          );
        } on DioException catch (secondErr) {
          throw _mapDioException(secondErr);
        }
      } else {
        throw _mapDioException(e);
      }
    }

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final choices = data['choices'] as List<dynamic>?;
      if (choices != null && choices.isNotEmpty) {
        final firstChoice = choices.first as Map<String, dynamic>;
        final message = firstChoice['message'] as Map<String, dynamic>?;
        final content = message?['content'] as String?;
        if (content != null && content.trim().isNotEmpty) {
          return content;
        }
      }
    }

    throw const AiResponseParsingFailure('AI 接口未返回有效的 choices 对话内容');
  }

  AiFailure _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return const AiAuthenticationFailure();
    }
    if (statusCode == 404) {
      return const AiModelNotAvailableFailure();
    }
    if (statusCode != null && statusCode >= 500) {
      return AiServerFailure(
        statusCode: statusCode,
        message: 'AI 服务端错误 ($statusCode): ${e.response?.statusMessage ?? ''}',
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AiNetworkFailure('连接 AI 服务超时，请检查网络或代理连通性');
      case DioExceptionType.connectionError:
        return const AiNetworkFailure('无法连接到目标服务，请检查 Base URL 是否正确或代理配置');
      case DioExceptionType.badResponse:
        final serverMsg = e.response?.data is Map
            ? (e.response?.data['error']?['message']?.toString() ?? '')
            : '';
        return AiServerFailure(
          statusCode: statusCode,
          message: serverMsg.isNotEmpty
              ? '服务商报错: $serverMsg'
              : '服务商返回错误 (HTTP $statusCode)',
        );
      default:
        return AiNetworkFailure('网络请求异常: ${e.message ?? '未知错误'}');
    }
  }

  String _normalizeBaseUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
