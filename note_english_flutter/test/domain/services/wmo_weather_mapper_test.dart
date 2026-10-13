import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/services/wmo_weather_mapper.dart';

void main() {
  group('WmoWeatherMapper Tests (TDD)', () {
    const mapper = WmoWeatherMapper();

    test('maps code 0 to sunny', () {
      expect(mapper.mapCodeToCondition(weatherCode: 0), WeatherCondition.sunny);
    });

    test('maps codes 1, 2, 3 to cloudy', () {
      expect(mapper.mapCodeToCondition(weatherCode: 1), WeatherCondition.cloudy);
      expect(mapper.mapCodeToCondition(weatherCode: 2), WeatherCondition.cloudy);
      expect(mapper.mapCodeToCondition(weatherCode: 3), WeatherCondition.cloudy);
    });

    test('maps codes 45, 48 to foggy', () {
      expect(mapper.mapCodeToCondition(weatherCode: 45), WeatherCondition.foggy);
      expect(mapper.mapCodeToCondition(weatherCode: 48), WeatherCondition.foggy);
    });

    test('maps rain and drizzle codes to rainy', () {
      expect(mapper.mapCodeToCondition(weatherCode: 51), WeatherCondition.rainy);
      expect(mapper.mapCodeToCondition(weatherCode: 61), WeatherCondition.rainy);
      expect(mapper.mapCodeToCondition(weatherCode: 65), WeatherCondition.rainy);
      expect(mapper.mapCodeToCondition(weatherCode: 80), WeatherCondition.rainy);
      expect(mapper.mapCodeToCondition(weatherCode: 95), WeatherCondition.rainy);
    });

    test('maps snow codes to snowy', () {
      expect(mapper.mapCodeToCondition(weatherCode: 71), WeatherCondition.snowy);
      expect(mapper.mapCodeToCondition(weatherCode: 75), WeatherCondition.snowy);
      expect(mapper.mapCodeToCondition(weatherCode: 85), WeatherCondition.snowy);
    });

    test('maps high wind speed with clear/cloudy sky to windy', () {
      expect(
        mapper.mapCodeToCondition(weatherCode: 1, windSpeedKmh: 42.0),
        WeatherCondition.windy,
      );
    });
  });
}
