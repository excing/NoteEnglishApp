import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/services/wmo_weather_mapper.dart';

void main() {
  group('WmoWeatherMapper Tests (TDD)', () {
    const mapper = WmoWeatherMapper();

    test('maps code 0 to sunny', () {
      expect(mapper.mapCodeToCondition(weatherCode: 0), WeatherCondition.sunny);
    });

    test('maps codes 1, 2 to cloudy and 3 to overcast', () {
      expect(mapper.mapCodeToCondition(weatherCode: 1), WeatherCondition.cloudy);
      expect(mapper.mapCodeToCondition(weatherCode: 2), WeatherCondition.cloudy);
      expect(mapper.mapCodeToCondition(weatherCode: 3), WeatherCondition.overcast);
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
    });

    test('maps thunderstorm codes 95, 96, 99 to thunderstorm', () {
      expect(mapper.mapCodeToCondition(weatherCode: 95), WeatherCondition.thunderstorm);
      expect(mapper.mapCodeToCondition(weatherCode: 96), WeatherCondition.thunderstorm);
      expect(mapper.mapCodeToCondition(weatherCode: 99), WeatherCondition.thunderstorm);
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

    test('returns accurate detailed description across 20+ WMO codes', () {
      expect(mapper.getDetailedDescription(0), '晴朗无云');
      expect(mapper.getDetailedDescription(2), '晴间多云');
      expect(mapper.getDetailedDescription(3), '阴云蔽日');
      expect(mapper.getDetailedDescription(51), '毛毛细雨');
      expect(mapper.getDetailedDescription(61), '小雨');
      expect(mapper.getDetailedDescription(65), '倾盆暴雨');
      expect(mapper.getDetailedDescription(71), '小雪');
      expect(mapper.getDetailedDescription(75), '暴雪');
      expect(mapper.getDetailedDescription(82), '强阵雨');
      expect(mapper.getDetailedDescription(95), '雷阵雨');
      expect(mapper.getDetailedDescription(99), '强雷暴伴冰雹');
      expect(mapper.getDetailedDescription(45), '大雾');
    });
  });
}
