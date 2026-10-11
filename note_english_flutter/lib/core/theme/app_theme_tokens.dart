import 'package:flutter/material.dart';
import 'package:note_english_flutter/core/theme/app_colors.dart';
import 'package:note_english_flutter/core/theme/app_typography.dart';

/// 设计令牌主题扩展 (ThemeExtension) - 单一信源
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  final Color canvas;
  final Color card;
  final Color cardBorder;
  final Color textPrimary;
  final Color textMuted;
  final Color terracotta;
  final Color sage;
  final Color amber;
  final Color highlight;

  const AppThemeTokens({
    required this.canvas,
    required this.card,
    required this.cardBorder,
    required this.textPrimary,
    required this.textMuted,
    required this.terracotta,
    required this.sage,
    required this.amber,
    required this.highlight,
  });

  static const light = AppThemeTokens(
    canvas: AppColors.lightCanvas,
    card: AppColors.lightCard,
    cardBorder: AppColors.lightCardBorder,
    textPrimary: AppColors.lightTextPrimary,
    textMuted: AppColors.lightTextMuted,
    terracotta: AppColors.lightTerracotta,
    sage: AppColors.lightSage,
    amber: AppColors.lightAmber,
    highlight: AppColors.lightHighlight,
  );

  static const dark = AppThemeTokens(
    canvas: AppColors.darkCanvas,
    card: AppColors.darkCard,
    cardBorder: AppColors.darkCardBorder,
    textPrimary: AppColors.darkTextPrimary,
    textMuted: AppColors.darkTextMuted,
    terracotta: AppColors.darkTerracotta,
    sage: AppColors.darkSage,
    amber: AppColors.darkAmber,
    highlight: AppColors.darkHighlight,
  );

  static AppThemeTokens of(BuildContext context) {
    return Theme.of(context).extension<AppThemeTokens>() ?? light;
  }

  @override
  AppThemeTokens copyWith({
    Color? canvas,
    Color? card,
    Color? cardBorder,
    Color? textPrimary,
    Color? textMuted,
    Color? terracotta,
    Color? sage,
    Color? amber,
    Color? highlight,
  }) {
    return AppThemeTokens(
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      terracotta: terracotta ?? this.terracotta,
      sage: sage ?? this.sage,
      amber: amber ?? this.amber,
      highlight: highlight ?? this.highlight,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      canvas: Color.lerp(canvas, other.canvas, t) ?? canvas,
      card: Color.lerp(card, other.card, t) ?? card,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t) ?? cardBorder,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      terracotta: Color.lerp(terracotta, other.terracotta, t) ?? terracotta,
      sage: Color.lerp(sage, other.sage, t) ?? sage,
      amber: Color.lerp(amber, other.amber, t) ?? amber,
      highlight: Color.lerp(highlight, other.highlight, t) ?? highlight,
    );
  }

  static ThemeData createThemeData({required bool isDark}) {
    final tokens = isDark ? dark : light;
    final textTheme = AppTypography.createTextTheme(
      tokens.textPrimary,
      tokens.textMuted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: tokens.canvas,
      cardColor: tokens.card,
      primaryColor: tokens.terracotta,
      textTheme: textTheme,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: tokens.terracotta,
              surface: tokens.card,
              onSurface: tokens.textPrimary,
            )
          : ColorScheme.light(
              primary: tokens.terracotta,
              surface: tokens.card,
              onSurface: tokens.textPrimary,
            ),
      extensions: [tokens],
    );
  }
}
