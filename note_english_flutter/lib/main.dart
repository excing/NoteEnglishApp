import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:note_english_flutter/application/diary/diary_list_cubit.dart';
import 'package:note_english_flutter/application/editorial/diary_editorial_cubit.dart';
import 'package:note_english_flutter/application/inquiry/inquiry_cubit.dart';
import 'package:note_english_flutter/application/quick_polish/quick_polish_cubit.dart';
import 'package:note_english_flutter/application/settings/ai_settings_cubit.dart';
import 'package:note_english_flutter/app/service_locator.dart';
import 'package:note_english_flutter/core/device/app_device_orientation.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/gateways/quick_polish_platform_gateway.dart';
import 'package:note_english_flutter/domain/gateways/weather_gateway.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';
import 'package:note_english_flutter/domain/services/editorial_analysis_service.dart';
import 'package:note_english_flutter/infrastructure/gateways/method_channel_quick_polish_platform_gateway.dart';
import 'package:note_english_flutter/presentation/modules/writing_studio/writing_studio_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await startNoteEnglishApp();
}

Future<void> startNoteEnglishApp() async {
  // 锁定移动端屏幕方向为竖屏，不主动随手机横向握持切换为横屏 (Single Source of Truth)
  try {
    await AppDeviceOrientation.lockPreferredOrientations();
  } catch (_) {}

  // 初始化多语言日期本地化
  try {
    await initializeDateFormatting('zh_CN', null);
  } catch (_) {}

  // 初始化服务定位器与依赖注入 (Single Source of Truth)
  await setupServiceLocator();

  // 初始化全局快捷润色与菜单栏常驻后台宿主
  try {
    await sl<QuickPolishCubit>().initialize();
  } catch (_) {}

  // 恢复持久化配置与随笔 (保证应用启动后设置与内容均为同步可用)
  final configRepo = sl<IAiConfigRepository>();
  final initialConfig = await configRepo.getConfig();

  final diaryRepo = sl<IDiaryRepository>();
  final existingEntries = await diaryRepo.getAllEntries();
  final DiaryEntry initialEntry;
  if (existingEntries.isNotEmpty) {
    initialEntry = existingEntries.first;
  } else {
    initialEntry = DiaryEntry.create(
      content: '今晚加班到九点多，走出来的时候外面下着很大的雨。'
          'Today work overtime until 9pm, outside is raining heavily. '
          '整个人疲惫到了极点，但街角那家深烘焙手冲的香气，忽然让我心里踏实下来。',
      metadata: DiaryMetadata(
        recordedAt: DateTime.now(),
        weather: WeatherCondition.rainy,
        wordCount: 38,
      ),
    );
    await diaryRepo.saveEntry(initialEntry);
  }

  runApp(NoteEnglishApp(
    initialEntry: initialEntry,
    initialConfig: initialConfig,
  ));
}

class NoteEnglishApp extends StatelessWidget {
  final DiaryEntry initialEntry;
  final AiProfileConfig initialConfig;

  const NoteEnglishApp({
    super.key,
    required this.initialEntry,
    this.initialConfig = const AiProfileConfig(),
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DiaryEditorialCubit>(
          create: (_) => DiaryEditorialCubit(
            diaryRepository: sl<IDiaryRepository>(),
            corpusRepository: sl<ICorpusRepository>(),
            configRepository: sl<IAiConfigRepository>(),
            aiGateway: sl(),
            weatherGateway: sl<IWeatherGateway>(),
            initialEntry: initialEntry,
          ),
        ),
        BlocProvider<DiaryListCubit>(
          create: (_) => DiaryListCubit(
            diaryRepository: sl<IDiaryRepository>(),
            initialActiveEntryId: initialEntry.id,
          ),
        ),
        BlocProvider<InquiryCubit>(
          create: (_) => InquiryCubit(
            diaryRepository: sl<IDiaryRepository>(),
            corpusRepository: sl<ICorpusRepository>(),
            configRepository: sl<IAiConfigRepository>(),
            aiGateway: sl(),
            initialHistory: initialEntry.inquiryHistory,
          ),
        ),
        BlocProvider<AiSettingsCubit>(
          lazy: false,
          create: (_) => AiSettingsCubit(
            configRepository: sl<IAiConfigRepository>(),
            aiGateway: sl(),
            initialConfig: initialConfig,
          ),
        ),
        if (sl.isRegistered<QuickPolishCubit>())
          BlocProvider<QuickPolishCubit>.value(
            value: sl<QuickPolishCubit>(),
          )
        else
          BlocProvider<QuickPolishCubit>(
            create: (_) => QuickPolishCubit(
              platformGateway: sl.isRegistered<IQuickPolishPlatformGateway>()
                  ? sl<IQuickPolishPlatformGateway>()
                  : MethodChannelQuickPolishPlatformGateway(),
              editorialAnalysisService: sl.isRegistered<EditorialAnalysisService>()
                  ? sl<EditorialAnalysisService>()
                  : EditorialAnalysisService(
                      aiGateway: sl<IAiGateway>(),
                      configRepository: sl<IAiConfigRepository>(),
                      corpusRepository: sl<ICorpusRepository>(),
                      diaryRepository: sl<IDiaryRepository>(),
                      weatherGateway: sl.isRegistered<IWeatherGateway>()
                          ? sl<IWeatherGateway>()
                          : null,
                    ),
            ),
          ),
      ],
      child: MaterialApp(
        title: 'OtterJot - 双语创作书房',
        debugShowCheckedModeBanner: false,
        theme: AppThemeTokens.createThemeData(isDark: false),
        darkTheme: AppThemeTokens.createThemeData(isDark: true),
        themeMode: ThemeMode.system,
        home: const WritingStudioPage(),
      ),
    );
  }
}
