import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:note_english_flutter/domain/contracts/ai_contracts.dart';
import 'package:note_english_flutter/domain/errors/ai_failure.dart';
import 'package:note_english_flutter/domain/models/config/ai_profile_config.dart';
import 'package:note_english_flutter/domain/services/prompt_template_engine.dart';
import 'package:note_english_flutter/infrastructure/adapters/ai/openai_compatible_ai_gateway.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late OpenAiCompatibleAiGateway gateway;

  setUp(() {
    mockDio = MockDio();
    gateway = OpenAiCompatibleAiGateway(dio: mockDio);
  });

  group('OpenAiCompatibleAiGateway Tests (TDD)', () {
    const config = AiProfileConfig(
      baseUrl: 'https://api.openai.com/v1',
      apiKey: 'test-api-key',
      selectedModel: 'gpt-4o',
    );

    const promptBundle = PromptBundle(
      systemPrompt: 'System',
      userMessage: 'User',
    );

    test('should fetch models list successfully', () async {
      when(() => mockDio.get(
            'https://api.openai.com/v1/models',
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/models'),
            statusCode: 200,
            data: {
              'data': [
                {'id': 'gpt-4o', 'owned_by': 'openai'},
                {'id': 'gpt-4o-mini', 'owned_by': 'openai'},
              ]
            },
          ));

      final models = await gateway.fetchAvailableModels(config: config);

      expect(models.length, 2);
      expect(models.first.id, 'gpt-4o');
      expect(models.last.id, 'gpt-4o-mini');
    });

    test('should parse diary analysis response accurately', () async {
      final sampleJson = '''
{
  "${AiContracts.keyNonEnglish}": [],
  "${AiContracts.keyIncorrectExpressions}": [],
  "${AiContracts.keyOriginalStyleVersion}": "I worked late today.",
  "${AiContracts.keyUnnaturalExpressions}": [],
  "${AiContracts.keyAuthenticAdvancedVersion}": "Clocked out late today.",
  "${AiContracts.keyExtractedCorpus}": []
}
''';

      when(() => mockDio.post(
            'https://api.openai.com/v1/chat/completions',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/chat/completions'),
            statusCode: 200,
            data: {
              'choices': [
                {
                  'message': {'content': sampleJson}
                }
              ]
            },
          ));

      final result = await gateway.analyzeDiary(
        promptBundle: promptBundle,
        config: config,
      );

      expect(result.originalStyleEnglishVersion, 'I worked late today.');
      expect(result.authenticAdvancedVersion, 'Clocked out late today.');
    });

    test('should throw AiConfigNotSetFailure when apiKey or baseUrl is empty', () async {
      const emptyConfig = AiProfileConfig(baseUrl: '', apiKey: '');
      expect(
        () => gateway.analyzeDiary(promptBundle: promptBundle, config: emptyConfig),
        throwsA(isA<AiConfigNotSetFailure>()),
      );
    });

    test('should throw AiAuthenticationFailure when HTTP status is 401', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/chat/completions'),
        response: Response(
          requestOptions: RequestOptions(path: '/chat/completions'),
          statusCode: 401,
        ),
      ));

      expect(
        () => gateway.analyzeDiary(promptBundle: promptBundle, config: config),
        throwsA(isA<AiAuthenticationFailure>()),
      );
    });

    test('should throw AiNetworkFailure on connection timeout', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/chat/completions'),
        type: DioExceptionType.connectionTimeout,
      ));

      expect(
        () => gateway.analyzeDiary(promptBundle: promptBundle, config: config),
        throwsA(isA<AiNetworkFailure>()),
      );
    });
  });
}
