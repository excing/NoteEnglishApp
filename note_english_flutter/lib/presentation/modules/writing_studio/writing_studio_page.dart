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
import 'package:note_english_flutter/presentation/common_widgets/pane_resize_handle.dart';
import 'package:note_english_flutter/presentation/common_widgets/weather_picker_badge.dart';
import 'package:note_english_flutter/presentation/modules/corpus_deck/corpus_deck_page.dart';
import 'package:note_english_flutter/presentation/modules/diary_management/diary_management_drawer.dart';
import 'package:note_english_flutter/presentation/modules/editorial_inspector/editorial_inspector_view.dart';
import 'package:note_english_flutter/presentation/modules/settings_studio/ai_settings_dialog.dart';

/// 响应式多端布局断点与尺寸规格
abstract final class LayoutBreakpoints {
  /// 桌面端最小宽度 (>= 1024 采用三栏设计)
  static const double desktop = 1024.0;

  /// 平板端最小宽度 (720 <= width < 1024 采用主区域与右边栏设计)
  static const double tablet = 720.0;

  /// 主区域 (编辑稿纸) 最小保证可视宽度
  static const double mainAreaMinWidth = 210.0;

  /// 左边栏默认、最小与最大宽度
  static const double leftSidebarDefaultWidth = 320.0;
  static const double leftSidebarMinWidth = 180.0;
  static const double leftSidebarMaxWidth = 460.0;

  /// 右边栏 (AI 视窗) 默认、最小与最大宽度
  static const double rightSidebarDefaultWidth = 380.0;
  static const double rightSidebarMinWidth = 200.0;
  static const double rightSidebarMaxWidth = 560.0;

  /// 边栏达到最小宽度后，用户继续向收起方向拉动触发自动隐藏所需的弹性心理距离
  static const double collapseElasticDistance = 100.0;

  /// 隐藏后未松手，用户往展开方向回拉达到此距离时还原显示
  static const double restoreDragThreshold = 30.0;
}

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

  /// 桌面端三栏架构中左边栏(随笔列表)的展开状态，默认开启
  bool _isLeftSidebarOpen = true;

  /// AI 主编梳理右边栏视窗的展开状态，默认收起，点击“梳理”时显示
  bool _isAiSidebarOpen = false;

  /// 左边栏当前用户自定义宽度
  double _leftSidebarWidth = LayoutBreakpoints.leftSidebarDefaultWidth;

  /// 右边栏当前用户自定义宽度
  double _rightSidebarWidth = LayoutBreakpoints.rightSidebarDefaultWidth;

  /// 左边栏达到最小宽度后的累计收起弹性拉动距离
  double _leftSidebarOverdrag = 0.0;

  /// 右边栏达到最小宽度后的累计收起弹性拉动距离
  double _rightSidebarOverdrag = 0.0;

  /// 左边栏拖拽中因超过弹性距离而临时隐藏状态
  bool _isLeftSidebarTemporarilyCollapsed = false;

  /// 右边栏拖拽中因超过弹性距离而临时隐藏状态
  bool _isRightSidebarTemporarilyCollapsed = false;

  /// 左边栏临时隐藏后，未松手往回拉的累计距离
  double _leftSidebarReversePull = 0.0;

  /// 右边栏临时隐藏后，未松手往回拉的累计距离
  double _rightSidebarReversePull = 0.0;

  void _onLeftDragEnd() {
    setState(() {
      if (_isLeftSidebarTemporarilyCollapsed) {
        _isLeftSidebarOpen = false;
        _leftSidebarWidth = LayoutBreakpoints.leftSidebarDefaultWidth;
        _isLeftSidebarTemporarilyCollapsed = false;
      }
      _leftSidebarOverdrag = 0.0;
      _leftSidebarReversePull = 0.0;
    });
  }

  void _onRightDragEnd() {
    setState(() {
      if (_isRightSidebarTemporarilyCollapsed) {
        _isAiSidebarOpen = false;
        _rightSidebarWidth = LayoutBreakpoints.rightSidebarDefaultWidth;
        _isRightSidebarTemporarilyCollapsed = false;
      }
      _rightSidebarOverdrag = 0.0;
      _rightSidebarReversePull = 0.0;
    });
  }

  void _onLeftSidebarResize(double delta, double screenWidth) {
    setState(() {
      // 若当前处于拖拽临时收起状态：监听未松手反向拉动
      if (_isLeftSidebarTemporarilyCollapsed) {
        if (delta > 0) {
          _leftSidebarReversePull += delta;
          if (_leftSidebarReversePull >=
              LayoutBreakpoints.restoreDragThreshold) {
            // 达到 30px 反向拉动距离，还原显示！
            _isLeftSidebarTemporarilyCollapsed = false;
            _leftSidebarWidth = LayoutBreakpoints.leftSidebarMinWidth;
            _leftSidebarOverdrag = 0.0;
            _leftSidebarReversePull = 0.0;
          }
        } else {
          // 继续向左拉，重置反向拉动累计
          _leftSidebarReversePull = 0.0;
        }
        return;
      }

      // 1. 若向左拖拽（变窄，delta < 0）
      if (delta < 0) {
        if (_leftSidebarWidth > LayoutBreakpoints.leftSidebarMinWidth) {
          final candidate = _leftSidebarWidth + delta;
          if (candidate >= LayoutBreakpoints.leftSidebarMinWidth) {
            _leftSidebarWidth = candidate;
            _leftSidebarOverdrag = 0.0;
            return;
          } else {
            // 穿过最小宽度 180px 边界，超出的部分计入弹性拉动距离
            final excess = LayoutBreakpoints.leftSidebarMinWidth - candidate;
            _leftSidebarWidth = LayoutBreakpoints.leftSidebarMinWidth;
            _leftSidebarOverdrag += excess;
          }
        } else {
          // 已处于最小宽度 180px，用户持续向左拉动累计弹性距离
          _leftSidebarOverdrag += (-delta);
        }

        // 达到或超过心理弹性距离 (100px) 后，触发临时收起隐藏
        if (_leftSidebarOverdrag >= LayoutBreakpoints.collapseElasticDistance) {
          _isLeftSidebarTemporarilyCollapsed = true;
          _leftSidebarReversePull = 0.0;
        }
        return;
      }

      // 2. 若向右拖拽变宽 (delta > 0)
      if (_leftSidebarOverdrag > 0) {
        final consumed = delta.clamp(0.0, _leftSidebarOverdrag);
        _leftSidebarOverdrag -= consumed;
        delta -= consumed;
        if (_leftSidebarOverdrag > 0 || delta <= 0) {
          return;
        }
      }

      final isBothOpen = _isLeftSidebarOpen &&
          !_isLeftSidebarTemporarilyCollapsed &&
          _isAiSidebarOpen &&
          !_isRightSidebarTemporarilyCollapsed;
      if (isBothOpen) {
        // 双边栏同时打开时：主区域与右侧边栏以等比例 (1:1 各 50%) 共同承担压缩空间
        final totalContentWidth = screenWidth - 16.0;
        final currentMainWidth =
            totalContentWidth - _leftSidebarWidth - _rightSidebarWidth;

        final maxMainCompress = (currentMainWidth - LayoutBreakpoints.mainAreaMinWidth)
            .clamp(0.0, double.infinity);
        final maxRightCompress =
            (_rightSidebarWidth - LayoutBreakpoints.rightSidebarMinWidth)
                .clamp(0.0, double.infinity);

        var halfDelta = delta / 2;
        var mainCompress = halfDelta.clamp(0.0, maxMainCompress);
        var rightCompress = halfDelta.clamp(0.0, maxRightCompress);

        // 若一方达到压缩极限，溢出部分尝试由另一方额外吸收
        if (halfDelta > maxMainCompress) {
          final excess = halfDelta - maxMainCompress;
          final additionalRight =
              excess.clamp(0.0, maxRightCompress - rightCompress);
          rightCompress += additionalRight;
        } else if (halfDelta > maxRightCompress) {
          final excess = halfDelta - maxRightCompress;
          final additionalMain =
              excess.clamp(0.0, maxMainCompress - mainCompress);
          mainCompress += additionalMain;
        }

        final actualExpand = mainCompress + rightCompress;
        final proposedLeftWidth = (_leftSidebarWidth + actualExpand)
            .clamp(LayoutBreakpoints.leftSidebarMinWidth,
                LayoutBreakpoints.leftSidebarMaxWidth);

        final realDelta = proposedLeftWidth - _leftSidebarWidth;
        _leftSidebarWidth = proposedLeftWidth;

        // 右边栏相应压缩，保底停留在 200px 最小宽度，不立刻隐藏
        final proposedRightWidth = _rightSidebarWidth -
            (rightCompress *
                (actualExpand > 0 ? (realDelta / actualExpand) : 1.0));
        _rightSidebarWidth = proposedRightWidth.clamp(
          LayoutBreakpoints.rightSidebarMinWidth,
          LayoutBreakpoints.rightSidebarMaxWidth,
        );
      } else {
        // 单侧展开：由主区域承担压缩，保证主区域不低于 mainAreaMinWidth (210px)
        final maxAllowed = (screenWidth -
                LayoutBreakpoints.mainAreaMinWidth -
                8.0)
            .clamp(
          LayoutBreakpoints.leftSidebarMinWidth,
          LayoutBreakpoints.leftSidebarMaxWidth,
        );
        _leftSidebarWidth = (_leftSidebarWidth + delta).clamp(
          LayoutBreakpoints.leftSidebarMinWidth,
          maxAllowed,
        );
      }
    });
  }

  void _onRightSidebarResize(
    double delta,
    double screenWidth, {
    required bool isDesktop,
  }) {
    setState(() {
      final expandDelta = -delta;

      // 若当前处于拖拽临时收起状态：监听未松手反向拉动
      if (_isRightSidebarTemporarilyCollapsed) {
        if (expandDelta > 0) {
          _rightSidebarReversePull += expandDelta;
          if (_rightSidebarReversePull >=
              LayoutBreakpoints.restoreDragThreshold) {
            // 达到 30px 反向拉动距离，还原显示！
            _isRightSidebarTemporarilyCollapsed = false;
            _rightSidebarWidth = LayoutBreakpoints.rightSidebarMinWidth;
            _rightSidebarOverdrag = 0.0;
            _rightSidebarReversePull = 0.0;
          }
        } else {
          // 继续向右拉，重置反向拉动累计
          _rightSidebarReversePull = 0.0;
        }
        return;
      }

      // 1. 若向右拖拽（变窄，expandDelta < 0）
      if (expandDelta < 0) {
        if (_rightSidebarWidth > LayoutBreakpoints.rightSidebarMinWidth) {
          final candidate = _rightSidebarWidth + expandDelta;
          if (candidate >= LayoutBreakpoints.rightSidebarMinWidth) {
            _rightSidebarWidth = candidate;
            _rightSidebarOverdrag = 0.0;
            return;
          } else {
            // 穿过最小宽度 200px 边界，超出的部分计入弹性拉动距离
            final excess = LayoutBreakpoints.rightSidebarMinWidth - candidate;
            _rightSidebarWidth = LayoutBreakpoints.rightSidebarMinWidth;
            _rightSidebarOverdrag += excess;
          }
        } else {
          // 已处于最小宽度 200px，用户持续向右拉动累计弹性距离
          _rightSidebarOverdrag += (-expandDelta);
        }

        // 达到或超过心理弹性距离 (100px) 后，触发临时收起隐藏
        if (_rightSidebarOverdrag >= LayoutBreakpoints.collapseElasticDistance) {
          _isRightSidebarTemporarilyCollapsed = true;
          _rightSidebarReversePull = 0.0;
        }
        return;
      }

      // 2. 若向左拖拽变宽 (expandDelta > 0)
      if (_rightSidebarOverdrag > 0) {
        final consumed = expandDelta.clamp(0.0, _rightSidebarOverdrag);
        _rightSidebarOverdrag -= consumed;
        final remainingExpand = expandDelta - consumed;
        if (_rightSidebarOverdrag > 0 || remainingExpand <= 0) {
          return;
        }
      }

      final isBothOpen = isDesktop &&
          _isLeftSidebarOpen &&
          !_isLeftSidebarTemporarilyCollapsed &&
          _isAiSidebarOpen &&
          !_isRightSidebarTemporarilyCollapsed;
      if (isBothOpen) {
        // 双边栏同时打开时：主区域与左侧边栏以等比例 (1:1 各 50%) 共同承担压缩空间
        final totalContentWidth = screenWidth - 16.0;
        final currentMainWidth =
            totalContentWidth - _leftSidebarWidth - _rightSidebarWidth;

        final maxMainCompress = (currentMainWidth - LayoutBreakpoints.mainAreaMinWidth)
            .clamp(0.0, double.infinity);
        final maxLeftCompress =
            (_leftSidebarWidth - LayoutBreakpoints.leftSidebarMinWidth)
                .clamp(0.0, double.infinity);

        var halfDelta = expandDelta / 2;
        var mainCompress = halfDelta.clamp(0.0, maxMainCompress);
        var leftCompress = halfDelta.clamp(0.0, maxLeftCompress);

        // 若一方达到压缩极限，溢出部分尝试由另一方额外吸收
        if (halfDelta > maxMainCompress) {
          final excess = halfDelta - maxMainCompress;
          final additionalLeft =
              excess.clamp(0.0, maxLeftCompress - leftCompress);
          leftCompress += additionalLeft;
        } else if (halfDelta > maxLeftCompress) {
          final excess = halfDelta - maxLeftCompress;
          final additionalMain =
              excess.clamp(0.0, maxMainCompress - mainCompress);
          mainCompress += additionalMain;
        }

        final actualExpand = mainCompress + leftCompress;
        final proposedRightWidth = (_rightSidebarWidth + actualExpand)
            .clamp(LayoutBreakpoints.rightSidebarMinWidth,
                LayoutBreakpoints.rightSidebarMaxWidth);

        final realDelta = proposedRightWidth - _rightSidebarWidth;
        _rightSidebarWidth = proposedRightWidth;

        // 左边栏相应压缩，保底停留在 180px 最小宽度，不立刻隐藏
        final proposedLeftWidth = _leftSidebarWidth -
            (leftCompress *
                (actualExpand > 0 ? (realDelta / actualExpand) : 1.0));
        _leftSidebarWidth = proposedLeftWidth.clamp(
          LayoutBreakpoints.leftSidebarMinWidth,
          LayoutBreakpoints.leftSidebarMaxWidth,
        );
      } else {
        // 单侧展开（桌面单边或平板端）：由主区域承担压缩
        final maxAllowed = (screenWidth -
                LayoutBreakpoints.mainAreaMinWidth -
                8.0)
            .clamp(
          LayoutBreakpoints.rightSidebarMinWidth,
          LayoutBreakpoints.rightSidebarMaxWidth,
        );
        _rightSidebarWidth = (_rightSidebarWidth + expandDelta).clamp(
          LayoutBreakpoints.rightSidebarMinWidth,
          maxAllowed,
        );
      }
    });
  }

  void _resetLeftSidebarWidth() {
    setState(() {
      _leftSidebarWidth = LayoutBreakpoints.leftSidebarDefaultWidth;
      _leftSidebarOverdrag = 0.0;
      _leftSidebarReversePull = 0.0;
      _isLeftSidebarTemporarilyCollapsed = false;
    });
  }

  void _resetRightSidebarWidth() {
    setState(() {
      _rightSidebarWidth = LayoutBreakpoints.rightSidebarDefaultWidth;
      _rightSidebarOverdrag = 0.0;
      _rightSidebarReversePull = 0.0;
      _isRightSidebarTemporarilyCollapsed = false;
    });
  }

  void _handleSelectEntry(DiaryEntry selected) {
    context.read<DiaryEditorialCubit>().loadEntry(selected);
    context.read<InquiryCubit>().resetHistory(selected.inquiryHistory);
    context.read<DiaryListCubit>().setActiveEntryId(selected.id);
  }

  void _handleEntryCreated(DiaryEntry created) {
    context.read<DiaryEditorialCubit>().loadEntry(created);
    context.read<InquiryCubit>().resetHistory([]);
    context.read<DiaryListCubit>().setActiveEntryId(created.id);
    _focusNode.requestFocus();
  }

  Future<void> _handleEntryDeleted(String deletedId) async {
    final editorialCubit = context.read<DiaryEditorialCubit>();
    final inquiryCubit = context.read<InquiryCubit>();
    final listCubit = context.read<DiaryListCubit>();
    if (editorialCubit.state.entry.id == deletedId) {
      final remaining = listCubit.state.entries
          .where((e) => e.id != deletedId)
          .toList();
      if (remaining.isNotEmpty) {
        final nextEntry = remaining.first;
        editorialCubit.loadEntry(nextEntry);
        inquiryCubit.resetHistory(nextEntry.inquiryHistory);
        listCubit.setActiveEntryId(nextEntry.id);
      } else {
        final fresh = await listCubit.createEntry();
        editorialCubit.loadEntry(fresh);
        inquiryCubit.resetHistory([]);
        listCubit.setActiveEntryId(fresh.id);
      }
    }
  }

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
    final isDesktop = screenWidth >= LayoutBreakpoints.desktop;
    final isTablet = screenWidth >= LayoutBreakpoints.tablet &&
        screenWidth < LayoutBreakpoints.desktop;
    final isMobile = screenWidth < LayoutBreakpoints.tablet;

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

        return CallbackShortcuts(
          bindings: {
            // 桌面/平板端快捷键: Cmd/Ctrl + Enter 呼叫主编
            const SingleActivator(LogicalKeyboardKey.enter, meta: true): () {
              if (!isMobile) {
                setState(() => _isAiSidebarOpen = true);
              }
              context.read<DiaryEditorialCubit>().requestAiAnalysis();
            },
            const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
              if (!isMobile) {
                setState(() => _isAiSidebarOpen = true);
              }
              context.read<DiaryEditorialCubit>().requestAiAnalysis();
            },
          },
          child: Scaffold(
            backgroundColor: tokens.canvas,
            drawer: isDesktop
                ? null
                : DiaryManagementDrawer(
                    isPermanent: false,
                    onOpenCorpus: () => _openCorpus(context),
                    onOpenSettings: () => _openSettings(context),
                    onSelectEntry: _handleSelectEntry,
                    onEntryCreated: _handleEntryCreated,
                    onEntryDeleted: _handleEntryDeleted,
                  ),
            appBar: AppBar(
              backgroundColor: tokens.canvas,
              elevation: 0,
              titleSpacing: 0,
              leading: Builder(
                builder: (scaffoldCtx) => IconButton(
                  key: const ValueKey('diary_drawer_button'),
                  icon: Icon(
                    isDesktop
                        ? (_isLeftSidebarOpen
                            ? Icons.menu_open
                            : Icons.menu_book_outlined)
                        : Icons.menu_book_outlined,
                  ),
                  tooltip: isDesktop
                      ? (_isLeftSidebarOpen ? '收起随笔手账' : '展开随笔手账')
                      : '随笔手账与管理',
                  onPressed: () {
                    if (isDesktop) {
                      setState(() {
                        _isLeftSidebarOpen = !_isLeftSidebarOpen;
                        _isLeftSidebarTemporarilyCollapsed = false;
                        _leftSidebarOverdrag = 0.0;
                        _leftSidebarReversePull = 0.0;
                      });
                    } else {
                      Scaffold.of(scaffoldCtx).openDrawer();
                    }
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
                    _handleEntryCreated(newEntry);
                  },
                ),
                if (!isMobile)
                  IconButton(
                    key: const ValueKey('toggle_ai_sidebar_button'),
                    icon: Icon(
                      _isAiSidebarOpen
                          ? Icons.auto_awesome
                          : Icons.auto_awesome_outlined,
                      size: 20,
                      color: _isAiSidebarOpen
                          ? tokens.terracotta
                          : tokens.textMuted,
                    ),
                    tooltip: _isAiSidebarOpen ? '收起主编视窗' : '展开主编视窗',
                    onPressed: () {
                      setState(() {
                        _isAiSidebarOpen = !_isAiSidebarOpen;
                        _isRightSidebarTemporarilyCollapsed = false;
                        _rightSidebarOverdrag = 0.0;
                        _rightSidebarReversePull = 0.0;
                      });
                    },
                  ),
                const SizedBox(width: 4),
              ],
            ),
            body: isDesktop
                ? _buildDesktopLayout(context, state, tokens, screenWidth)
                : (isTablet
                    ? _buildTabletLayout(context, state, tokens, screenWidth)
                    : _buildMobileLayout(context, state, tokens)),
          ),
        );
      },
    );
  }

  /// 桌面端三栏布局 (默认显示左边栏与主区域，点击梳理右边栏显示，左右边栏支持自由拖拽调宽，主区域保持最小可视宽度)
  Widget _buildDesktopLayout(
    BuildContext context,
    DiaryEditorialState state,
    AppThemeTokens tokens,
    double screenWidth,
  ) {
    // 动态计算当前各栏可用宽度，严格保障主区域不低于 mainAreaMinWidth
    final showLeftDrawer =
        _isLeftSidebarOpen && !_isLeftSidebarTemporarilyCollapsed;
    final showRightInspector =
        _isAiSidebarOpen && !_isRightSidebarTemporarilyCollapsed;

    final activeRightWidth = showRightInspector ? _rightSidebarWidth : 0.0;
    final maxLeft = (screenWidth -
            activeRightWidth -
            LayoutBreakpoints.mainAreaMinWidth -
            (showRightInspector ? 16.0 : 8.0))
        .clamp(
      LayoutBreakpoints.leftSidebarMinWidth,
      LayoutBreakpoints.leftSidebarMaxWidth,
    );
    final effectiveLeftWidth =
        _leftSidebarWidth.clamp(LayoutBreakpoints.leftSidebarMinWidth, maxLeft);

    final activeLeftWidth = showLeftDrawer ? effectiveLeftWidth : 0.0;
    final maxRight = (screenWidth -
            activeLeftWidth -
            LayoutBreakpoints.mainAreaMinWidth -
            (showLeftDrawer ? 16.0 : 8.0))
        .clamp(
      LayoutBreakpoints.rightSidebarMinWidth,
      LayoutBreakpoints.rightSidebarMaxWidth,
    );
    final effectiveRightWidth = _rightSidebarWidth.clamp(
      LayoutBreakpoints.rightSidebarMinWidth,
      maxRight,
    );

    return Row(
      children: [
        // 1. 左边栏 (笔记列表) - 默认常驻显示，支持快捷折叠收起与用户手动拖拽调宽
        if (showLeftDrawer)
          SizedBox(
            width: effectiveLeftWidth,
            child: DiaryManagementDrawer(
              isPermanent: true,
              onOpenCorpus: () => _openCorpus(context),
              onOpenSettings: () => _openSettings(context),
              onSelectEntry: _handleSelectEntry,
              onEntryCreated: _handleEntryCreated,
              onEntryDeleted: _handleEntryDeleted,
            ),
          ),
        if (_isLeftSidebarOpen)
          PaneResizeHandle(
            key: const ValueKey('left_pane_resize_handle'),
            tooltip: '拖拽调整笔记列表宽度，双击恢复默认',
            onDelta: (delta) => _onLeftSidebarResize(delta, screenWidth),
            onReset: _resetLeftSidebarWidth,
            onDragEnd: _onLeftDragEnd,
          ),
        // 2. 主区域 (编辑稿纸与工具条) - 保持最小可视宽度并自适应占据剩余空间
        Expanded(
          child: Container(
            constraints: const BoxConstraints(
              minWidth: LayoutBreakpoints.mainAreaMinWidth,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Column(
              children: [
                Expanded(child: _buildWritingArea(tokens)),
                _buildBottomToolbar(context, state, tokens, isMobile: false),
              ],
            ),
          ),
        ),
        // 3. 右边栏 (主编梳理与追问视窗) - 点击梳理显示，支持手动拖拽调宽与随时收起
        if (_isAiSidebarOpen)
          PaneResizeHandle(
            key: const ValueKey('right_pane_resize_handle'),
            tooltip: '拖拽调整AI视窗宽度，双击恢复默认',
            onDelta: (delta) =>
                _onRightSidebarResize(delta, screenWidth, isDesktop: true),
            onReset: _resetRightSidebarWidth,
            onDragEnd: _onRightDragEnd,
          ),
        if (showRightInspector)
          SizedBox(
            width: effectiveRightWidth,
            child: _buildRightAiSidebar(
              context,
              state,
              tokens,
              onClose: () => setState(() => _isAiSidebarOpen = false),
            ),
          ),
      ],
    );
  }

  /// 平板端主区域与右边栏布局 (笔记列表侧滑出来，默认主区域，点击梳理右边栏显示，右边栏支持拖拽调宽)
  Widget _buildTabletLayout(
    BuildContext context,
    DiaryEditorialState state,
    AppThemeTokens tokens,
    double screenWidth,
  ) {
    final showRightInspector =
        _isAiSidebarOpen && !_isRightSidebarTemporarilyCollapsed;
    final maxRight = (screenWidth -
            LayoutBreakpoints.mainAreaMinWidth -
            8.0)
        .clamp(
      LayoutBreakpoints.rightSidebarMinWidth,
      LayoutBreakpoints.rightSidebarMaxWidth,
    );
    final effectiveRightWidth = _rightSidebarWidth.clamp(
      LayoutBreakpoints.rightSidebarMinWidth,
      maxRight,
    );

    return Row(
      children: [
        // 1. 主区域 (编辑稿纸与工具条) - 保持最小可视宽度并占据主要空间
        Expanded(
          child: Container(
            constraints: const BoxConstraints(
              minWidth: LayoutBreakpoints.mainAreaMinWidth,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Expanded(child: _buildWritingArea(tokens)),
                _buildBottomToolbar(context, state, tokens, isMobile: false),
              ],
            ),
          ),
        ),
        // 2. 右边栏 (主编梳理与追问视窗) - 点击梳理显示，支持手动拖拽调宽与随时收起
        if (_isAiSidebarOpen)
          PaneResizeHandle(
            key: const ValueKey('right_pane_resize_handle'),
            tooltip: '拖拽调整AI视窗宽度，双击恢复默认',
            onDelta: (delta) =>
                _onRightSidebarResize(delta, screenWidth, isDesktop: false),
            onReset: _resetRightSidebarWidth,
            onDragEnd: _onRightDragEnd,
          ),
        if (showRightInspector)
          SizedBox(
            width: effectiveRightWidth,
            child: _buildRightAiSidebar(
              context,
              state,
              tokens,
              onClose: () => setState(() => _isAiSidebarOpen = false),
            ),
          ),
      ],
    );
  }

  /// 移动端单栏心流布局 (笔记列表侧滑出来，AI 从底部滑出来)
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
            onTap: () => _openAiBottomSheet(context, state, tokens),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.highlight,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: tokens.terracotta.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 16)),
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
        _buildBottomToolbar(context, state, tokens, isMobile: true),
      ],
    );
  }

  /// 呼出移动端 AI 梳理底部浮层
  void _openAiBottomSheet(
    BuildContext context,
    DiaryEditorialState state,
    AppThemeTokens tokens,
  ) {
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
  }

  /// 右侧 AI 视窗外壳 (桌面与平板通用)
  Widget _buildRightAiSidebar(
    BuildContext context,
    DiaryEditorialState state,
    AppThemeTokens tokens, {
    required VoidCallback onClose,
  }) {
    return Container(
      color: tokens.card.withValues(alpha: 0.5),
      child: Column(
        children: [
          // 顶部操作栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: tokens.canvas,
              border: Border(bottom: BorderSide(color: tokens.cardBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '主编梳理与追问',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const ValueKey('close_ai_sidebar_button'),
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: '收起AI视窗',
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          // 内容区域
          Expanded(
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
        ],
      ),
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
        hintText:
            '写下今天的经历、闪念与思绪...\n允许任意中英夹杂，拼写不全也无妨。\n主编会在右侧随时为你重塑地道表达。',
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
    AppThemeTokens tokens, {
    required bool isMobile,
  }) {
    final isAnalyzing = state.status == DiaryAnalysisStatus.analyzing;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isCompact = availableWidth < 380;
        final isVeryCompact = availableWidth < 280;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 16,
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
                    isVeryCompact
                        ? '${state.entry.metadata.wordCount} 字'
                        : '${state.entry.metadata.wordCount} 字 · 自动存盘',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: isVeryCompact ? 11 : 13,
                      color: tokens.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 在平板或桌面端，若已存在梳理结果且右边栏未展开，且空间充裕时提供快捷展开胶囊
                    if (!isMobile &&
                        state.entry.analysisResult != null &&
                        !_isAiSidebarOpen &&
                        availableWidth >= 380) ...[
                      TextButton.icon(
                        key: const ValueKey('view_insights_chip_button'),
                        onPressed: () {
                          setState(() => _isAiSidebarOpen = true);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: tokens.terracotta,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Text('✨', style: TextStyle(fontSize: 12)),
                        label: const Text(
                          '查看梳理洞察',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    ElevatedButton.icon(
                      key: const ValueKey('call_editor_button'),
                      onPressed: isAnalyzing
                          ? null
                          : () {
                              context
                                  .read<DiaryEditorialCubit>()
                                  .updateContent(_textCtrl.text);
                              if (!isMobile) {
                                setState(() => _isAiSidebarOpen = true);
                              }
                              context
                                  .read<DiaryEditorialCubit>()
                                  .requestAiAnalysis();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.terracotta,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 12 : 18,
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
                            : (isCompact ? '梳理' : '呼叫主编梳理'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isCompact ? 13 : 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
