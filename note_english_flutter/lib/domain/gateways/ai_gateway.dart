import 'package:note_english_flutter/domain/models/analysis/diary_analysis_result.dart';
import 'package:note_english_flutter/domain/models/config/ai_model_descriptor.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/domain/models/inquiry/inquiry_response.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';

/// AI 防腐网关接口 (Anti-Corruption Layer Gateway Interface)
abstract class IAiGateway {
  /// 执行随笔 AI 梳理
  Future<DiaryAnalysisResult> analyzeDiary({
    required PromptBundle promptBundle,
    required AiProfileConfig config,
  });

  /// 执行情境追问
  Future<InquiryStructuredResponse> inquire({
    required PromptBundle promptBundle,
    required AiProfileConfig config,
  });

  /// 动态获取平台支持的模型列表
  Future<List<AiModelDescriptor>> fetchAvailableModels({
    required AiProfileConfig config,
  });
}
