import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/core/theme/app_typography.dart';

void main() {
  group('AppTypography', () {
    test('phonetic style conforms to professional dictionary typography standards', () {
      const testColor = Colors.brown;
      final style = AppTypography.phonetic(testColor);

      expect(style.color, equals(testColor));
      expect(style.fontSize, equals(13.0));
      // 严禁使用斜体，确保 IPA 音标字符不发生缺失或歧义
      expect(style.fontStyle, equals(FontStyle.normal));
      // 必须配置跨平台可靠的字体降级链
      expect(style.fontFamilyFallback, isNotNull);
      expect(
        style.fontFamilyFallback,
        containsAll([
          '.AppleSystemUIFont',
          'Helvetica Neue',
          'Arial',
          'Lucida Grande',
          'sans-serif',
        ]),
      );
    });

    test('phonetic style allows custom fontSize', () {
      final style = AppTypography.phonetic(Colors.black, fontSize: 16.0);
      expect(style.fontSize, equals(16.0));
      expect(style.fontStyle, equals(FontStyle.normal));
    });
  });
}
