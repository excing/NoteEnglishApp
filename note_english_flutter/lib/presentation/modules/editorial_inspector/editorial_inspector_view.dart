import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_english_flutter/application/inquiry/inquiry_cubit.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/domain/models/analysis/diary_analysis_result.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/presentation/common_widgets/paper_card.dart';

/// AI 主编梳理结构化视图 (Editorial Polish Inspector)
/// 新交互设计：追问输入框直接置底在梳理界面下方，问答流内嵌呈现，可直接追问无需跳转二级界面
class EditorialInspectorView extends StatefulWidget {
  final DiaryAnalysisResult analysisResult;
  final DiaryEntry currentEntry;
  final int silentCorpusCount;

  const EditorialInspectorView({
    super.key,
    required this.analysisResult,
    required this.currentEntry,
    this.silentCorpusCount = 0,
  });

  @override
  State<EditorialInspectorView> createState() => _EditorialInspectorViewState();
}

class _EditorialInspectorViewState extends State<EditorialInspectorView> {
  late final TextEditingController _inquiryCtrl;
  late final ScrollController _scrollCtrl;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _inquiryCtrl = TextEditingController();
    _scrollCtrl = ScrollController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _inquiryCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitInquiry() {
    final text = _inquiryCtrl.text.trim();
    if (text.isEmpty) return;

    _inquiryCtrl.clear();
    context.read<InquiryCubit>().askQuestion(
          question: text,
          currentEntry: widget.currentEntry,
        );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final analysisResult = widget.analysisResult;

    return Stack(
      children: [
        // 顶部可滚动梳理报告与追问问答流 (底部留出 96px 留白给浮空岛)
        Positioned.fill(
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 96.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 头部说明
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                const SizedBox(height: 16),

                // 1. 非英文字词翻译及解释 (若无则自适应隐藏)
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
                              Text(
                                '正确修改: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: tokens.sage,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  item.correction,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (item.explanation.isNotEmpty) ...[
                            const SizedBox(height: 8),
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

                // 3. 原文风格的英文版本
                if (analysisResult.originalStyleEnglishVersion.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    icon: Icons.auto_stories,
                    title: '原文风格的英文版本 (保留你的本真口吻)',
                  ),
                  PaperCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      analysisResult.originalStyleEnglishVersion,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            color: tokens.textPrimary,
                            fontSize: 15,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 4. 思维桥梁与进阶版本
                if (analysisResult.unnaturalExpressions.isNotEmpty ||
                    analysisResult.authenticAdvancedVersion.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    icon: Icons.lightbulb_outline,
                    title: '思维桥梁 (Mindset Bridge) 与进阶版本',
                  ),
                  ...analysisResult.unnaturalExpressions.map((item) {
                    return PaperCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.compare_arrows,
                                  size: 16, color: tokens.terracotta),
                              const SizedBox(width: 6),
                              Text(
                                '不地道/中式表达: "${item.original}"',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: tokens.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('✨', style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.naturalAlternative,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: tokens.terracotta,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (item.mindsetBridge.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: tokens.highlight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('🌉', style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '思维桥梁: ${item.mindsetBridge}',
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
                        ],
                      ),
                    );
                  }),
                  if (analysisResult.authenticAdvancedVersion.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildSectionHeader(
                      context,
                      icon: Icons.star_border,
                      title: '地道英文表达的进阶版本',
                    ),
                    PaperCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        analysisResult.authenticAdvancedVersion,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.7,
                              fontWeight: FontWeight.w500,
                              color: tokens.textPrimary,
                              fontSize: 15,
                            ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],

                // 静默提取语料自动入库提示微徽章
                if (widget.silentCorpusCount > 0) ...[
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
                            '已自动将 ${widget.silentCorpusCount} 条核心生动表达收录进专属语料库',
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
                  const SizedBox(height: 16),
                ],

                // 分隔线：主编追问与语感切磋模块 (内嵌对话流)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(color: tokens.cardBorder, thickness: 1),
                ),
                _buildSectionHeader(
                  context,
                  icon: Icons.psychology_outlined,
                  title: '主编追问与语感切磋',
                ),
                const SizedBox(height: 8),

                // 追问历史与对话卡片流
                BlocConsumer<InquiryCubit, InquiryState>(
                  listener: (context, state) {
                    if (state.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.errorMessage!),
                          backgroundColor: tokens.terracotta,
                        ),
                      );
                    }
                    if (state.history.isNotEmpty || state.isLoading) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollCtrl.hasClients) {
                          _scrollCtrl.animateTo(
                            _scrollCtrl.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    }
                  },
                  builder: (context, state) {
                    if (state.history.isEmpty && !state.isLoading) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: tokens.card.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: tokens.cardBorder.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 20, color: tokens.terracotta),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '对上方梳理细节、用词搭配有疑问？可直接在下方输入框向主编追问。',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: tokens.textMuted,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...state.history.map((turn) {
                          final resp = turn.response;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 用户提问气泡 (靠右)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  margin: const EdgeInsets.only(left: 48, bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tokens.terracotta,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    turn.userQuestion,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),

                              // AI 结构化回复卡片
                              PaperCard(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. 自然语言回复
                                    Text(
                                      resp.reply,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: tokens.textPrimary,
                                            fontSize: 14,
                                            height: 1.5,
                                          ),
                                    ),
                                    const SizedBox(height: 10),

                                    // 2. 核心重点总结
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: tokens.highlight,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: tokens.cardBorder),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('💡',
                                              style: const TextStyle(fontSize: 14)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: '核心重点: ',
                                                    style: TextStyle(
                                                      color: tokens.amber,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: resp.keyTakeaway,
                                                    style: TextStyle(
                                                      color: tokens.textPrimary,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 3. 延伸应用示例
                                    if (resp.hasExamples) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        '延伸应用示例：',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: tokens.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ...resp.examples.map(
                                        (ex) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 4.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('• ',
                                                  style: TextStyle(
                                                      color: tokens.terracotta)),
                                              Expanded(
                                                child: Text(
                                                  ex,
                                                  style: TextStyle(
                                                    color: tokens.textPrimary,
                                                    fontSize: 13,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],

                                    // 4. 追问中提取并入库的语料小微徽章
                                    if (resp.extractedCorpus.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: resp.extractedCorpus.map((item) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: tokens.highlight,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: tokens.cardBorder),
                                            ),
                                            child: Text(
                                              '已收录: ${item.expression} (${item.meaning})',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: tokens.sage,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),

                        // 加载态动效：主编沉思中
                        if (state.isLoading)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: tokens.terracotta,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '主编沉思中...',
                                    style: TextStyle(
                                      color: tokens.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // 底部真正纯净无边框悬浮岛 (Floating Inquiry Island - No border, frosted glass)
        Positioned(
          left: 16,
          right: 16,
          bottom: 20,
          child: BlocBuilder<InquiryCubit, InquiryState>(
            builder: (context, state) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      color: tokens.card.withValues(alpha: 0.90),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.psychology_alt_outlined,
                            size: 20,
                            color: tokens.terracotta,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              key: const ValueKey('inquiry_input_field'),
                              controller: _inquiryCtrl,
                              focusNode: _focusNode,
                              enabled: !state.isLoading,
                              onSubmitted: (_) => _submitInquiry(),
                              style: TextStyle(
                                color: tokens.textPrimary,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: state.isLoading
                                    ? '主编正在解答上一条提问...'
                                    : '向主编追问细节、近义词辨析或文化用法...',
                                hintStyle: TextStyle(
                                  color: tokens.textMuted.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            key: const ValueKey('send_inquiry_button'),
                            borderRadius: BorderRadius.circular(20),
                            onTap: state.isLoading ? null : _submitInquiry,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: state.isLoading
                                    ? tokens.cardBorder
                                    : tokens.terracotta,
                                shape: BoxShape.circle,
                                boxShadow: state.isLoading
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: tokens.terracotta.withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: state.isLoading
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.arrow_upward,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
