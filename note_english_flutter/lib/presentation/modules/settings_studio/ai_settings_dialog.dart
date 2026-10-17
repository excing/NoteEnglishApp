import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_english_flutter/app/service_locator.dart';
import 'package:note_english_flutter/application/quick_polish/quick_polish_cubit.dart';
import 'package:note_english_flutter/application/quick_polish/quick_polish_state.dart';
import 'package:note_english_flutter/application/settings/ai_settings_cubit.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/presentation/common_widgets/otter_jot_avatar.dart';

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
  late TextEditingController _modelCtrl;
  String _selectedModel = 'gpt-4o';

  @override
  void initState() {
    super.initState();
    final cfg = context.read<AiSettingsCubit>().state.config;
    _baseUrlCtrl = TextEditingController(text: cfg.baseUrl);
    _apiKeyCtrl = TextEditingController(text: cfg.apiKey);
    _promptCtrl = TextEditingController(text: cfg.customSystemPrompt);
    _modelCtrl = TextEditingController(text: cfg.selectedModel);
    _selectedModel = cfg.selectedModel;
  }

  void _syncWithConfig(AiProfileConfig cfg) {
    if (_baseUrlCtrl.text != cfg.baseUrl) {
      _baseUrlCtrl.text = cfg.baseUrl;
    }
    if (_apiKeyCtrl.text != cfg.apiKey) {
      _apiKeyCtrl.text = cfg.apiKey;
    }
    if (_promptCtrl.text != cfg.customSystemPrompt) {
      _promptCtrl.text = cfg.customSystemPrompt;
    }
    if (_modelCtrl.text != cfg.selectedModel) {
      _modelCtrl.text = cfg.selectedModel;
    }
    if (_selectedModel != cfg.selectedModel) {
      setState(() {
        _selectedModel = cfg.selectedModel;
      });
    }
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _promptCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);

    return BlocConsumer<AiSettingsCubit, AiSettingsState>(
      listener: (context, state) {
        _syncWithConfig(state.config);
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const OtterJotAvatar(size: 26),
                          const SizedBox(width: 8),
                          Text(
                            'AI 引擎与主编偏好配置',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'OtterJot · 自定义 Jotty 主编服务端点与模型参数 (支持任意 OpenAI 兼容端点)',
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
                                    setState(() {
                                      _selectedModel = val;
                                      _modelCtrl.text = val;
                                    });
                                  }
                                },
                              )
                            : _buildTextField(
                                label: '模型名称',
                                controller: _modelCtrl,
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
                                final cubit = context.read<AiSettingsCubit>();
                                cubit.saveConfig(tempConfig).then((_) {
                                  cubit.fetchPlatformModels();
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
                  const SizedBox(height: 20),
                  _buildQuickPolishSection(context, tokens),
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
                          final modelToSave = _modelCtrl.text.trim().isNotEmpty
                              ? _modelCtrl.text.trim()
                              : _selectedModel.trim();
                          final updated = state.config.copyWith(
                            baseUrl: _baseUrlCtrl.text.trim(),
                            apiKey: _apiKeyCtrl.text.trim(),
                            selectedModel: modelToSave,
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

  QuickPolishCubit? _getQuickPolishCubit(BuildContext context) {
    try {
      return context.read<QuickPolishCubit>();
    } catch (_) {
      if (sl.isRegistered<QuickPolishCubit>()) {
        return sl<QuickPolishCubit>();
      }
      return null;
    }
  }

  Widget _buildQuickPolishSection(BuildContext context, AppThemeTokens tokens) {
    final cubit = _getQuickPolishCubit(context);
    if (cubit == null) return const SizedBox.shrink();

    return BlocBuilder<QuickPolishCubit, QuickPolishState>(
      bloc: cubit,
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: tokens.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.cardBorder),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bolt, size: 20, color: tokens.terracotta),
                            const SizedBox(width: 6),
                            Text(
                              '全局快捷润色 (fn + 空格)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: tokens.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '常驻桌面菜单栏，选中文本按下快捷键即可原地重塑为地道英文并自动沉淀语料。',
                          style: TextStyle(fontSize: 12, color: tokens.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch.adaptive(
                    key: const ValueKey('quick_polish_switch'),
                    value: state.isEnabled,
                    activeTrackColor: tokens.terracotta,
                    activeThumbColor: Colors.white,
                    onChanged: (val) {
                      cubit.toggleEnabled(val);
                    },
                  ),
                ],
              ),
              if (state.isEnabled) ...[
                const SizedBox(height: 12),
                if (state.isAccessibilityGranted)
                  _buildGrantedStatus(context, cubit, tokens)
                else
                  _buildGuideCard(context, cubit, tokens),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrantedStatus(
    BuildContext context,
    QuickPolishCubit cubit,
    AppThemeTokens tokens,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.sage.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.sage.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: tokens.sage),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '辅助功能已授权，快捷润色随时就绪 (fn + 空格 / ⌥ + 空格)',
              style: TextStyle(
                fontSize: 12,
                color: tokens.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('recheck_permission_button'),
            onPressed: () => cubit.checkAccessibilityPermission(),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              '重新检测',
              style: TextStyle(fontSize: 12, color: tokens.sage),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(
    BuildContext context,
    QuickPolishCubit cubit,
    AppThemeTokens tokens,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.amber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: tokens.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '需要授予 macOS 系统辅助功能权限',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '为了在任意第三方应用（如微信、Slack、浏览器）的输入框中模拟快捷键抓取选中文本并原地回填地道英文，macOS 要求授予 OtterJot 辅助功能权限。',
            style: TextStyle(fontSize: 12, color: tokens.textMuted, height: 1.4),
          ),
          const SizedBox(height: 10),
          _buildGuideStep('1', '点击下方「前往系统设置授权」，系统将直接跳转至「辅助功能」设置；', tokens),
          const SizedBox(height: 4),
          _buildGuideStep('2', '若列表中已出现「OtterJot」，请直接将右侧开关切换为允许；', tokens),
          const SizedBox(height: 4),
          _buildGuideStep('3', '若列表中未出现「OtterJot」：点击下方「在访达中定位应用」，将高亮选中的 OtterJot 拖入系统列表，或点击系统列表底部的「+」号添加；', tokens),
          const SizedBox(height: 4),
          _buildGuideStep('4', '授权完成后返回此处，点击「已完成授权，重新检测」。', tokens),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                key: const ValueKey('request_permission_button'),
                onPressed: () => cubit.requestAccessibilityPermission(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.terracotta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text('前往系统设置授权'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('locate_in_finder_button'),
                onPressed: () => cubit.openAppInFinder(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: tokens.cardBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                icon: Icon(Icons.folder_open, size: 14, color: tokens.textPrimary),
                label: Text('在访达中定位应用 (拖入列表)', style: TextStyle(color: tokens.textPrimary)),
              ),
              OutlinedButton.icon(
                key: const ValueKey('recheck_permission_button'),
                onPressed: () => cubit.checkAccessibilityPermission(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: tokens.cardBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                icon: Icon(Icons.refresh, size: 14, color: tokens.textPrimary),
                label: Text('已完成授权，重新检测', style: TextStyle(color: tokens.textPrimary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String text, AppThemeTokens tokens) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tokens.amber.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: tokens.amber,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: tokens.textPrimary),
          ),
        ),
      ],
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
      key: ValueKey('setting_field_$label'),
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
