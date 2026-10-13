import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:note_english_flutter/application/diary/diary_list_cubit.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/presentation/common_widgets/paper_card.dart';

/// 随笔手账与管理抽屉 (Diary Management Drawer)
class DiaryManagementDrawer extends StatefulWidget {
  final void Function(DiaryEntry entry)? onSelectEntry;
  final void Function(DiaryEntry entry)? onEntryCreated;
  final void Function(String deletedEntryId)? onEntryDeleted;

  const DiaryManagementDrawer({
    super.key,
    this.onSelectEntry,
    this.onEntryCreated,
    this.onEntryDeleted,
  });

  @override
  State<DiaryManagementDrawer> createState() => _DiaryManagementDrawerState();
}

class _DiaryManagementDrawerState extends State<DiaryManagementDrawer> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
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

  Future<void> _confirmDelete(BuildContext context, DiaryEntry entry) async {
    final tokens = AppThemeTokens.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: tokens.terracotta, size: 22),
            const SizedBox(width: 8),
            Text(
              '确认删除随笔',
              style: TextStyle(
                color: tokens.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          '删除后该篇随笔及其关联的 AI 梳理和追问记录将无法恢复。确定继续吗？',
          style: TextStyle(color: tokens.textMuted, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('取消', style: TextStyle(color: tokens.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.terracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<DiaryListCubit>().deleteEntry(entry.id);
      widget.onEntryDeleted?.call(entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.85).clamp(320.0, 420.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: tokens.canvas,
      child: SafeArea(
        child: BlocBuilder<DiaryListCubit, DiaryListState>(
          builder: (context, state) {
            final filtered = state.filteredEntries;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 顶部标题栏与新建操作
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.menu_book, color: tokens.terracotta, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            '随笔手账',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: tokens.textPrimary,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tokens.highlight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${state.entries.length} 篇',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: tokens.terracotta,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // 新建随笔按钮
                      ElevatedButton.icon(
                        key: const ValueKey('new_diary_button'),
                        onPressed: () async {
                          final cubit = context.read<DiaryListCubit>();
                          final newEntry = await cubit.createEntry();
                          widget.onEntryCreated?.call(newEntry);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.terracotta,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          '新建随笔',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                // 搜索框
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: tokens.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tokens.cardBorder),
                    ),
                    child: TextField(
                      key: const ValueKey('search_diary_input'),
                      controller: _searchCtrl,
                      style: TextStyle(color: tokens.textPrimary, fontSize: 13),
                      onChanged: (text) {
                        context.read<DiaryListCubit>().setSearchQuery(text);
                      },
                      decoration: InputDecoration(
                        hintText: '搜索随笔内容或天气...',
                        hintStyle: TextStyle(
                          color: tokens.textMuted.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(Icons.search,
                            size: 18, color: tokens.textMuted),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  context.read<DiaryListCubit>().setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),
                Divider(color: tokens.cardBorder, height: 1),

                // 随笔列表视图
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState(context, tokens, state)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final entry = filtered[index];
                            final isActive = entry.id == state.activeEntryId;
                            return _buildEntryCard(
                              context: context,
                              entry: entry,
                              isActive: isActive,
                              tokens: tokens,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEntryCard({
    required BuildContext context,
    required DiaryEntry entry,
    required bool isActive,
    required AppThemeTokens tokens,
  }) {
    final previewText = entry.content.trim().isEmpty
        ? '空白随笔草稿...'
        : entry.content.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.read<DiaryListCubit>().setActiveEntryId(entry.id);
          widget.onSelectEntry?.call(entry);
          Navigator.of(context).pop();
        },
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? tokens.highlight : tokens.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? tokens.terracotta
                  : tokens.cardBorder,
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部信息：时间、天气、当前编辑中标识、删除按钮
              Row(
                children: [
                  Text(
                    entry.metadata.weather.icon,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatDate(entry.metadata.recordedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tokens.terracotta.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '当前编辑',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: tokens.terracotta,
                        ),
                      ),
                    ),
                  // 删除按钮
                  IconButton(
                    key: ValueKey('delete_diary_button_${entry.id}'),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: tokens.textMuted.withValues(alpha: 0.7),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    splashRadius: 16,
                    tooltip: '删除随笔',
                    onPressed: () => _confirmDelete(context, entry),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 正文内容预览 (最多两行)
              Text(
                previewText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: entry.content.trim().isEmpty
                      ? tokens.textMuted.withValues(alpha: 0.6)
                      : tokens.textPrimary,
                  fontStyle: entry.content.trim().isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
              const SizedBox(height: 10),

              // 底部状态徽章：字数、AI 梳理状态、追问轮数
              Row(
                children: [
                  Text(
                    '${entry.metadata.wordCount} 字',
                    style: TextStyle(fontSize: 11, color: tokens.textMuted),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(entry.status, tokens),
                  if (entry.inquiryHistory.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tokens.canvas,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: tokens.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 11, color: tokens.terracotta),
                          const SizedBox(width: 3),
                          Text(
                            '${entry.inquiryHistory.length} 轮追问',
                            style: TextStyle(
                              fontSize: 11,
                              color: tokens.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(DiaryAnalysisStatus status, AppThemeTokens tokens) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case DiaryAnalysisStatus.completed:
        bg = tokens.sage.withValues(alpha: 0.15);
        fg = tokens.sage;
        text = '已梳理';
        break;
      case DiaryAnalysisStatus.analyzing:
        bg = tokens.amber.withValues(alpha: 0.15);
        fg = tokens.amber;
        text = '梳理中';
        break;
      case DiaryAnalysisStatus.failed:
        bg = tokens.terracotta.withValues(alpha: 0.15);
        fg = tokens.terracotta;
        text = '失败';
        break;
      case DiaryAnalysisStatus.draft:
        bg = tokens.cardBorder.withValues(alpha: 0.5);
        fg = tokens.textMuted;
        text = '草稿';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppThemeTokens tokens,
    DiaryListState state,
  ) {
    final isSearching = state.searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.notes,
              size: 48,
              color: tokens.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              isSearching ? '未找到匹配的随笔' : '暂无随笔记录',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? '尝试搜索其他关键词或检查错别字'
                  : '点击上方“新建随笔”，写下今天的经历与思绪',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: tokens.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
