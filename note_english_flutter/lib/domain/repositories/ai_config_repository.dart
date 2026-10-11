import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';

/// AI 接口配置仓储接口
abstract class IAiConfigRepository {
  /// 获取当前生效的 AI 配置
  Future<AiProfileConfig> getConfig();

  /// 保存/更新 AI 配置
  Future<void> saveConfig(AiProfileConfig config);
}
