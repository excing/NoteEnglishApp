import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_english_flutter/application/corpus/corpus_deck_cubit.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/core/theme/app_typography.dart';
import 'package:note_english_flutter/domain/models/corpus/mastery_status.dart';
import 'package:note_english_flutter/presentation/common_widgets/paper_card.dart';

/// 场景化生活语料库页面
class CorpusDeckPage extends StatelessWidget {
  const CorpusDeckPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('专属生活语料库'),
        elevation: 0,
        backgroundColor: tokens.canvas,
        foregroundColor: tokens.textPrimary,
      ),
      body: BlocBuilder<CorpusDeckCubit, CorpusDeckState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.collections_bookmark_outlined,
                      size: 64,
                      color: tokens.textMuted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '语料库尚未沉淀表达',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '每当你在随笔中呼叫主编梳理或追问时，AI 提取的高价值表达会自动静默存入这里。',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: tokens.textMuted),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return PaperCard(
                margin: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.expression,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: tokens.terracotta,
                            ),
                          ),
                        ),
                        PopupMenuButton<MasteryStatus>(
                          key: ValueKey('mastery_status_button_$index'),
                          initialValue: item.masteryStatus,
                          onSelected: (status) {
                            context.read<CorpusDeckCubit>().updateMastery(
                                  id: item.id,
                                  status: status,
                                );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.highlight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(item.masteryStatus.icon,
                                    style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  item.masteryStatus.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: tokens.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => MasteryStatus.values.map((s) {
                            return PopupMenuItem(
                              value: s,
                              child: Row(
                                children: [
                                  Text(s.icon),
                                  const SizedBox(width: 6),
                                  Text(s.label),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    if (item.phonetic.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.phonetic,
                        style: AppTypography.phonetic(tokens.textMuted),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      item.meaning,
                      style: TextStyle(
                        fontSize: 15,
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.usageContext.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '💡 用法: ${item.usageContext}',
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (item.source.sourceSnippet.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: tokens.canvas,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🔗 当时情境: "${item.source.sourceSnippet}"',
                          style: TextStyle(
                            fontSize: 12,
                            color: tokens.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
