import 'package:flutter/material.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';

/// OtterJot 吉祥物 Jotty 的矢量 Logo 组件 (无背景纯图形)
///
/// 采用 Canvas 纯矢量绘制，去除了底座卡片背景，仅保留水獭 Logo 核心主体，透明底色。
class OtterJotAvatar extends StatelessWidget {
  final double size;

  const OtterJotAvatar({
    super.key,
    this.size = 34.0,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _OtterJotAvatarPainter(tokens: tokens),
      ),
    );
  }
}

class _OtterJotAvatarPainter extends CustomPainter {
  final AppThemeTokens tokens;

  _OtterJotAvatarPainter({required this.tokens});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. 水獭外耳与内耳 (#B57D33 暖棕 & #FAF7F2 柔白)
    final earOuterPaint = Paint()..color = const Color(0xFFB57D33);
    final earInnerPaint = Paint()..color = const Color(0xFFFAF7F2);

    canvas.drawCircle(const Offset(24, 24), 14, earOuterPaint);
    canvas.drawCircle(const Offset(24, 24), 7.5, earInnerPaint);

    canvas.drawCircle(const Offset(76, 24), 14, earOuterPaint);
    canvas.drawCircle(const Offset(76, 24), 7.5, earInnerPaint);

    // 2. 头部主体 (#CCA05E 暖琥珀色)
    final headPaint = Paint()..color = const Color(0xFFCCA05E);
    canvas.drawCircle(const Offset(50, 52), 40, headPaint);

    // 3. 面部口鼻区域 (#FBF9F5 纯净纸面色)
    final muzzlePaint = Paint()..color = const Color(0xFFFBF9F5);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 61), width: 56, height: 40),
      muzzlePaint,
    );

    // 4. 眼睛 (微弯笑眼，深烘焙墨黑 #22201D)
    final eyePaint = Paint()
      ..color = const Color(0xFF22201D)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2;

    final leftEye = Path()..moveTo(33, 48)..quadraticBezierTo(39, 42, 45, 48);
    final rightEye = Path()..moveTo(55, 48)..quadraticBezierTo(61, 42, 67, 48);
    canvas.drawPath(leftEye, eyePaint);
    canvas.drawPath(rightEye, eyePaint);

    // 5. 腮红 (陶土赭石 #B8593B 柔和半透明)
    final blushPaint = Paint()..color = const Color(0x60B8593B);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(28, 56), width: 10, height: 6),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(72, 56), width: 10, height: 6),
      blushPaint,
    );

    // 6. 钢笔尖双关小鼻子 (Pen Nib Nose, #22201D)
    final nosePaint = Paint()
      ..color = const Color(0xFF22201D)
      ..style = PaintingStyle.fill;
    final nibPath = Path()
      ..moveTo(50, 50)
      ..lineTo(44.5, 58)
      ..lineTo(55.5, 58)
      ..close();
    canvas.drawPath(nibPath, nosePaint);

    // 嘴巴 (笑线)
    final mouthPaint = Paint()
      ..color = const Color(0xFF22201D)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;
    canvas.drawLine(const Offset(50, 58), const Offset(50, 63), mouthPaint);
    final smilePath = Path()..moveTo(45, 63)..quadraticBezierTo(50, 67, 55, 63);
    canvas.drawPath(smilePath, mouthPaint);

    // 7. 爪子与便签
    // 小便签 (#FFFFFF 纯白纸卡 + #E8E2D8 浅灰边框)
    final notePaint = Paint()..color = const Color(0xFFFFFFFF);
    final noteRect = Rect.fromCenter(center: const Offset(50, 77), width: 28, height: 20);
    canvas.drawRRect(RRect.fromRectAndRadius(noteRect, const Radius.circular(4.5)), notePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(noteRect, const Radius.circular(4.5)),
      Paint()
        ..color = const Color(0xFFE8E2D8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 便签中央小星点 (#B8593B 陶土赭石)
    final starPaint = Paint()..color = const Color(0xFFB8593B);
    canvas.drawCircle(const Offset(50, 77), 3.8, starPaint);

    // 肉乎乎小爪爪 (#B57D33)
    final pawPaint = Paint()..color = const Color(0xFFB57D33);
    canvas.drawCircle(const Offset(32, 78), 7.5, pawPaint);
    canvas.drawCircle(const Offset(68, 78), 7.5, pawPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OtterJotAvatarPainter oldDelegate) {
    return oldDelegate.tokens != tokens;
  }
}
