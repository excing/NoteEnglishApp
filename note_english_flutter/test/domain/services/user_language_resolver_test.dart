import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/domain/services/user_language_resolver.dart';

void main() {
  group('UserLanguageResolver Tests (TDD)', () {
    const resolver = UserLanguageResolver();

    test('correctly resolves Chinese locales', () {
      expect(resolver.resolveLanguageName('zh_CN'), equals('中文'));
      expect(resolver.resolveLanguageName('zh-Hans_CN'), equals('中文'));
      expect(resolver.resolveLanguageName('zh_SG'), equals('中文'));
      expect(resolver.resolveLanguageName('zh_TW'), equals('中文'));
      expect(resolver.resolveLanguageName('zh_HK'), equals('中文'));
    });

    test('correctly resolves major world languages', () {
      expect(resolver.resolveLanguageName('en_US'), equals('英文'));
      expect(resolver.resolveLanguageName('ja_JP'), equals('日文'));
      expect(resolver.resolveLanguageName('ko_KR'), equals('韩文'));
      expect(resolver.resolveLanguageName('fr_FR'), equals('法文'));
      expect(resolver.resolveLanguageName('de_DE'), equals('德文'));
      expect(resolver.resolveLanguageName('es_ES'), equals('西班牙文'));
      expect(resolver.resolveLanguageName('it_IT'), equals('意大利文'));
      expect(resolver.resolveLanguageName('ru_RU'), equals('俄文'));
      expect(resolver.resolveLanguageName('pt_BR'), equals('葡萄牙文'));
    });

    test('gracefully handles unknown, empty or null locale override', () {
      expect(resolver.resolveLanguageName('nl_NL'), equals('nl_NL'));
      expect(resolver.resolveLanguageName(''), equals('中文'));
      // Default without override should not throw and return a non-empty string
      final defaultLang = resolver.resolveLanguageName();
      expect(defaultLang.isNotEmpty, isTrue);
    });
  });
}
