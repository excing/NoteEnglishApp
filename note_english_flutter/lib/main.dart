import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:note_english_flutter/application/editorial/diary_editorial_cubit.dart';
import 'package:note_english_flutter/application/settings/ai_settings_cubit.dart';
import 'package:note_english_flutter/app/service_locator.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';
import 'package:note_english_flutter/presentation/modules/writing_studio/writing_studio_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await startNoteEnglishApp();
}

Future<void> startNoteEnglishApp() async {
  // 初始化多语言日期本地化
  try {
    await initializeDateFormatting('zh_CN', null);
  } catch (_) {}

  // 初始化服务定位器与依赖注入 (Single Source of Truth)
  await setupServiceLocator();

  // 初始化默认随笔 (示例草稿)
  final initialEntry = DiaryEntry.create(
    content: '今晚加班到九点多，走出来的时候外面下着很大的雨。'
        'Today work overtime until 9pm, outside is raining heavily. '
        '整个人疲惫到了极点，但街角那家深烘焙手冲的香气，忽然让我心里踏实下来。',
    metadata: DiaryMetadata(
      recordedAt: DateTime.now(),
      weather: WeatherCondition.rainy,
      wordCount: 38,
    ),
  );

  runApp(NoteEnglishApp(initialEntry: initialEntry));
}

class NoteEnglishApp extends StatelessWidget {
  final DiaryEntry initialEntry;

  const NoteEnglishApp({
    super.key,
    required this.initialEntry,
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
            initialEntry: initialEntry,
          ),
        ),
        BlocProvider<AiSettingsCubit>(
          create: (_) => AiSettingsCubit(
            configRepository: sl<IAiConfigRepository>(),
            aiGateway: sl(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'NoteEnglish - 双语创作书房',
        debugShowCheckedModeBanner: false,
        theme: AppThemeTokens.createThemeData(isDark: false),
        darkTheme: AppThemeTokens.createThemeData(isDark: true),
        themeMode: ThemeMode.system,
        home: const WritingStudioPage(),
      ),
    );
  }
}
