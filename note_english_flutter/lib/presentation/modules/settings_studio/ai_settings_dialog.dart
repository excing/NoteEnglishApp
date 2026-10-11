import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_english_flutter/application/settings/ai_settings_cubit.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';

/// AI 接口配置对话框 (全平台自适应)
class AiSettingsDialog extends StatefulWidget {
  const AiSettingsDialog({super.key});

  @override
  State<AiSettingsDialog> createState() => _AiSettingsDialogState();
}

class _AiSettingsDialogState extends State<AiSettingsDialog> {
  late TextEditingController _baseUrlCtrl;
  late TextEditingController _apiKeyCtrl;
  late TextEditingController _promptCtrl;
  String _selectedModel = 'gpt-4o';

  @override
  void initState() {
    super.initState();
    final cfg = context.read<AiSettingsCubit>().state.config;
    _baseUrlCtrl = TextEditingController(text: cfg.baseUrl);
    _apiKeyCtrl = TextEditingController(text: cfg.apiKey);
    _promptCtrl = TextEditingController(text: cfg.customSystemPrompt);
    _selectedModel = cfg.selectedModel;
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _promptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);

    return BlocConsumer<AiSettingsCubit, AiSettingsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: tokens.terracotta,
            ),
          );
        }
        if (state.infoMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.infoMessage!),
              backgroundColor: tokens.sage,
            ),
          );
        }
      },
      builder: (context, state) {
        return Dialog(
          backgroundColor: tokens.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: tokens.cardBorder),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AI 引擎与主编偏好配置',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '支持任意 OpenAI 兼容的第三方服务商或中转端点',
                    style: TextStyle(fontSize: 13, color: tokens.textMuted),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Base URL',
                    controller: _baseUrlCtrl,
                    hint: '例如: https://api.openai.com/v1',
                    tokens: tokens,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'API Key',
                    controller: _apiKeyCtrl,
                    hint: 'sk-...',
                    obscureText: true,
                    tokens: tokens,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: state.availableModels.isNotEmpty
                            ? DropdownButtonFormField<String>(
                                initialValue: state.availableModels
                                        .any((m) => m.id == _selectedModel)
                                    ? _selectedModel
                                    : state.availableModels.first.id,
                                decoration: InputDecoration(
                                  labelText: '选择模型',
                                  labelStyle: TextStyle(color: tokens.textMuted),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: state.availableModels.map((m) {
                                  return DropdownMenuItem(
                                    value: m.id,
                                    child: Text(m.id, style: const TextStyle(fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedModel = val);
                                  }
                                },
                              )
                            : _buildTextField(
                                label: '模型名称',
                                controller: TextEditingController(text: _selectedModel),
                                hint: '例如: gpt-4o',
                                tokens: tokens,
                                onChanged: (v) => _selectedModel = v,
                              ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: state.isLoadingModels
                            ? null
                            : () {
                                // 暂存当前输入的 url 和 key 并拉取模型
                                final tempConfig = state.config.copyWith(
                                  baseUrl: _baseUrlCtrl.text.trim(),
                                  apiKey: _apiKeyCtrl.text.trim(),
                                );
                                context
                                    .read<AiSettingsCubit>()
                                    .saveConfig(tempConfig)
                                    .then((_) {
                                  context
                                      .read<AiSettingsCubit>()
                                      .fetchPlatformModels();
                                });
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          side: BorderSide(color: tokens.terracotta),
                        ),
                        icon: state.isLoadingModels
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.cloud_download,
                                size: 16, color: tokens.terracotta),
                        label: Text(
                          '获取模型',
                          style: TextStyle(color: tokens.terracotta, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: '自定义系统提示词 (仅定义风格口吻)',
                    controller: _promptCtrl,
                    hint: '例如: 请扮演一位风趣的专栏作家，重点关注我的生动表达...',
                    maxLines: 3,
                    tokens: tokens,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '注: 底层结构化协议由系统严格保全，无论如何修改风格均不会破坏梳理与追问的数据解析。',
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.amber,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('取消', style: TextStyle(color: tokens.textMuted)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        key: const ValueKey('save_settings_button'),
                        onPressed: () {
                          final updated = state.config.copyWith(
                            baseUrl: _baseUrlCtrl.text.trim(),
                            apiKey: _apiKeyCtrl.text.trim(),
                            selectedModel: _selectedModel.trim(),
                            customSystemPrompt: _promptCtrl.text.trim(),
                          );
                          context.read<AiSettingsCubit>().saveConfig(updated);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.terracotta,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('保存配置'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required AppThemeTokens tokens,
    bool obscureText = false,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      onChanged: onChanged,
      style: TextStyle(color: tokens.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: tokens.textMuted.withValues(alpha: 0.6)),
        labelStyle: TextStyle(color: tokens.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.terracotta, width: 1.5),
        ),
      ),
    );
  }
}
