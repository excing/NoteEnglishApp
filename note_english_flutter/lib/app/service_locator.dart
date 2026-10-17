import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/gateways/weather_gateway.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';
import 'package:note_english_flutter/domain/services/corpus_ingestion_service.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';
import 'package:note_english_flutter/infrastructure/adapters/ai/openai_compatible_ai_gateway.dart';
import 'package:note_english_flutter/infrastructure/adapters/weather/open_meteo_weather_gateway.dart';
import 'package:note_english_flutter/application/quick_polish/quick_polish_cubit.dart';
import 'package:note_english_flutter/domain/gateways/quick_polish_platform_gateway.dart';
import 'package:note_english_flutter/domain/services/quick_polish_service.dart';
import 'package:note_english_flutter/infrastructure/gateways/method_channel_quick_polish_platform_gateway.dart';
import 'package:note_english_flutter/infrastructure/repositories/local_corpus_repository.dart';
import 'package:note_english_flutter/infrastructure/repositories/local_diary_repository.dart';
import 'package:note_english_flutter/infrastructure/repositories/secure_ai_config_repository.dart';
import 'package:note_english_flutter/infrastructure/storage/file_storage_engine.dart';

final sl = GetIt.instance;

/// 初始化全局服务定位容器 (Single Source of Truth for DI)
Future<void> setupServiceLocator({IStorageEngine? customStorageEngine}) async {
  // 0. 底层持久化存储引擎
  final storage = customStorageEngine ?? FileStorageEngine();
  sl.registerLazySingleton<IStorageEngine>(() => storage);

  // 1. 领域服务
  sl.registerLazySingleton<PromptTemplateEngine>(() => const PromptTemplateEngine());
  sl.registerLazySingleton<CorpusIngestionService>(() => const CorpusIngestionService());

  // 2. 基础设施网关与适配器
  sl.registerLazySingleton<IAiGateway>(() => OpenAiCompatibleAiGateway());
  sl.registerLazySingleton<IWeatherGateway>(() => OpenMeteoWeatherGateway());
  sl.registerLazySingleton<IQuickPolishPlatformGateway>(
    () => MethodChannelQuickPolishPlatformGateway(),
  );

  // 3. 持久化仓储层 (全平台文件原子刷盘保障)
  sl.registerLazySingleton<IDiaryRepository>(
    () => LocalDiaryRepository(storageEngine: sl<IStorageEngine>()),
  );
  sl.registerLazySingleton<ICorpusRepository>(
    () => LocalCorpusRepository(storageEngine: sl<IStorageEngine>()),
  );
  sl.registerLazySingleton<IAiConfigRepository>(
    () => SecureAiConfigRepository(
      storageEngine: sl<IStorageEngine>(),
      secureStorage: const FlutterSecureStorage(),
    ),
  );

  // 4. 快捷润色领域服务与 Cubit
  sl.registerLazySingleton<QuickPolishService>(
    () => QuickPolishService(
      aiGateway: sl<IAiGateway>(),
      configRepository: sl<IAiConfigRepository>(),
      corpusRepository: sl<ICorpusRepository>(),
      diaryRepository: sl<IDiaryRepository>(),
      promptTemplateEngine: sl<PromptTemplateEngine>(),
      corpusIngestionService: sl<CorpusIngestionService>(),
    ),
  );
  sl.registerLazySingleton<QuickPolishCubit>(
    () => QuickPolishCubit(
      platformGateway: sl<IQuickPolishPlatformGateway>(),
      quickPolishService: sl<QuickPolishService>(),
    ),
  );
}
