import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:note_english_flutter/application/quick_polish/quick_polish_cubit.dart';
import 'package:note_english_flutter/application/quick_polish/quick_polish_state.dart';
import 'package:note_english_flutter/application/settings/ai_settings_cubit.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';
import 'package:note_english_flutter/presentation/modules/settings_studio/ai_settings_dialog.dart';

class MockAiConfigRepository extends Mock implements IAiConfigRepository {}
class MockAiGateway extends Mock implements IAiGateway {}
class MockQuickPolishCubit extends Mock implements QuickPolishCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(const AiProfileConfig());
  });

  group('AiSettingsDialog Quick Polish Integration Tests (TDD)', () {
    late MockAiConfigRepository mockAiConfigRepo;
    late MockAiGateway mockAiGateway;
    late AiSettingsCubit aiSettingsCubit;
    late MockQuickPolishCubit mockQuickPolishCubit;

    setUp(() {
      mockAiConfigRepo = MockAiConfigRepository();
      mockAiGateway = MockAiGateway();
      when(() => mockAiConfigRepo.getConfig()).thenAnswer(
        (_) async => const AiProfileConfig(
          baseUrl: 'https://api.openai.com/v1',
          apiKey: 'sk-test',
          selectedModel: 'gpt-4o',
        ),
      );
      when(() => mockAiConfigRepo.saveConfig(any())).thenAnswer((_) async {});

      aiSettingsCubit = AiSettingsCubit(
        configRepository: mockAiConfigRepo,
        aiGateway: mockAiGateway,
      );
      mockQuickPolishCubit = MockQuickPolishCubit();

      when(() => mockQuickPolishCubit.close()).thenAnswer((_) async {});
      when(() => mockQuickPolishCubit.toggleEnabled(any())).thenAnswer((_) async {});
      when(() => mockQuickPolishCubit.checkAccessibilityPermission()).thenAnswer((_) async {});
      when(() => mockQuickPolishCubit.requestAccessibilityPermission()).thenAnswer((_) async {});
      when(() => mockQuickPolishCubit.openAppInFinder()).thenAnswer((_) async {});
      when(() => mockQuickPolishCubit.relaunchApp()).thenAnswer((_) async {});
    });

    tearDown(() {
      aiSettingsCubit.close();
    });

    Widget buildTestWidget({required QuickPolishState quickPolishState}) {
      when(() => mockQuickPolishCubit.state).thenReturn(quickPolishState);
      when(() => mockQuickPolishCubit.stream).thenAnswer((_) => Stream.value(quickPolishState));

      return MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: [AppThemeTokens.light],
        ),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AiSettingsCubit>.value(value: aiSettingsCubit),
            BlocProvider<QuickPolishCubit>.value(value: mockQuickPolishCubit),
          ],
          child: const Scaffold(
            body: AiSettingsDialog(),
          ),
        ),
      );
    }

    testWidgets('renders dialog with quick polish section and ready status when granted', (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          quickPolishState: const QuickPolishState(
            isEnabled: true,
            isAccessibilityGranted: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('全局快捷润色 (fn + 空格)'), findsOneWidget);
      expect(find.byKey(const ValueKey('quick_polish_switch')), findsOneWidget);
      expect(find.textContaining('辅助功能已授权，快捷润色随时就绪'), findsOneWidget);

      final recheckBtn = find.byKey(const ValueKey('recheck_permission_button'));
      expect(recheckBtn, findsOneWidget);
      await tester.ensureVisible(recheckBtn);
      await tester.tap(recheckBtn);
      await tester.pump();

      verify(() => mockQuickPolishCubit.checkAccessibilityPermission()).called(1);
    });

    testWidgets('renders guidance card with instructions and action buttons when permission ungranted', (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          quickPolishState: const QuickPolishState(
            isEnabled: true,
            isAccessibilityGranted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('需要授予 macOS 系统辅助功能权限'), findsOneWidget);
      expect(find.textContaining('在任意第三方应用（如微信、Slack、浏览器）的输入框中'), findsOneWidget);
      expect(find.textContaining('点击下方「前往系统设置授权」'), findsOneWidget);
      expect(find.textContaining('在访达中定位应用'), findsWidgets);

      final requestBtn = find.byKey(const ValueKey('request_permission_button'));
      expect(requestBtn, findsOneWidget);
      await tester.ensureVisible(requestBtn);
      await tester.tap(requestBtn);
      await tester.pump();
      verify(() => mockQuickPolishCubit.requestAccessibilityPermission()).called(1);

      final relaunchBtn = find.byKey(const ValueKey('relaunch_app_button'));
      expect(relaunchBtn, findsOneWidget);
      await tester.ensureVisible(relaunchBtn);
      await tester.tap(relaunchBtn);
      await tester.pump();
      verify(() => mockQuickPolishCubit.relaunchApp()).called(1);

      final locateBtn = find.byKey(const ValueKey('locate_in_finder_button'));
      expect(locateBtn, findsOneWidget);
      await tester.ensureVisible(locateBtn);
      await tester.tap(locateBtn);
      await tester.pump();
      verify(() => mockQuickPolishCubit.openAppInFinder()).called(1);

      final recheckBtn = find.byKey(const ValueKey('recheck_permission_button'));
      expect(recheckBtn, findsOneWidget);
      await tester.ensureVisible(recheckBtn);
      await tester.tap(recheckBtn);
      await tester.pump();
      verify(() => mockQuickPolishCubit.checkAccessibilityPermission()).called(1);
    });

    testWidgets('toggling switch off invokes toggleEnabled(false) and hides guidance', (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          quickPolishState: const QuickPolishState(
            isEnabled: true,
            isAccessibilityGranted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switchWidget = find.byKey(const ValueKey('quick_polish_switch'));
      expect(switchWidget, findsOneWidget);
      await tester.ensureVisible(switchWidget);

      await tester.tap(switchWidget);
      await tester.pump();

      verify(() => mockQuickPolishCubit.toggleEnabled(false)).called(1);
    });
  });
}
