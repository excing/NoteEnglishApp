import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('移动端屏幕方向原生配置契约测试 (Mobile Orientation Config Contract)', () {
    test('iOS Info.plist 中 iPhone 屏幕方向仅配置 UIInterfaceOrientationPortrait', () {
      final plistFile = File('ios/Runner/Info.plist');
      expect(plistFile.existsSync(), isTrue, reason: 'iOS Info.plist 文件必须存在');

      final content = plistFile.readAsStringSync();

      // 提取 UISupportedInterfaceOrientations 对应的数组内容（针对 iPhone 手机端）
      final phoneOrientationsRegex = RegExp(
        r'<key>UISupportedInterfaceOrientations</key>\s*<array>([\s\S]*?)</array>',
      );
      final match = phoneOrientationsRegex.firstMatch(content);
      expect(match, isNotNull, reason: '必须定义 UISupportedInterfaceOrientations 字典项');

      final arrayContent = match!.group(1)!;

      // 必须包含 UIInterfaceOrientationPortrait
      expect(
        arrayContent.contains('<string>UIInterfaceOrientationPortrait</string>'),
        isTrue,
        reason: 'iPhone 必须支持竖屏',
      );

      // 严禁包含横屏选项（防止手机横放时切到横屏）
      expect(
        arrayContent.contains('UIInterfaceOrientationLandscapeLeft'),
        isFalse,
        reason: 'iPhone 不应支持 LandscapeLeft',
      );
      expect(
        arrayContent.contains('UIInterfaceOrientationLandscapeRight'),
        isFalse,
        reason: 'iPhone 不应支持 LandscapeRight',
      );
    });

    test('Android AndroidManifest.xml 中 MainActivity 必须配置 android:screenOrientation="portrait"', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue, reason: 'AndroidManifest.xml 必须存在');

      final content = manifestFile.readAsStringSync();

      // 检查 MainActivity 中是否明确配置了 android:screenOrientation="portrait"
      expect(
        content.contains('android:screenOrientation="portrait"'),
        isTrue,
        reason: 'MainActivity 必须配置 android:screenOrientation="portrait" 以锁死屏幕方向不主动旋转',
      );
    });
  });
}
