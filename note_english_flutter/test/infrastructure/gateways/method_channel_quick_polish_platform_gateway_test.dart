import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/infrastructure/gateways/method_channel_quick_polish_platform_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('io.github.excing.otterjot/quick_polish');
  late MethodChannelQuickPolishPlatformGateway gateway;
  final log = <MethodCall>[];

  setUp(() {
    log.clear();
    gateway = MethodChannelQuickPolishPlatformGateway();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'initializeQuickPolish':
          return true;
        case 'isAccessibilityGranted':
          return true;
        case 'requestAccessibilityPermission':
          return null;
        case 'setQuickPolishEnabled':
          return null;
        case 'showNotification':
          return null;
        case 'openAppInFinder':
          return null;
        case 'relaunchApp':
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('MethodChannelQuickPolishPlatformGateway Tests (TDD)', () {
    test('initialize invokes initializeQuickPolish', () async {
      await gateway.initialize();

      expect(log, hasLength(1));
      expect(log.first.method, 'initializeQuickPolish');
    });

    test('isAccessibilityGranted returns value from platform', () async {
      final granted = await gateway.isAccessibilityGranted();

      expect(granted, isTrue);
      expect(log.last.method, 'isAccessibilityGranted');
    });

    test('requestAccessibilityPermission invokes platform channel', () async {
      await gateway.requestAccessibilityPermission();

      expect(log.last.method, 'requestAccessibilityPermission');
    });

    test('setQuickPolishEnabled passes boolean flag', () async {
      await gateway.setQuickPolishEnabled(true);

      expect(log.last.method, 'setQuickPolishEnabled');
      expect(log.last.arguments, {'enabled': true});
    });

    test('showNotification passes title and body', () async {
      await gateway.showNotification(title: '标题', body: '内容');

      expect(log.last.method, 'showNotification');
      expect(log.last.arguments, {'title': '标题', 'body': '内容'});
    });

    test('openAppInFinder invokes openAppInFinder on native side', () async {
      await gateway.openAppInFinder();

      expect(log.last.method, 'openAppInFinder');
    });

    test('relaunchApp invokes relaunchApp on native side', () async {
      await gateway.relaunchApp();

      expect(log.last.method, 'relaunchApp');
    });

    test('incoming performQuickPolish call invokes registered handler and returns map', () async {
      await gateway.initialize();

      gateway.setQuickPolishHandler((rawText) async {
        return 'Polished: $rawText';
      });

      ByteData? rawResponse;
      await TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'io.github.excing.otterjot/quick_polish',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('performQuickPolish', {'selectedText': 'hello'}),
        ),
        (ByteData? data) {
          rawResponse = data;
        },
      );

      expect(rawResponse, isNotNull);
      final decoded = const StandardMethodCodec().decodeEnvelope(rawResponse!) as Map;
      expect(decoded['polishedText'], 'Polished: hello');
    });
  });
}
