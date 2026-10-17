import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generate OtterJot macOS AppIcons', () async {
    final sizes = [1024, 512, 256, 128, 64, 32, 16];
    final outDir = Directory('macos/Runner/Assets.xcassets/AppIcon.appiconset');

    for (final size in sizes) {
      final bytes = await _renderIcon(size, size, fullBleed: false);
      final file = File('${outDir.path}/app_icon_$size.png');
      await file.writeAsBytes(bytes);
      // ignore: avoid_print
      print('Generated macOS ${file.path} (${size}x$size)');
    }
  });

  test('generate OtterJot iOS AppIcons', () async {
    final outDir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
    final iosSpecs = <String, int>{
      'Icon-App-20x20@1x.png': 20,
      'Icon-App-20x20@2x.png': 40,
      'Icon-App-20x20@3x.png': 60,
      'Icon-App-29x29@1x.png': 29,
      'Icon-App-29x29@2x.png': 58,
      'Icon-App-29x29@3x.png': 87,
      'Icon-App-40x40@1x.png': 40,
      'Icon-App-40x40@2x.png': 80,
      'Icon-App-40x40@3x.png': 120,
      'Icon-App-60x60@2x.png': 120,
      'Icon-App-60x60@3x.png': 180,
      'Icon-App-76x76@1x.png': 76,
      'Icon-App-76x76@2x.png': 152,
      'Icon-App-83.5x83.5@2x.png': 167,
      'Icon-App-1024x1024@1x.png': 1024,
    };

    for (final entry in iosSpecs.entries) {
      final bytes = await _renderIcon(entry.value, entry.value, fullBleed: true);
      final file = File('${outDir.path}/${entry.key}');
      await file.writeAsBytes(bytes);
      // ignore: avoid_print
      print('Generated iOS ${file.path} (${entry.value}x${entry.value})');
    }
  });

  test('generate OtterJot Android AppIcons', () async {
    final androidSpecs = <String, int>{
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
    };

    for (final entry in androidSpecs.entries) {
      final bytes = await _renderIcon(entry.value, entry.value, fullBleed: false);
      final file = File(entry.key);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      // ignore: avoid_print
      print('Generated Android ${file.path} (${entry.value}x${entry.value})');
    }
  });

  test('generate OtterJot Web AppIcons and Favicon', () async {
    final webSpecs = <String, ({int size, bool fullBleed})>{
      'web/favicon.png': (size: 32, fullBleed: false),
      'web/icons/Icon-192.png': (size: 192, fullBleed: false),
      'web/icons/Icon-512.png': (size: 512, fullBleed: false),
      'web/icons/Icon-maskable-192.png': (size: 192, fullBleed: true),
      'web/icons/Icon-maskable-512.png': (size: 512, fullBleed: true),
    };

    for (final entry in webSpecs.entries) {
      final bytes = await _renderIcon(entry.value.size, entry.value.size,
          fullBleed: entry.value.fullBleed);
      final file = File(entry.key);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      // ignore: avoid_print
      print('Generated Web ${file.path} (${entry.value.size}x${entry.value.size})');
    }
  });

  test('generate OtterJot Windows AppIcon .ico', () async {
    final icoSizes = [16, 32, 48, 64, 128, 256];
    final images = <({int size, Uint8List pngBytes})>[];

    for (final size in icoSizes) {
      final bytes = await _renderIcon(size, size, fullBleed: false);
      images.add((size: size, pngBytes: bytes));
    }

    final icoBytes = _encodeIco(images);
    final icoFile = File('windows/runner/resources/app_icon.ico');
    await icoFile.parent.create(recursive: true);
    await icoFile.writeAsBytes(icoBytes);
    // ignore: avoid_print
    print('Generated Windows ${icoFile.path} (${icoBytes.length} bytes)');
  });
}

Future<Uint8List> _renderIcon(int width, int height, {required bool fullBleed}) async {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

  final scaleX = width / 1024.0;
  final scaleY = height / 1024.0;
  canvas.scale(scaleX, scaleY);

  _drawOtterJotIcon(canvas, fullBleed: fullBleed);

  final picture = recorder.endRecording();
  final img = await picture.toImage(width, height);
  final byteData = await img.toByteData(format: ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

Uint8List _encodeIco(List<({int size, Uint8List pngBytes})> images) {
  final header = ByteData(6);
  header.setUint16(0, 0, Endian.little);
  header.setUint16(2, 1, Endian.little); // 1 = ICO
  header.setUint16(4, images.length, Endian.little);

  final dirSize = images.length * 16;
  var offset = 6 + dirSize;

  final dirBytes = BytesBuilder();
  final imagesBytes = BytesBuilder();

  for (final img in images) {
    final entry = ByteData(16);
    entry.setUint8(0, img.size == 256 ? 0 : img.size);
    entry.setUint8(1, img.size == 256 ? 0 : img.size);
    entry.setUint8(2, 0); // No palette
    entry.setUint8(3, 0); // Reserved
    entry.setUint16(4, 1, Endian.little); // Color planes
    entry.setUint16(6, 32, Endian.little); // Bits per pixel
    entry.setUint32(8, img.pngBytes.length, Endian.little);
    entry.setUint32(12, offset, Endian.little);

    dirBytes.add(entry.buffer.asUint8List());
    imagesBytes.add(img.pngBytes);
    offset += img.pngBytes.length;
  }

  final fullIco = BytesBuilder();
  fullIco.add(header.buffer.asUint8List());
  fullIco.add(dirBytes.toBytes());
  fullIco.add(imagesBytes.toBytes());
  return fullIco.toBytes();
}

void _drawOtterJotIcon(Canvas canvas, {required bool fullBleed}) {
  if (fullBleed) {
    // Full bleed background for iOS / Web maskable
    final fullRect = const Rect.fromLTWH(0, 0, 1024, 1024);
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFFAF7F2), Color(0xFFF2ECE1)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(fullRect);
    canvas.drawRect(fullRect, bgPaint);

    canvas.save();
    _drawMascot(canvas);
    canvas.restore();
  } else {
    // macOS Big Sur / Windows / Android squircle card on transparent canvas
    final iconRect = Rect.fromCenter(
      center: const Offset(512, 512),
      width: 824,
      height: 824,
    );
    final iconRRect = RRect.fromRectAndRadius(iconRect, const Radius.circular(185));

    // Drop shadow
    final shadowPaint1 = Paint()
      ..color = const Color(0x2622201D)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawRRect(iconRRect.shift(const Offset(0, 18)), shadowPaint1);

    final shadowPaint2 = Paint()
      ..color = const Color(0x1A22201D)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(iconRRect.shift(const Offset(0, 6)), shadowPaint2);

    // Card background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFFAF7F2), Color(0xFFF2ECE1)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(iconRect);
    canvas.drawRRect(iconRRect, bgPaint);

    // Subtle border
    final borderPaint = Paint()
      ..color = const Color(0xFFE8E2D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(iconRRect, borderPaint);

    canvas.save();
    canvas.clipRRect(iconRRect);
    _drawMascot(canvas);
    canvas.restore();
  }
}

void _drawMascot(Canvas canvas) {
  // Mascot - Otter Ears
  final earOuterPaint = Paint()..color = const Color(0xFFB57D33);
  final earInnerPaint = Paint()..color = const Color(0xFFFAF7F2);

  canvas.drawCircle(const Offset(365, 340), 55, earOuterPaint);
  canvas.drawCircle(const Offset(365, 340), 32, earInnerPaint);

  canvas.drawCircle(const Offset(659, 340), 55, earOuterPaint);
  canvas.drawCircle(const Offset(659, 340), 32, earInnerPaint);

  // Mascot - Head Body (#CCA05E Warm Honey Amber)
  final headPaint = Paint()..color = const Color(0xFFCCA05E);
  canvas.drawCircle(const Offset(512, 500), 220, headPaint);

  // Mascot - Cheeks & Muzzle (#FBF9F5 Cream Paper)
  final muzzlePaint = Paint()..color = const Color(0xFFFBF9F5);
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(512, 560), width: 310, height: 230),
    muzzlePaint,
  );

  // Mascot - Eyes (Friendly curved happy arches)
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

  // Mascot - Cute Cheek Blush (#B8593B Terracotta with opacity)
  final blushPaint = Paint()..color = const Color(0x40B8593B);
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(390, 520), width: 55, height: 32),
    blushPaint,
  );
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(634, 520), width: 55, height: 32),
    blushPaint,
  );

  // Mascot - Fountain Pen Nib Nose & Mouth
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

  // Glowing Handheld Paper Note & Little Paws
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
