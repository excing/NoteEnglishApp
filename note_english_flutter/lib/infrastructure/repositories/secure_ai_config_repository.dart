import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';
import 'package:note_english_flutter/infrastructure/storage/file_storage_engine.dart';

/// 具备文件系统持久化与可选安全存储的 AI 接口配置仓储实现
class SecureAiConfigRepository implements IAiConfigRepository {
  static const String _keyProfile = 'ai_profile_config_v1.json';
  static const String _secureApiKey = 'ai_profile_api_key_v1';

  final FlutterSecureStorage? _secureStorage;
  final IStorageEngine? _storageEngine;

  AiProfileConfig? _cachedConfig;

  SecureAiConfigRepository({
    FlutterSecureStorage? secureStorage,
    IStorageEngine? storageEngine,
  })  : _secureStorage = secureStorage,
        _storageEngine = storageEngine;

  @override
  Future<AiProfileConfig> getConfig() async {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    // 1. 优先从文件持久化引擎读取
    if (_storageEngine != null) {
      try {
        final rawJson = await _storageEngine!.readString(_keyProfile);
        if (rawJson != null && rawJson.trim().isNotEmpty) {
          final map = json.decode(rawJson) as Map<String, dynamic>;
          var config = AiProfileConfig.fromJson(map);

          // 尝试读取独立安全存储的 API Key (若存在)
          if (_secureStorage != null) {
            try {
              final secureKey = await _secureStorage!.read(key: _secureApiKey);
              if (secureKey != null && secureKey.trim().isNotEmpty) {
                config = config.copyWith(apiKey: secureKey);
              }
            } catch (_) {}
          }

          _cachedConfig = config;
          return config;
        }
      } catch (_) {}
    }

    // 2. 备选从独立 secureStorage 读取
    if (_secureStorage != null) {
      try {
        final secureKey = await _secureStorage!.read(key: _secureApiKey);
        if (secureKey != null && secureKey.trim().isNotEmpty) {
          final cfg = const AiProfileConfig().copyWith(apiKey: secureKey);
          _cachedConfig = cfg;
          return cfg;
        }
      } catch (_) {}
    }

    const defaultConfig = AiProfileConfig();
    _cachedConfig = defaultConfig;
    return defaultConfig;
  }

  @override
  Future<void> saveConfig(AiProfileConfig config) async {
    _cachedConfig = config;

    // 1. 持久化至本地文件存储 (保证全平台跨进程关闭不丢失)
    if (_storageEngine != null) {
      try {
        final map = config.toJson();
        await _storageEngine!.writeString(_keyProfile, json.encode(map));
      } catch (_) {}
    }

    // 2. 尝试向安全存储写入 API Key
    if (_secureStorage != null) {
      try {
        await _secureStorage!.write(
          key: _secureApiKey,
          value: config.apiKey.trim(),
        );
      } catch (_) {}
    }
  }
}
