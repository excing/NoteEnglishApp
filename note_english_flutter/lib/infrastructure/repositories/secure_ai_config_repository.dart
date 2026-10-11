import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';

/// 基于安全存储的 AI 接口配置仓储实现
class SecureAiConfigRepository implements IAiConfigRepository {
  final FlutterSecureStorage _secureStorage;
  static const String _keyProfile = 'ai_profile_config_v1';
  static const String _keyApiKey = 'ai_profile_api_key_v1';

  AiProfileConfig? _cachedConfig;

  SecureAiConfigRepository({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<AiProfileConfig> getConfig() async {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    try {
      final rawJson = await _secureStorage.read(key: _keyProfile);
      final storedApiKey = await _secureStorage.read(key: _keyApiKey) ?? '';

      if (rawJson != null) {
        final map = json.decode(rawJson) as Map<String, dynamic>;
        final config = AiProfileConfig.fromJson(map).copyWith(
          apiKey: storedApiKey,
        );
        _cachedConfig = config;
        return config;
      }
    } catch (_) {
      // 容错降级
    }

    final defaultConfig = const AiProfileConfig();
    _cachedConfig = defaultConfig;
    return defaultConfig;
  }

  @override
  Future<void> saveConfig(AiProfileConfig config) async {
    _cachedConfig = config;
    final map = config.toJson();
    // API Key 单独使用安全键存储
    map.remove('apiKey');

    try {
      await _secureStorage.write(key: _keyProfile, value: json.encode(map));
      await _secureStorage.write(key: _keyApiKey, value: config.apiKey.trim());
    } catch (_) {
      // 在钥匙串受限环境下静默回退使用内存缓存
    }
  }
}
