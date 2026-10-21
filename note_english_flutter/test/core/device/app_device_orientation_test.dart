import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/core/device/app_device_orientation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppDeviceOrientation (单一信源规范测试)', () {
    test('preferredOrientations 单一信源定义仅包含 portraitUp', () {
      expect(
        AppDeviceOrientation.preferredOrientations,
        equals([DeviceOrientation.portraitUp]),
      );
    });

    test('lockPreferredOrientations 正确向系统通道发送锁定竖屏请求', () async {
      final List<MethodCall> methodCalls = [];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
        methodCalls.add(call);
        return null;
      });

      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await AppDeviceOrientation.lockPreferredOrientations();

      expect(methodCalls, isNotEmpty);
      final setOrientationsCall = methodCalls.firstWhere(
        (call) => call.method == 'SystemChrome.setPreferredOrientations',
      );
      expect(
        setOrientationsCall.arguments,
        equals(['DeviceOrientation.portraitUp']),
      );
    });
  });
}
