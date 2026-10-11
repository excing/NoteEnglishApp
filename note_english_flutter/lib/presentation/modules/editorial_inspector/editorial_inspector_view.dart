import 'package:flutter/material.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/domain/models/analysis/diary_analysis_result.dart';
import 'package:note_english_flutter/presentation/common_widgets/paper_card.dart';

/// AI 主编梳理结构化视图 (Editorial Polish Inspector)
class EditorialInspectorView extends StatelessWidget {
  final DiaryAnalysisResult analysisResult;
  final int silentCorpusCount;
  final VoidCallback onStartInquiry;

  const EditorialInspectorView({
    super.key,
    required this.analysisResult,
    this.silentCorpusCount = 0,
    required this.onStartInquiry,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 头部说明
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tokens.terracotta,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Ed',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '纽约客式温和润色与重塑',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                key: const ValueKey('start_inquiry_button'),
                onPressed: onStartInquiry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: tokens.terracotta,
                  side: BorderSide(color: tokens.terracotta),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 14),
                label: const Text('向主编追问', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. 非英文字词翻译及解释 (若无则完全不显示，自适应隐藏)
          if (analysisResult.hasNonEnglishItems) ...[
            _buildSectionHeader(
              context,
              icon: Icons.translate,
              title: '非英文字词翻译及解释',
              badge: '${analysisResult.nonEnglishItems.length}',
            ),
            ...analysisResult.nonEnglishItems.map((item) {
              return PaperCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.original,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: tokens.terracotta,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '→  ${item.meaning}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (item.explanation.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.explanation,
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.textMuted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // 2. 不正确的英文表达及解释
          if (analysisResult.incorrectExpressions.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              icon: Icons.spellcheck,
              title: '不正确的英文表达及解释',
              badge: '${analysisResult.incorrectExpressions.length}',
            ),
            ...analysisResult.incorrectExpressions.map((item) {
              return PaperCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '原表达: "${item.original}"',
                      style: TextStyle(
                        fontSize: 14,
                        color: tokens.textMuted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('✓ ',
                            style: TextStyle(
                              color: tokens.sage,
                              fontWeight: FontWeight.bold,
                            )),
                        Expanded(
                          child: Text(
                            item.correction,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: tokens.sage,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: tokens.highlight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '💡 语法解析: ${item.explanation}',
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // 3. 原文风格的英文版本
          if (analysisResult.originalStyleEnglishVersion.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              icon: Icons.history_edu,
              title: '原文风格的英文版本 (保留你的本真口吻)',
            ),
            PaperCard(
              margin: const EdgeInsets.only(bottom: 20),
              child: SelectableText(
                analysisResult.originalStyleEnglishVersion,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ],

          // 4. 不地道的英文表达及解释 (思维桥梁)
          if (analysisResult.unnaturalExpressions.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              icon: Icons.alt_route,
              title: '不地道的英文表达及解释 · 思维桥梁',
              badge: '${analysisResult.unnaturalExpressions.length}',
            ),
            ...analysisResult.unnaturalExpressions.map((item) {
              return PaperCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '中式思维习惯: "${item.original}"',
                      style: TextStyle(
                        fontSize: 14,
                        color: tokens.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('✨ 地道表达: ',
                            style: TextStyle(
                              color: tokens.terracotta,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            )),
                        Expanded(
                          child: Text(
                            item.naturalAlternative,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: tokens.highlight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: tokens.cardBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🌉 ', style: const TextStyle(fontSize: 14)),
                          Expanded(
                            child: Text(
                              '思维跃迁: ${item.mindsetBridge}',
                              style: TextStyle(
                                fontSize: 13,
                                color: tokens.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // 5. 地道英文表达的进阶版本
          if (analysisResult.authenticAdvancedVersion.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              icon: Icons.auto_awesome,
              title: '地道英文表达的进阶版本 (母语高质感重塑)',
            ),
            PaperCard(
              margin: const EdgeInsets.only(bottom: 20),
              borderColor: tokens.terracotta.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    analysisResult.authenticAdvancedVersion,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                          color: tokens.textPrimary,
                          height: 1.8,
                        ),
                  ),
                ],
              ),
            ),
          ],

          // 自动语料入库反馈微徽章 (不显示语料列表，仅给出温润入库提示)
          if (silentCorpusCount > 0) ...[
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: tokens.highlight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tokens.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.collections_bookmark_outlined,
                        size: 16, color: tokens.sage),
                    const SizedBox(width: 6),
                    Text(
                      '已自动将 $silentCorpusCount 条核心生动表达收录进专属语料库',
                      style: TextStyle(
                        fontSize: 13,
                        color: tokens.sage,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? badge,
  }) {
    final tokens = AppThemeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: tokens.terracotta),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: tokens.highlight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: tokens.terracotta,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
