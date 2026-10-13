import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:note_english_flutter/application/corpus/corpus_deck_cubit.dart';
import 'package:note_english_flutter/application/diary/diary_list_cubit.dart';
import 'package:note_english_flutter/application/editorial/diary_editorial_cubit.dart';
import 'package:note_english_flutter/application/inquiry/inquiry_cubit.dart';
import 'package:note_english_flutter/application/settings/ai_settings_cubit.dart';
import 'package:note_english_flutter/app/service_locator.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';
import 'package:note_english_flutter/presentation/common_widgets/weather_picker_badge.dart';
import 'package:note_english_flutter/presentation/modules/corpus_deck/corpus_deck_page.dart';
import 'package:note_english_flutter/presentation/modules/diary_management/diary_management_drawer.dart';
import 'package:note_english_flutter/presentation/modules/editorial_inspector/editorial_inspector_view.dart';
import 'package:note_english_flutter/presentation/modules/settings_studio/ai_settings_dialog.dart';

/// 沉浸式随笔书房主页面 (Writing Studio)
class WritingStudioPage extends StatefulWidget {
  const WritingStudioPage({super.key});

  @override
  State<WritingStudioPage> createState() => _WritingStudioPageState();
}

class _WritingStudioPageState extends State<WritingStudioPage> {
  late TextEditingController _textCtrl;
  final FocusNode _focusNode = FocusNode();
  String? _currentEntryId;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<DiaryEditorialCubit>();
    _currentEntryId = cubit.state.entry.id;
    _textCtrl = TextEditingController(text: cubit.state.entry.content);
    _textCtrl.addListener(() {
      if (_textCtrl.text != context.read<DiaryEditorialCubit>().state.entry.content) {
        context.read<DiaryEditorialCubit>().updateContent(_textCtrl.text);
      }
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    try {
      return DateFormat('MM月dd日 E · HH:mm', 'zh_CN').format(dt);
    } catch (_) {
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$m月$d日 · $h:$min';
    }
  }

  String? _formatResponsiveDate(DateTime dt, double width) {
    if (width < 320) {
      return null;
    }
    try {
      if (width < 380) {
        return DateFormat('M/d', 'zh_CN').format(dt);
      } else if (width < 500) {
        return DateFormat('M月d日', 'zh_CN').format(dt);
      } else if (width < 700) {
        return DateFormat('M月d日 E', 'zh_CN').format(dt);
      }
      return DateFormat('MM月dd日 E · HH:mm', 'zh_CN').format(dt);
    } catch (_) {
      final m = dt.month.toString();
      final d = dt.day.toString();
      if (width < 380) return '$m/$d';
      if (width < 500) return '$m月$d日';
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$m月$d日 · $h:$min';
    }
  }

  void _openCorpus(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => CorpusDeckCubit(
            corpusRepository: sl<ICorpusRepository>(),
          ),
          child: const CorpusDeckPage(),
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: context.read<AiSettingsCubit>(),
        child: const AiSettingsDialog(),
      ),
    );
  }

  /// 依据屏幕宽度阶梯式省略天气显示元素，保证字号永不缩水
  WeatherBadgeDisplayMode _resolveWeatherDisplayMode(double width) {
    if (width < 280) {
      // 极窄屏幕（< 280px）：字号不缩小，仅保留天气图标胶囊
      return WeatherBadgeDisplayMode.iconOnly;
    } else if (width < 360) {
      // 较窄屏幕（280px ~ 360px）：省略天气名称与城市，仅保留 图标 + 温度 (如 ⛅ 23°C)
      return WeatherBadgeDisplayMode.compact;
    } else if (width < 480) {
      // 紧凑屏幕（360px ~ 480px）：省略城市，保留 图标 + 温度 + 天气描述 (如 ⛅ 23°C 多云)
      return WeatherBadgeDisplayMode.noLocation;
    }
    // 宽阔屏幕（>= 480px）：完整展示 (如 ⛅ 23°C 多云 · 大理)
    return WeatherBadgeDisplayMode.full;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return BlocConsumer<DiaryEditorialCubit, DiaryEditorialState>(
      listener: (context, state) {
        if (state.entry.id != _currentEntryId) {
          _currentEntryId = state.entry.id;
          if (_textCtrl.text != state.entry.content) {
            _textCtrl.text = state.entry.content;
            _textCtrl.selection = TextSelection.fromPosition(
              TextPosition(offset: _textCtrl.text.length),
            );
          }
        }

        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: tokens.terracotta,
              action: state.errorMessage!.contains('配置')
                  ? SnackBarAction(
                      label: '去配置',
                      textColor: Colors.white,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => BlocProvider.value(
                            value: context.read<AiSettingsCubit>(),
                            child: const AiSettingsDialog(),
                          ),
                        );
                      },
                    )
                  : null,
            ),
          );
        }
      },
      builder: (context, state) {
        final entry = state.entry;
        final hasAnalysis = entry.analysisResult != null;

        return CallbackShortcuts(
          bindings: {
            // 桌面端快捷键: Cmd/Ctrl + Enter 呼叫主编
            const SingleActivator(LogicalKeyboardKey.enter, meta: true): () {
              context.read<DiaryEditorialCubit>().requestAiAnalysis();
            },
            const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
              context.read<DiaryEditorialCubit>().requestAiAnalysis();
            },
          },
          child: Scaffold(
            backgroundColor: tokens.canvas,
            drawer: DiaryManagementDrawer(
              onSelectEntry: (selected) {
                context.read<DiaryEditorialCubit>().loadEntry(selected);
                context.read<InquiryCubit>().resetHistory(selected.inquiryHistory);
                context.read<DiaryListCubit>().setActiveEntryId(selected.id);
              },
              onEntryCreated: (created) {
                context.read<DiaryEditorialCubit>().loadEntry(created);
                context.read<InquiryCubit>().resetHistory([]);
                context.read<DiaryListCubit>().setActiveEntryId(created.id);
                _focusNode.requestFocus();
              },
              onEntryDeleted: (deletedId) async {
                final editorialCubit = context.read<DiaryEditorialCubit>();
                if (editorialCubit.state.entry.id == deletedId) {
                  final listCubit = context.read<DiaryListCubit>();
                  final remaining = listCubit.state.entries
                      .where((e) => e.id != deletedId)
                      .toList();
                  if (remaining.isNotEmpty) {
                    final nextEntry = remaining.first;
                    editorialCubit.loadEntry(nextEntry);
                    context.read<InquiryCubit>().resetHistory(nextEntry.inquiryHistory);
                    listCubit.setActiveEntryId(nextEntry.id);
                  } else {
                    final fresh = await listCubit.createEntry();
                    editorialCubit.loadEntry(fresh);
                    context.read<InquiryCubit>().resetHistory([]);
                    listCubit.setActiveEntryId(fresh.id);
                  }
                }
              },
            ),
            appBar: AppBar(
              backgroundColor: tokens.canvas,
              elevation: 0,
              titleSpacing: 0,
              leading: Builder(
                builder: (scaffoldCtx) => IconButton(
                  key: const ValueKey('diary_drawer_button'),
                  icon: const Icon(Icons.menu_book_outlined),
                  tooltip: '随笔手账与管理',
                  onPressed: () {
                    Scaffold.of(scaffoldCtx).openDrawer();
                  },
                ),
              ),
              title: Builder(
                builder: (ctx) {
                  final respDate = _formatResponsiveDate(
                      entry.metadata.recordedAt, screenWidth);
                  return Row(
                    children: [
                      if (respDate != null) ...[
                        Flexible(
                          child: Text(
                            respDate,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: tokens.textMuted,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      WeatherPickerBadge(
                        displayMode: _resolveWeatherDisplayMode(screenWidth),
                        currentWeather: entry.metadata.weather,
                        detailedWeather: entry.metadata.detailedWeather,
                        location: entry.metadata.location,
                        temperature: entry.metadata.temperature,
                        apparentTemperature: entry.metadata.apparentTemperature,
                        humidity: entry.metadata.humidity,
                        isDay: entry.metadata.isDay,
                        onWeatherChanged: (w) {
                          context.read<DiaryEditorialCubit>().updateWeather(w);
                        },
                        onAutoFetchWeather: () {
                          context
                              .read<DiaryEditorialCubit>()
                              .fetchAndApplyRealtimeWeather();
                        },
                        onCityWeatherRequested: (cityName) {
                          context
                              .read<DiaryEditorialCubit>()
                              .fetchAndApplyRealtimeWeather(cityName: cityName);
                        },
                      ),
                    ],
                  );
                },
              ),
              actions: [
                // 快捷新建随笔入口
                IconButton(
                  key: const ValueKey('quick_new_diary_button'),
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  tooltip: '新建随笔',
                  onPressed: () async {
                    final listCubit = context.read<DiaryListCubit>();
                    final newEntry = await listCubit.createEntry();
                    context.read<DiaryEditorialCubit>().loadEntry(newEntry);
                    context.read<InquiryCubit>().resetHistory([]);
                    listCubit.setActiveEntryId(newEntry.id);
                    _focusNode.requestFocus();
                  },
                ),
                // 语料库入口
                if (screenWidth >= 640)
                  TextButton.icon(
                    key: const ValueKey('corpus_deck_button'),
                    style: TextButton.styleFrom(
                      foregroundColor: tokens.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    icon: const Icon(Icons.collections_bookmark_outlined, size: 18),
                    label: const Text('语料库', style: TextStyle(fontSize: 13)),
                    onPressed: () => _openCorpus(context),
                  )
                else if (screenWidth >= 340)
                  IconButton(
                    key: const ValueKey('corpus_deck_button'),
                    icon: const Icon(Icons.collections_bookmark_outlined, size: 20),
                    tooltip: '语料库',
                    onPressed: () => _openCorpus(context),
                  ),
                // 设置入口
                if (screenWidth >= 640)
                  TextButton.icon(
                    key: const ValueKey('ai_settings_button'),
                    style: TextButton.styleFrom(
                      foregroundColor: tokens.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('设置', style: TextStyle(fontSize: 13)),
                    onPressed: () => _openSettings(context),
                  )
                else if (screenWidth >= 340)
                  IconButton(
                    key: const ValueKey('ai_settings_button'),
                    icon: const Icon(Icons.tune, size: 20),
                    tooltip: '设置',
                    onPressed: () => _openSettings(context),
                  ),
                // 极小屏幕 (< 340px) 紧凑折叠为更多菜单
                if (screenWidth < 340)
                  PopupMenuButton<String>(
                    key: const ValueKey('appbar_more_menu'),
                    icon: const Icon(Icons.more_vert, size: 20),
                    tooltip: '更多功能',
                    onSelected: (val) {
                      if (val == 'corpus') {
                        _openCorpus(context);
                      } else if (val == 'settings') {
                        _openSettings(context);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        key: const ValueKey('corpus_deck_button'),
                        value: 'corpus',
                        child: Row(
                          children: [
                            Icon(Icons.collections_bookmark_outlined,
                                size: 18, color: tokens.textPrimary),
                            const SizedBox(width: 8),
                            const Text('语料库'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        key: const ValueKey('ai_settings_button'),
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.tune, size: 18, color: tokens.textPrimary),
                            const SizedBox(width: 8),
                            const Text('设置'),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 4),
              ],
            ),
            body: isDesktop
                ? _buildDesktopLayout(context, state, tokens)
                : _buildMobileLayout(context, state, tokens),
          ),
        );
      },
    );
  }

  /// 桌面端双栏画卷布局
  Widget _buildDesktopLayout(
    BuildContext context,
    DiaryEditorialState state,
    AppThemeTokens tokens,
  ) {
    return Row(
      children: [
        // 左侧/中央：纯净稿纸书写区
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Column(
              children: [
                Expanded(child: _buildWritingArea(tokens)),
                _buildBottomToolbar(context, state, tokens),
              ],
            ),
          ),
        ),
        VerticalDivider(width: 1, thickness: 1, color: tokens.cardBorder),
        // 右侧：主编梳理与追问视窗
        Expanded(
          flex: 5,
          child: Container(
            color: tokens.card.withValues(alpha: 0.5),
            child: state.status == DiaryAnalysisStatus.analyzing
                ? _buildAnalyzingIndicator(tokens)
                : (state.entry.analysisResult != null
                    ? EditorialInspectorView(
                        analysisResult: state.entry.analysisResult!,
                        currentEntry: state.entry,
                        silentCorpusCount: state.silentCorpusCount,
                      )
                    : _buildEmptyEditorialPlaceholder(tokens)),
          ),
        ),
      ],
    );
  }

  /// 移动端单栏心流布局
  Widget _buildMobileLayout(
    BuildContext context,
    DiaryEditorialState state,
    AppThemeTokens tokens,
  ) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: _buildWritingArea(tokens),
          ),
        ),
        // 移动端若已有梳理结果，提供温润展开条
        if (state.entry.analysisResult != null)
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: tokens.canvas,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) {
                  return BlocProvider.value(
                    value: context.read<InquiryCubit>(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.88,
                      child: EditorialInspectorView(
                        analysisResult: state.entry.analysisResult!,
                        currentEntry: state.entry,
                        silentCorpusCount: state.silentCorpusCount,
                      ),
                    ),
                  );
                },
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.highlight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.terracotta.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('✨', style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        '主编润色重塑已就绪 · 查看洞察',
                        style: TextStyle(
                          color: tokens.terracotta,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: tokens.terracotta),
                ],
              ),
            ),
          ),
        _buildBottomToolbar(context, state, tokens),
      ],
    );
  }

  /// 纯净书写区域 (支持中英混排，不设红波浪线)
  Widget _buildWritingArea(AppThemeTokens tokens) {
    return TextField(
      key: const ValueKey('diary_input_field'),
      controller: _textCtrl,
      focusNode: _focusNode,
      maxLines: null,
      expands: true,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.multiline,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: tokens.textPrimary,
          ),
      onChanged: (text) {
        context.read<DiaryEditorialCubit>().updateContent(text);
      },
      decoration: InputDecoration(
        hintText: '写下今天的经历、闪念与思绪...\n允许任意中英夹杂，拼写不全也无妨。\n主编会在右下角随时为你重塑地道表达。',
        hintStyle: TextStyle(
          color: tokens.textMuted.withValues(alpha: 0.4),
          height: 1.8,
          fontSize: 17,
        ),
        border: InputBorder.none,
      ),
    );
  }

  /// 底部微工具条
  Widget _buildBottomToolbar(
    BuildContext context,
    DiaryEditorialState state,
    AppThemeTokens tokens,
  ) {
    final isAnalyzing = state.status == DiaryAnalysisStatus.analyzing;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth < 340 ? 10 : 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: tokens.canvas,
        border: Border(top: BorderSide(color: tokens.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                screenWidth < 280
                    ? '${state.entry.metadata.wordCount} 字'
                    : '${state.entry.metadata.wordCount} 字 · 自动存盘',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: screenWidth < 300 ? 11 : 13,
                  color: tokens.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              key: const ValueKey('call_editor_button'),
              onPressed: isAnalyzing
                  ? null
                  : () {
                      context
                          .read<DiaryEditorialCubit>()
                          .updateContent(_textCtrl.text);
                      context.read<DiaryEditorialCubit>().requestAiAnalysis();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.terracotta,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth < 340 ? 12 : 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              icon: isAnalyzing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('✨', style: TextStyle(fontSize: 14)),
              label: Text(
                isAnalyzing
                    ? '构思中...'
                    : (screenWidth < 300 ? '梳理' : '呼叫主编梳理'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: screenWidth < 340 ? 13 : 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingIndicator(AppThemeTokens tokens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: tokens.terracotta),
          const SizedBox(height: 16),
          Text(
            '纽约客主编正在细细品读你的随笔...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '正在重塑动词质感、搭建思维桥梁并提取生动语料',
            style: TextStyle(fontSize: 13, color: tokens.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEditorialPlaceholder(AppThemeTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories_outlined,
                size: 56, color: tokens.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              '双语随笔创作书房',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '左侧稿纸可自由书写。停笔后点击“呼叫主编梳理”，这里将并排呈现语法纠偏、原风格版本、思维桥梁与进阶母语重塑。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: tokens.textMuted,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
