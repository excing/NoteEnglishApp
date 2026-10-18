import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/domain/models/config/ai_provider_type.dart';

void main() {
  group('AiProfileConfig Tests (TDD)', () {
    test('default isDeepThinking should be false', () {
      const config = AiProfileConfig();
      expect(config.isDeepThinking, isFalse);
    });

    test('copyWith should update isDeepThinking', () {
      const config = AiProfileConfig();
      final updated = config.copyWith(isDeepThinking: true);
      expect(updated.isDeepThinking, isTrue);
      expect(config.isDeepThinking, isFalse);
    });

    test('toJson and fromJson should preserve isDeepThinking', () {
      const config = AiProfileConfig(
        serviceId: 'deepseek',
        providerType: AiProviderType.openAiCompatible,
        baseUrl: 'https://api.deepseek.com/v1',
        apiKey: 'sk-test',
        selectedModel: 'deepseek-v4.1-flash',
        isDeepThinking: true,
      );

      final json = config.toJson();
      expect(json['isDeepThinking'], isTrue);

      final restored = AiProfileConfig.fromJson(json);
      expect(restored.isDeepThinking, isTrue);
      expect(restored.selectedModel, 'deepseek-v4.1-flash');
      expect(restored, equals(config));
    });
  });
}
