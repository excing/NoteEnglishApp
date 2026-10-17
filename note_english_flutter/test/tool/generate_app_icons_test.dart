import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generate OtterJot macOS AppIcons', () async {
    final sizes = [1024, 512, 256, 128, 64, 32, 16];
    final outDir = Directory('macos/Runner/Assets.xcassets/AppIcon.appiconset');

    for (final size in sizes) {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));

      final scale = size / 1024.0;
      canvas.scale(scale, scale);

      _drawOtterJotIcon(canvas);

      final picture = recorder.endRecording();
      final img = await picture.toImage(size, size);
      final byteData = await img.toByteData(format: ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final file = File('${outDir.path}/app_icon_$size.png');
      await file.writeAsBytes(bytes);
      // ignore: avoid_print
      print('Generated ${file.path} (${size}x$size, ${bytes.length} bytes)');
    }
  });
}

void _drawOtterJotIcon(Canvas canvas) {
  // 1. Apple macOS Big Sur Standard Squircle Content Rect
  // 824x824 centered inside 1024x1024 (padding 100 on each side)
  final iconRect = Rect.fromCenter(
    center: const Offset(512, 512),
    width: 824,
    height: 824,
  );
  final iconRRect = RRect.fromRectAndRadius(iconRect, const Radius.circular(185));

  // 2. Drop Shadow under the squircle tile
  final shadowPaint1 = Paint()
    ..color = const Color(0x2622201D)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
  canvas.drawRRect(iconRRect.shift(const Offset(0, 18)), shadowPaint1);

  final shadowPaint2 = Paint()
    ..color = const Color(0x1A22201D)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  canvas.drawRRect(iconRRect.shift(const Offset(0, 6)), shadowPaint2);

  // 3. Squircle Base Card: Warm Paper White (#FAF7F2) with subtle gradient
  final bgPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFFAF7F2), Color(0xFFF2ECE1)],
      stops: [0.0, 0.5, 1.0],
    ).createShader(iconRect);
  canvas.drawRRect(iconRRect, bgPaint);

  // Subtle border rim
  final borderPaint = Paint()
    ..color = const Color(0xFFE8E2D8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  canvas.drawRRect(iconRRect, borderPaint);

  // Clip content inside the squircle
  canvas.save();
  canvas.clipRRect(iconRRect);

  // 4. Mascot - Otter Ears
  final earOuterPaint = Paint()..color = const Color(0xFFB57D33);
  final earInnerPaint = Paint()..color = const Color(0xFFFAF7F2);

  // Left ear
  canvas.drawCircle(const Offset(365, 340), 55, earOuterPaint);
  canvas.drawCircle(const Offset(365, 340), 32, earInnerPaint);

  // Right ear
  canvas.drawCircle(const Offset(659, 340), 55, earOuterPaint);
  canvas.drawCircle(const Offset(659, 340), 32, earInnerPaint);

  // 5. Mascot - Head Body (#CCA05E Warm Honey Amber)
  final headPaint = Paint()..color = const Color(0xFFCCA05E);
  canvas.drawCircle(const Offset(512, 500), 220, headPaint);

  // 6. Mascot - Cheeks & Muzzle (#FBF9F5 Cream Paper)
  final muzzlePaint = Paint()..color = const Color(0xFFFBF9F5);
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(512, 560), width: 310, height: 230),
    muzzlePaint,
  );

  // 7. Mascot - Eyes (Friendly curved happy arches)
  final eyePaint = Paint()
    ..color = const Color(0xFF22201D)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 14;

  final leftEyePath = Path()
    ..moveTo(415, 470)
    ..quadraticBezierTo(445, 435, 475, 470);
  canvas.drawPath(leftEyePath, eyePaint);

  final rightEyePath = Path()
    ..moveTo(549, 470)
    ..quadraticBezierTo(579, 435, 609, 470);
  canvas.drawPath(rightEyePath, eyePaint);

  // 8. Mascot - Cute Cheek Blush (#B8593B Terracotta with opacity)
  final blushPaint = Paint()..color = const Color(0x40B8593B);
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(390, 520), width: 55, height: 32),
    blushPaint,
  );
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(634, 520), width: 55, height: 32),
    blushPaint,
  );

  // 9. Mascot - Fountain Pen Nib Nose & Mouth
  // Nose shape shaped like a fountain pen tip
  final nosePaint = Paint()
    ..color = const Color(0xFF22201D)
    ..style = PaintingStyle.fill;
  final nibPath = Path()
    ..moveTo(512, 490)
    ..lineTo(484, 532)
    ..lineTo(540, 532)
    ..close();
  canvas.drawPath(nibPath, nosePaint);

  // Center slit & smile
  final mouthPaint = Paint()
    ..color = const Color(0xFF22201D)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 10;
  canvas.drawLine(const Offset(512, 532), const Offset(512, 555), mouthPaint);

  final smilePath = Path()
    ..moveTo(480, 555)
    ..quadraticBezierTo(512, 578, 544, 555);
  canvas.drawPath(smilePath, mouthPaint);

  // 10. Glowing Handheld Paper Note & Little Paws
  final noteRect = Rect.fromCenter(
    center: const Offset(512, 655),
    width: 140,
    height: 110,
  );
  final noteRRect = RRect.fromRectAndRadius(noteRect, const Radius.circular(20));

  final noteShadow = Paint()
    ..color = const Color(0x2022201D)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  canvas.drawRRect(noteRRect.shift(const Offset(0, 6)), noteShadow);

  final notePaint = Paint()..color = const Color(0xFFFFFFFF);
  canvas.drawRRect(noteRRect, notePaint);

  final noteBorder = Paint()
    ..color = const Color(0xFFE8E2D8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  canvas.drawRRect(noteRRect, noteBorder);

  // Note Content: Terracotta Star (#B8593B)
  _drawStar(canvas, const Offset(512, 655), 26, const Color(0xFFB8593B));

  // Paws holding the note
  final pawPaint = Paint()..color = const Color(0xFFB57D33);
  canvas.drawCircle(const Offset(430, 665), 32, pawPaint);
  canvas.drawCircle(const Offset(594, 665), 32, pawPaint);

  canvas.restore();
}

void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
  final path = Path();
  const points = 5;
  final innerRadius = radius * 0.45;
  var rot = math.pi / 2 * 3;
  const step = math.pi / points;

  var x = center.dx;
  var y = center.dy - radius;
  path.moveTo(x, y);

  for (var i = 0; i < points; i++) {
    x = center.dx + math.cos(rot) * radius;
    y = center.dy + math.sin(rot) * radius;
    path.lineTo(x, y);
    rot += step;

    x = center.dx + math.cos(rot) * innerRadius;
    y = center.dy + math.sin(rot) * innerRadius;
    path.lineTo(x, y);
    rot += step;
  }
  path.close();

  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;
  canvas.drawPath(path, paint);
}
