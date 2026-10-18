import 'dart:io' show Platform;

/// 用户操作系统语言解析器 (单一信源 SSOT)
///
/// 用于获取用户电脑操作系统的当前系统语言设置，并将其转换为对应的自然语言名称（如“中文”、“日文”、“法文”等），
/// 以便直接替换提示词中硬编码的“中文”，保持提示词原有结构与语感纯正不变。
class UserLanguageResolver {
  const UserLanguageResolver();

  /// 解析系统当前的自然语言名称
  ///
  /// 支持通过 [localeOverride] 手动指定或在测试中覆盖，默认读取 [Platform.localeName]。
  String resolveLanguageName([String? localeOverride]) {
    String rawLocale;
    try {
      rawLocale = localeOverride ?? Platform.localeName;
    } catch (_) {
      rawLocale = 'zh_CN';
    }

    if (rawLocale.trim().isEmpty) {
      return '中文';
    }

    final normalized = rawLocale.replaceAll('-', '_').trim();
    final lower = normalized.toLowerCase();

    if (lower.startsWith('zh')) {
      return '中文';
    } else if (lower.startsWith('en')) {
      return '英文';
    } else if (lower.startsWith('ja')) {
      return '日文';
    } else if (lower.startsWith('ko')) {
      return '韩文';
    } else if (lower.startsWith('fr')) {
      return '法文';
    } else if (lower.startsWith('de')) {
      return '德文';
    } else if (lower.startsWith('es')) {
      return '西班牙文';
    } else if (lower.startsWith('it')) {
      return '意大利文';
    } else if (lower.startsWith('ru')) {
      return '俄文';
    } else if (lower.startsWith('pt')) {
      return '葡萄牙文';
    }

    return normalized;
  }
}
