import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_english_flutter/application/inquiry/inquiry_cubit.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/presentation/common_widgets/paper_card.dart';

/// 情境追问交互抽屉/面板
class InquiryBottomSheet extends StatefulWidget {
  final DiaryEntry currentEntry;

  const InquiryBottomSheet({
    super.key,
    required this.currentEntry,
  });

  @override
  State<InquiryBottomSheet> createState() => _InquiryBottomSheetState();
}

class _InquiryBottomSheetState extends State<InquiryBottomSheet> {
  final TextEditingController _questionCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _questionCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _submitQuestion() {
    final text = _questionCtrl.text.trim();
    if (text.isEmpty) return;

    _questionCtrl.clear();
    context.read<InquiryCubit>().askQuestion(
          question: text,
          currentEntry: widget.currentEntry,
        );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: tokens.canvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 顶部拖动条与标题
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: tokens.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: tokens.cardBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology_outlined,
                        color: tokens.terracotta, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      '主编追问与语感切磋',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  key: const ValueKey('close_inquiry_button'),
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // 问答历史流
          Expanded(
            child: BlocConsumer<InquiryCubit, InquiryState>(
              listener: (context, state) {
                if (state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage!),
                      backgroundColor: tokens.terracotta,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state.history.isEmpty && !state.isLoading) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 48, color: tokens.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            '对梳理结果或词句搭配有疑问？',
                            style: TextStyle(
                              color: tokens.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '向主编随意追问，例如：“为什么这样改比我写的更好？”、“这里的介词能换吗？”',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: tokens.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.history.length + (state.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.history.length) {
                      return Padding(
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
                      );
                    }

                    final turn = state.history[index];
                    final resp = turn.response;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 用户追问气泡
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
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),

                        // AI 结构化回复卡片
                        PaperCard(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. 自然语言回复
                              Text(
                                resp.reply,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: tokens.textPrimary,
                                      fontSize: 15,
                                    ),
                              ),
                              const SizedBox(height: 12),

                              // 2. 重点总结
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
                                    Text('💡', style: const TextStyle(fontSize: 14)),
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

                              // 3. 示例 (如果有)
                              if (resp.hasExamples) ...[
                                const SizedBox(height: 12),
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
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('• ',
                                            style: TextStyle(
                                                color: tokens.terracotta)),
                                        Expanded(
                                          child: Text(
                                            ex,
                                            style: TextStyle(
                                              color: tokens.textPrimary,
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // 底部输入栏
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.card,
              border: Border(top: BorderSide(color: tokens.cardBorder)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('inquiry_input_field'),
                      controller: _questionCtrl,
                      onSubmitted: (_) => _submitQuestion(),
                      style: TextStyle(color: tokens.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '向主编追问细节、近义词辨析或文化用法...',
                        hintStyle: TextStyle(
                          color: tokens.textMuted.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: tokens.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: tokens.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: tokens.terracotta),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const ValueKey('send_inquiry_button'),
                    onPressed: _submitQuestion,
                    style: IconButton.styleFrom(
                      backgroundColor: tokens.terracotta,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.arrow_upward, size: 20),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
