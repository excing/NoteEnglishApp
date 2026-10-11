import 'package:get_it/get_it.dart';
import 'package:note_english_flutter/domain/gateways/ai_gateway.dart';
import 'package:note_english_flutter/domain/repositories/ai_config_repository.dart';
import 'package:note_english_flutter/domain/repositories/corpus_repository.dart';
import 'package:note_english_flutter/domain/repositories/diary_repository.dart';
import 'package:note_english_flutter/domain/services/corpus_ingestion_service.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';
import 'package:note_english_flutter/infrastructure/adapters/ai/openai_compatible_ai_gateway.dart';
import 'package:note_english_flutter/infrastructure/repositories/local_corpus_repository.dart';
import 'package:note_english_flutter/infrastructure/repositories/local_diary_repository.dart';
import 'package:note_english_flutter/infrastructure/repositories/secure_ai_config_repository.dart';

final sl = GetIt.instance;

/// 初始化全局服务定位容器 (Single Source of Truth for DI)
Future<void> setupServiceLocator() async {
  // 1. 领域服务
  sl.registerLazySingleton<PromptTemplateEngine>(() => const PromptTemplateEngine());
  sl.registerLazySingleton<CorpusIngestionService>(() => const CorpusIngestionService());

  // 2. 基础设施网关与适配器
  sl.registerLazySingleton<IAiGateway>(() => OpenAiCompatibleAiGateway());

  // 3. 仓储层
  sl.registerLazySingleton<IDiaryRepository>(() => LocalDiaryRepository());
  sl.registerLazySingleton<ICorpusRepository>(() => LocalCorpusRepository());
  sl.registerLazySingleton<IAiConfigRepository>(() => SecureAiConfigRepository());
}
