import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/infrastructure/adapters/ai/robust_json_parser.dart';

void main() {
  group('RobustJsonParser Tests (TDD)', () {
    test('should parse standard clean JSON string', () {
      const cleanJson = '{"reply": "Hello", "count": 10}';
      final map = RobustJsonParser.cleanAndParse(cleanJson);
      expect(map['reply'], 'Hello');
      expect(map['count'], 10);
    });

    test('should strip markdown code block fences (```json ... ```)', () {
      const markdownJson = '''
```json
{
  "key": "value",
  "num": 42
}
```
''';
      final map = RobustJsonParser.cleanAndParse(markdownJson);
      expect(map['key'], 'value');
      expect(map['num'], 42);
    });

    test('should extract JSON when preceded or followed by LLM conversational chatter', () {
      const conversationalJson = '''
好的，这是为您梳理的随笔数据：
{
  "status": "success",
  "message": "done"
}
希望对您的英语学习有所帮助！
''';
      final map = RobustJsonParser.cleanAndParse(conversationalJson);
      expect(map['status'], 'success');
      expect(map['message'], 'done');
    });

    test('should throw FormatException when no valid JSON object is found', () {
      const invalidText = 'This is just pure text without any json.';
      expect(
        () => RobustJsonParser.cleanAndParse(invalidText),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
