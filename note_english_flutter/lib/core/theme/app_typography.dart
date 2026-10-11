import 'package:flutter/material.dart';

/// 排版即界面 (Typography-First System) - 单一信源
class AppTypography {
  AppTypography._();

  static const double bodyHeight = 1.85; // 正文行高 1.8 ~ 1.85 黄金呼吸节奏
  static const double headingHeight = 1.35;

  /// 构建全局文本主题
  static TextTheme createTextTheme(Color primaryColor, Color mutedColor) {
    return TextTheme(
      // 随笔正文 (手账/稿纸书写质感)
      bodyLarge: TextStyle(
        fontSize: 18.0,
        height: bodyHeight,
        letterSpacing: 0.3,
        color: primaryColor,
        fontWeight: FontWeight.normal,
      ),
      // 辅助说明与注释
      bodyMedium: TextStyle(
        fontSize: 15.0,
        height: bodyHeight,
        letterSpacing: 0.2,
        color: mutedColor,
        fontWeight: FontWeight.normal,
      ),
      // 标签与微小注脚
      bodySmall: TextStyle(
        fontSize: 13.0,
        height: 1.6,
        letterSpacing: 0.1,
        color: mutedColor,
      ),
      // 主标题 (纽约客文学质感)
      headlineMedium: TextStyle(
        fontSize: 24.0,
        height: headingHeight,
        letterSpacing: -0.2,
        color: primaryColor,
        fontWeight: FontWeight.w600,
      ),
      // 卡片副标题
      titleMedium: TextStyle(
        fontSize: 17.0,
        height: headingHeight,
        letterSpacing: 0.1,
        color: primaryColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
