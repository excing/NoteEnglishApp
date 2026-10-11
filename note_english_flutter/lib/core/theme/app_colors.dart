import 'package:flutter/material.dart';

/// 纸质与大地色系调色盘 (Paper & Earth Tone Palette) - 单一信源
class AppColors {
  AppColors._();

  // ---------- 浅色纸质模式 (Light Paper) ----------
  static const Color lightCanvas = Color(0xFFFAF7F2); // 温润米白纸
  static const Color lightCard = Color(0xFFFFFFFF); // 纯净纸面
  static const Color lightCardBorder = Color(0xFFEBE6DC); // 极淡纸质折痕线
  static const Color lightTextPrimary = Color(0xFF22201D); // 墨黑
  static const Color lightTextMuted = Color(0xFF736E65); // 褪色墨灰
  static const Color lightTerracotta = Color(0xFFB8593B); // 陶土赭石 (主行动点/地道表达)
  static const Color lightSage = Color(0xFF4E6E5D); // 鼠尾草绿 (内化完成/宁静生长)
  static const Color lightAmber = Color(0xFFB57D33); // 复古琥珀 (思维桥梁标签)
  static const Color lightHighlight = Color(0xFFF3EDE2); // 柔和选中背景

  // ---------- 深空暗夜模式 (Dark Espresso) ----------
  static const Color darkCanvas = Color(0xFF181715); // 深烘焙哑光黑
  static const Color darkCard = Color(0xFF22201D); // 柔和暗炭灰
  static const Color darkCardBorder = Color(0xFF2E2B27); // 暗部边界线
  static const Color darkTextPrimary = Color(0xFFF0EDE6); // 米灰白
  static const Color darkTextMuted = Color(0xFF9E988D); // 柔灰
  static const Color darkTerracotta = Color(0xFFD97354); // 暖赭红
  static const Color darkSage = Color(0xFF759B87); // 青苔绿
  static const Color darkAmber = Color(0xFFCCA05E); // 暖金
  static const Color darkHighlight = Color(0xFF2C2925);
}
