// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:note_english_flutter/app/service_locator.dart';
import 'package:note_english_flutter/core/device/app_device_orientation.dart';
import 'package:note_english_flutter/domain/models/diary/diary_entry.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';
import 'package:note_english_flutter/main.dart';

void main() async {
  enableFlutterDriverExtension();
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AppDeviceOrientation.lockPreferredOrientations();
  } catch (_) {}
  try {
    await initializeDateFormatting('zh_CN', null);
  } catch (_) {}

  await setupServiceLocator();

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

