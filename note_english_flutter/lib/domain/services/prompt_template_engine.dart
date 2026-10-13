import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:note_english_flutter/domain/contracts/ai_contracts.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';

/// 提示词数据包，包含装配后的 systemPrompt 与 userMessage
class PromptBundle extends Equatable {
  final String systemPrompt;
  final String userMessage;

  const PromptBundle({
    required this.systemPrompt,
    required this.userMessage,
  });

  @override
  List<Object?> get props => [systemPrompt, userMessage];
}

/// 历史问答轮次表示
class HistoryTurnItem extends Equatable {
  final String question;
  final String answer;

  const HistoryTurnItem({
    required this.question,
    required this.answer,
  });

  @override
  List<Object?> get props => [question, answer];
}

/// 双层提示词组装引擎 (Domain Service)
class PromptTemplateEngine {
  const PromptTemplateEngine();

  /// 组装随笔 AI 梳理提示词
  PromptBundle buildAnalysisPromptBundle({
    required DiaryMetadata metadata,
    required String diaryContent,
    String? customSystemPrompt,
  }) {
    final effectiveStylePrompt = (customSystemPrompt != null &&
            customSystemPrompt.trim().isNotEmpty)
        ? customSystemPrompt.trim()
        : AiContracts.defaultEditorialSystemPrompt;

    final systemPrompt = '''
$effectiveStylePrompt

${AiContracts.diaryAnalysisSchemaInstruction}
''';

    final dateFormatted =
        DateFormat('yyyy-MM-dd HH:mm').format(metadata.recordedAt);
    final weatherIcon = metadata.weather.getIcon(isDay: metadata.isDay ?? true);
    final weatherName = metadata.detailedWeather ?? metadata.weather.label;
    final StringBuffer weatherBuffer =
        StringBuffer('$weatherIcon $weatherName');
    if (metadata.temperature != null) {
      final details = <String>[
        '${metadata.temperature!.round()}°C',
        if (metadata.apparentTemperature != null)
          '体感 ${metadata.apparentTemperature!.round()}°C',
        if (metadata.humidity != null) '湿度 ${metadata.humidity}%',
      ];
      weatherBuffer.write(' (${details.join('，')})');
    }
    final weatherDesc = weatherBuffer.toString();

    final userMessage = '''
【随笔元数据】
- 记录时间: $dateFormatted
- 当时天气: $weatherDesc
- 随笔字数: ${metadata.wordCount}
${metadata.location != null ? '- 记录地点: ${metadata.location}' : ''}

【随笔正文】
$diaryContent

请根据上述随笔内容，严格按照约束输出完整的 JSON 梳理数据。
''';

    return PromptBundle(
      systemPrompt: systemPrompt.trim(),
      userMessage: userMessage.trim(),
    );
  }

  /// 组装用户追问提示词 (携带完整上下文)
  PromptBundle buildInquiryPromptBundle({
    required String diaryContent,
    required String analysisContext,
    required List<HistoryTurnItem> historyTurns,
    required String userQuestion,
    String? customSystemPrompt,
  }) {
    final effectiveStylePrompt = (customSystemPrompt != null &&
            customSystemPrompt.trim().isNotEmpty)
        ? customSystemPrompt.trim()
        : AiContracts.defaultEditorialSystemPrompt;

    final systemPrompt = '''
$effectiveStylePrompt

${AiContracts.inquirySchemaInstruction}
''';

    final buffer = StringBuffer();
    buffer.writeln('【原始随笔正文】');
    buffer.writeln(diaryContent);
    buffer.writeln();
    buffer.writeln('【随笔的 AI 梳理结果上下文】');
    buffer.writeln(analysisContext);
    buffer.writeln();

    if (historyTurns.isNotEmpty) {
      buffer.writeln('【之前的追问与解答记录】');
      for (var i = 0; i < historyTurns.length; i++) {
        final turn = historyTurns[i];
        buffer.writeln('问: ${turn.question}');
        buffer.writeln('答: ${turn.answer}');
      }
      buffer.writeln();
    }

    buffer.writeln('【用户当前追问】');
    buffer.writeln(userQuestion);
    buffer.writeln();
    buffer.writeln('请结合上述完整上下文，深入解答用户的追问，并严格按规范输出 JSON。');

    return PromptBundle(
      systemPrompt: systemPrompt.trim(),
      userMessage: buffer.toString().trim(),
    );
  }
}
