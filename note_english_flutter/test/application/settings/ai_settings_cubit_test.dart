import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:note_english_flutter/application/settings/ai_settings_cubit.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/domain/models/config/built_in_ai_service.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';

class MockAiConfigRepository extends Mock implements IAiConfigRepository {}
class MockAiGateway extends Mock implements IAiGateway {}

void main() {
  late MockAiConfigRepository configRepo;
  late MockAiGateway aiGateway;

  const savedConfig = AiProfileConfig(
    baseUrl: 'https://api.deepseek.com/v1',
    apiKey: 'sk-deepseek-123',
    selectedModel: 'deepseek-chat',
    customSystemPrompt: '专注英式幽默',
  );

  setUpAll(() {
    registerFallbackValue(const AiProfileConfig());
  });

  setUp(() {
    configRepo = MockAiConfigRepository();
    aiGateway = MockAiGateway();
  });

  group('AiSettingsCubit Tests (TDD)', () {
    test('should immediately have initialConfig in initial state without delay', () {
      final cubit = AiSettingsCubit(
        configRepository: configRepo,
        aiGateway: aiGateway,
        initialConfig: savedConfig,
      );

      expect(cubit.state.config, savedConfig);
      expect(cubit.state.config.baseUrl, 'https://api.deepseek.com/v1');
      expect(cubit.state.config.apiKey, 'sk-deepseek-123');
      expect(cubit.state.config.selectedModel, 'deepseek-chat');
    });

    blocTest<AiSettingsCubit, AiSettingsState>(
      'loadConfig should fetch from repository and emit updated config',
      setUp: () {
        when(() => configRepo.getConfig()).thenAnswer((_) async => savedConfig);
      },
      build: () => AiSettingsCubit(
        configRepository: configRepo,
        aiGateway: aiGateway,
      ),
      act: (cubit) => cubit.loadConfig(),
      expect: () => [
        isA<AiSettingsState>().having((s) => s.isLoading, 'isLoading', true),
        isA<AiSettingsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.config, 'config', savedConfig),
      ],
    );

    blocTest<AiSettingsCubit, AiSettingsState>(
      'saveConfig should persist config to repository and update state',
      setUp: () {
        when(() => configRepo.saveConfig(any())).thenAnswer((_) async {});
      },
      build: () => AiSettingsCubit(
        configRepository: configRepo,
        aiGateway: aiGateway,
        initialConfig: savedConfig,
      ),
      act: (cubit) => cubit.saveConfig(savedConfig.copyWith(selectedModel: 'deepseek-coder')),
      expect: () => [
        isA<AiSettingsState>().having((s) => s.isLoading, 'isLoading', true),
        isA<AiSettingsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.config.selectedModel, 'selectedModel', 'deepseek-coder')
            .having((s) => s.infoMessage, 'infoMessage', '配置保存成功'),
      ],
      verify: (_) {
        verify(() => configRepo.saveConfig(any())).called(1);
      },
    );

    blocTest<AiSettingsCubit, AiSettingsState>(
      'selectBuiltInService should update config with service defaults',
      build: () => AiSettingsCubit(
        configRepository: configRepo,
        aiGateway: aiGateway,
      ),
      act: (cubit) => cubit.selectBuiltInService(BuiltInAiService.ovhAi),
      expect: () => [
        isA<AiSettingsState>()
            .having((s) => s.config.serviceId, 'serviceId', 'ovh_ai')
            .having((s) => s.config.baseUrl, 'baseUrl', 'https://oai.endpoints.kepler.ai.cloud.ovh.net/v1')
            .having((s) => s.config.selectedModel, 'selectedModel', 'Qwen3.8-27B')
            .having((s) => s.config.isApiKeyRequired, 'isApiKeyRequired', false),
      ],
    );

    blocTest<AiSettingsCubit, AiSettingsState>(
      'fetchPlatformModels allows empty apiKey for OVH AI service and invokes gateway',
      setUp: () {
        when(() => aiGateway.fetchAvailableModels(config: any(named: 'config')))
            .thenAnswer((_) async => []);
      },
      build: () => AiSettingsCubit(
        configRepository: configRepo,
        aiGateway: aiGateway,
        initialConfig: const AiProfileConfig(
          serviceId: 'ovh_ai',
          baseUrl: 'https://oai.endpoints.kepler.ai.cloud.ovh.net/v1',
          apiKey: '',
        ),
      ),
      act: (cubit) => cubit.fetchPlatformModels(),
      expect: () => [
        isA<AiSettingsState>().having((s) => s.isLoadingModels, 'isLoadingModels', true),
        isA<AiSettingsState>()
            .having((s) => s.isLoadingModels, 'isLoadingModels', false)
            .having((s) => s.infoMessage, 'infoMessage', '成功获取 0 个可用模型'),
      ],
      verify: (_) {
        verify(() => aiGateway.fetchAvailableModels(config: any(named: 'config'))).called(1);
      },
    );

    blocTest<AiSettingsCubit, AiSettingsState>(
      'fetchPlatformModels requires apiKey when service requires apiKey',
      build: () => AiSettingsCubit(
        configRepository: configRepo,
        aiGateway: aiGateway,
        initialConfig: const AiProfileConfig(
          serviceId: 'openai',
          baseUrl: 'https://api.openai.com/v1',
          apiKey: '',
        ),
      ),
      act: (cubit) => cubit.fetchPlatformModels(),
      expect: () => [
        isA<AiSettingsState>().having((s) => s.errorMessage, 'errorMessage', '请先填写 Base URL 和 API Key 再获取模型'),
      ],
      verify: (_) {
        verifyNever(() => aiGateway.fetchAvailableModels(config: any(named: 'config')));
      },
    );
  });
}
