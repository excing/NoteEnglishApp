import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/domain/models/config/built_in_ai_service.dart';

void main() {
  group('BuiltInAiService Domain Model & Single Source of Truth (TDD)', () {
    test('BuiltInAiService.ovhAi contains correct endpoint, default Qwen3.8-27B model and keyless setting', () {
      final ovh = BuiltInAiService.ovhAi;

      expect(ovh.id, 'ovh_ai');
      expect(ovh.baseUrl, 'https://oai.endpoints.kepler.ai.cloud.ovh.net/v1');
      expect(ovh.requiresApiKey, isFalse);
      expect(ovh.defaultModel, 'Qwen3.8-27B');
      expect(ovh.presetModels, contains('Qwen3.8-27B'));
    });

    test('defaultService is BuiltInAiService.ovhAi', () {
      expect(BuiltInAiService.defaultService, BuiltInAiService.ovhAi);
    });

    test('allServices contains ovhAi as first item, openAi, deepSeek, and custom', () {
      final services = BuiltInAiService.allServices;
      final ids = services.map((s) => s.id).toList();

      expect(services.first, BuiltInAiService.ovhAi);
      expect(ids, containsAll(['ovh_ai', 'openai', 'deepseek', 'custom']));
    });

    test('findByBaseUrl correctly recognizes known endpoints with normalization', () {
      expect(
        BuiltInAiService.findByBaseUrl('https://oai.endpoints.kepler.ai.cloud.ovh.net/v1'),
        BuiltInAiService.ovhAi,
      );
      expect(
        BuiltInAiService.findByBaseUrl('https://oai.endpoints.kepler.ai.cloud.ovh.net/v1/'),
        BuiltInAiService.ovhAi,
      );
      expect(
        BuiltInAiService.findByBaseUrl('https://api.openai.com/v1'),
        BuiltInAiService.openAi,
      );
      expect(
        BuiltInAiService.findByBaseUrl('https://custom-proxy.internal.com/v1'),
        BuiltInAiService.custom,
      );
    });

    test('findById resolves service or falls back to custom', () {
      expect(BuiltInAiService.findById('ovh_ai'), BuiltInAiService.ovhAi);
      expect(BuiltInAiService.findById('openai'), BuiltInAiService.openAi);
      expect(BuiltInAiService.findById('unknown_id'), BuiltInAiService.custom);
      expect(BuiltInAiService.findById(null), BuiltInAiService.custom);
    });
  });

  group('AiProfileConfig Integration with BuiltInAiService (TDD)', () {
    test('default constructor defaults to OVH AI and Qwen3.8-27B', () {
      const defaultConfig = AiProfileConfig();

      expect(defaultConfig.serviceId, 'ovh_ai');
      expect(defaultConfig.baseUrl, 'https://oai.endpoints.kepler.ai.cloud.ovh.net/v1');
      expect(defaultConfig.selectedModel, 'Qwen3.8-27B');
      expect(defaultConfig.apiKey, '');
      expect(defaultConfig.isApiKeyRequired, isFalse);
      expect(defaultConfig.isConfigured, isTrue);
    });

    test('isConfigured returns true for OVH AI even when apiKey is empty', () {
      const ovhConfig = AiProfileConfig(
        serviceId: 'ovh_ai',
        baseUrl: 'https://oai.endpoints.kepler.ai.cloud.ovh.net/v1',
        apiKey: '',
        selectedModel: 'meta-llama/Meta-Llama-3.1-70B-Instruct',
      );

      expect(ovhConfig.isApiKeyRequired, isFalse);
      expect(ovhConfig.isConfigured, isTrue);
    });

    test('isConfigured returns false for OVH AI if baseUrl is empty', () {
      const ovhConfig = AiProfileConfig(
        serviceId: 'ovh_ai',
        baseUrl: '',
        apiKey: '',
      );

      expect(ovhConfig.isConfigured, isFalse);
    });

    test('isConfigured returns false for OpenAI when apiKey is empty', () {
      const openAiConfig = AiProfileConfig(
        serviceId: 'openai',
        baseUrl: 'https://api.openai.com/v1',
        apiKey: '',
      );

      expect(openAiConfig.isApiKeyRequired, isTrue);
      expect(openAiConfig.isConfigured, isFalse);
    });

    test('toJson and fromJson preserves serviceId and recovers seamlessly', () {
      const config = AiProfileConfig(
        serviceId: 'ovh_ai',
        baseUrl: 'https://oai.endpoints.kepler.ai.cloud.ovh.net/v1',
        apiKey: '',
        selectedModel: 'meta-llama/Meta-Llama-3.1-70B-Instruct',
      );

      final json = config.toJson();
      expect(json['serviceId'], 'ovh_ai');

      final deserialized = AiProfileConfig.fromJson(json);
      expect(deserialized.serviceId, 'ovh_ai');
      expect(deserialized.baseUrl, 'https://oai.endpoints.kepler.ai.cloud.ovh.net/v1');
      expect(deserialized.isApiKeyRequired, isFalse);
      expect(deserialized.isConfigured, isTrue);
    });

    test('fromJson infers serviceId from baseUrl if missing in json', () {
      final legacyJson = {
        'baseUrl': 'https://oai.endpoints.kepler.ai.cloud.ovh.net/v1',
        'apiKey': '',
        'selectedModel': 'meta-llama/Meta-Llama-3.1-70B-Instruct',
      };

      final config = AiProfileConfig.fromJson(legacyJson);
      expect(config.serviceId, 'ovh_ai');
      expect(config.isApiKeyRequired, isFalse);
      expect(config.isConfigured, isTrue);
    });
  });
}
