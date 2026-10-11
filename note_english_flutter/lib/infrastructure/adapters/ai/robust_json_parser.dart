import 'dart:convert';

/// 健壮的 JSON 解析与清洗工具类 (Anti-Corruption Parser)
class RobustJsonParser {
  RobustJsonParser._();

  /// 清洗并解析可能包含 Markdown 围栏或闲聊前缀后缀的 LLM 输出
  static Map<String, dynamic> cleanAndParse(String rawInput) {
    var text = rawInput.trim();

    // 1. 去除首尾的 ```json ... ``` 或 ``` ... ``` 围栏
    if (text.startsWith('```')) {
      final firstNewline = text.indexOf('\n');
      if (firstNewline != -1) {
        text = text.substring(firstNewline + 1);
      }
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3);
      }
      text = text.trim();
    }

    // 2. 尝试直接解析
    try {
      final decoded = json.decode(text);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // 继续尝试进行区间提取
    }

    // 3. 寻找最外层的 '{' 和 '}'
    final startIndex = text.indexOf('{');
    final endIndex = text.lastIndexOf('}');

    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      final candidate = text.substring(startIndex, endIndex + 1).trim();
      try {
        final decoded = json.decode(candidate);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (e) {
        throw FormatException('提取的 JSON 片段语法无效: $e \n原文: $candidate');
      }
    }

    throw const FormatException('未在响应中找到有效的 JSON 对象结构');
  }
}
