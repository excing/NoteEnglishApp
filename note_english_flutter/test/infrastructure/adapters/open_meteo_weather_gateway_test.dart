import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/services/wmo_weather_mapper.dart';
import 'package:note_english_flutter/infrastructure/adapters/weather/open_meteo_weather_gateway.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late OpenMeteoWeatherGateway gateway;

  setUp(() {
    mockDio = MockDio();
    gateway = OpenMeteoWeatherGateway(
      dio: mockDio,
      mapper: const WmoWeatherMapper(),
    );
  });

  group('OpenMeteoWeatherGateway Tests (TDD)', () {
    test('fetches weather by coordinates successfully', () async {
      when(() => mockDio.get(
            'https://api.open-meteo.com/v1/forecast',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: {
              'latitude': 39.9,
              'longitude': 116.4,
              'current': {
                'temperature_2m': 18.5,
                'apparent_temperature': 17.8,
                'relative_humidity_2m': 68,
                'precipitation': 1.2,
                'is_day': 1,
                'wind_speed_10m': 12.0,
                'weather_code': 61,
              },
            },
          ));

      final report = await gateway.fetchWeatherByCoordinates(
        latitude: 39.9,
        longitude: 116.4,
        locationName: '北京',
      );

      expect(report.condition, WeatherCondition.rainy);
      expect(report.temperature, 18.5);
      expect(report.apparentTemperature, 17.8);
      expect(report.relativeHumidity, 68);
      expect(report.precipitation, 1.2);
      expect(report.isDay, isTrue);
      expect(report.weatherCode, 61);
      expect(report.locationName, '北京');
      expect(report.displayDescription, contains('19°C'));
      expect(report.comfortLabel, '微凉清爽');
    });

    test('fetches weather by city name via geocoding', () async {
      when(() => mockDio.get(
            'https://geocoding-api.open-meteo.com/v1/search',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: {
              'results': [
                {
                  'name': 'Shanghai',
                  'latitude': 31.23,
                  'longitude': 121.47,
                }
              ]
            },
          ));

      when(() => mockDio.get(
            'https://api.open-meteo.com/v1/forecast',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: {
              'latitude': 31.23,
              'longitude': 121.47,
              'current': {
                'temperature_2m': 22.0,
                'wind_speed_10m': 8.0,
                'weather_code': 0,
              },
            },
          ));

      final report = await gateway.fetchWeatherByCity('Shanghai');

      expect(report.condition, WeatherCondition.sunny);
      expect(report.temperature, 22.0);
      expect(report.locationName, 'Shanghai');
    });

    test('throws friendly exception when city not found', () async {
      when(() => mockDio.get(
            'https://geocoding-api.open-meteo.com/v1/search',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: {'results': []},
          ));

      expect(
        () => gateway.fetchWeatherByCity('NonExistentCityXYZ'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
