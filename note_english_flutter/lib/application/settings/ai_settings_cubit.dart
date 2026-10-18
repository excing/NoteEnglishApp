import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_english_flutter/domain/errors/ai_failure.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/models/config/ai_model_descriptor.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/domain/models/config/built_in_ai_service.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';

/// AI 设置状态
class AiSettingsState extends Equatable {
  final AiProfileConfig config;
  final bool isLoading;
  final bool isLoadingModels;
  final List<AiModelDescriptor> availableModels;
  final String? infoMessage;
  final String? errorMessage;

  const AiSettingsState({
    this.config = const AiProfileConfig(),
    this.isLoading = false,
    this.isLoadingModels = false,
    this.availableModels = const [],
    this.infoMessage,
    this.errorMessage,
  });

  AiSettingsState copyWith({
    AiProfileConfig? config,
    bool? isLoading,
    bool? isLoadingModels,
    List<AiModelDescriptor>? availableModels,
    String? infoMessage,
    String? errorMessage,
  }) {
    return AiSettingsState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      isLoadingModels: isLoadingModels ?? this.isLoadingModels,
      availableModels: availableModels ?? this.availableModels,
      infoMessage: infoMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        config,
        isLoading,
        isLoadingModels,
        availableModels,
        infoMessage,
        errorMessage,
      ];
}

/// AI 设置管理 Cubit
class AiSettingsCubit extends Cubit<AiSettingsState> {
  final IAiConfigRepository _configRepository;
  final IAiGateway _aiGateway;

  AiSettingsCubit({
    required IAiConfigRepository configRepository,
    required IAiGateway aiGateway,
    AiProfileConfig? initialConfig,
  })  : _configRepository = configRepository,
        _aiGateway = aiGateway,
        super(AiSettingsState(config: initialConfig ?? const AiProfileConfig()));

  /// 加载当前存储的配置
  Future<void> loadConfig() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final config = await _configRepository.getConfig();
      emit(state.copyWith(config: config, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: '读取配置失败: $e'));
    }
  }

  /// 保存新配置
  Future<void> saveConfig(AiProfileConfig updatedConfig) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _configRepository.saveConfig(updatedConfig);
      emit(state.copyWith(
        config: updatedConfig,
        isLoading: false,
        infoMessage: '配置保存成功',
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: '保存配置失败: $e'));
    }
  }

  /// 切换内置预设服务并更新默认配置
  void selectBuiltInService(BuiltInAiService service) {
    final current = state.config;
    final updated = current.copyWith(
      serviceId: service.id,
      baseUrl: service.baseUrl,
      selectedModel: service.defaultModel.isNotEmpty
          ? service.defaultModel
          : current.selectedModel,
    );
    emit(state.copyWith(config: updated, errorMessage: null));
  }

  /// 动态向第三方平台拉取模型列表
  Future<void> fetchPlatformModels() async {
    final cfg = state.config;
    if (cfg.baseUrl.trim().isEmpty) {
      emit(state.copyWith(errorMessage: '请先填写 Base URL 再获取模型'));
      return;
    }
    if (cfg.isApiKeyRequired && cfg.apiKey.trim().isEmpty) {
      emit(state.copyWith(errorMessage: '请先填写 Base URL 和 API Key 再获取模型'));
      return;
    }

    emit(state.copyWith(isLoadingModels: true, errorMessage: null));
    try {
      final models = await _aiGateway.fetchAvailableModels(config: cfg);
      emit(state.copyWith(
        availableModels: models,
        isLoadingModels: false,
        infoMessage: '成功获取 ${models.length} 个可用模型',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingModels: false,
        errorMessage: e is AiFailure ? e.message : '获取模型列表失败: $e',
      ));
    }
  }
}
