import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/models/weather/current_weather_report.dart';

void main() {
  group('CurrentWeatherReport Domain Model Tests (TDD)', () {
    test('instantiates with all micro-climate properties', () {
      final now = DateTime(2026, 10, 13, 10, 0);
      final report = CurrentWeatherReport(
        condition: WeatherCondition.sunny,
        temperature: 21.4,
        apparentTemperature: 22.0,
        relativeHumidity: 55,
        precipitation: 0.0,
        isDay: true,
        weatherCode: 0,
        windSpeed: 8.5,
        locationName: '上海',
        latitude: 31.23,
        longitude: 121.47,
        fetchedAt: now,
      );

      expect(report.condition, WeatherCondition.sunny);
      expect(report.temperature, 21.4);
      expect(report.apparentTemperature, 22.0);
      expect(report.relativeHumidity, 55);
      expect(report.precipitation, 0.0);
      expect(report.isDay, isTrue);
      expect(report.dynamicIcon, '☀️');
      expect(report.comfortLabel, '舒朗宜人');
      expect(report.displayBadgeText, '21°C 晴朗无云');
      expect(report.effectiveDetailedDescription, '晴朗无云');
    });

    test('comfort label adapts across temperatures and humidity', () {
      CurrentWeatherReport makeReport(double temp, {int? humidity}) {
        return CurrentWeatherReport(
          condition: WeatherCondition.cloudy,
          temperature: temp,
          relativeHumidity: humidity ?? 50,
          latitude: 0,
          longitude: 0,
          fetchedAt: DateTime.now(),
        );
      }

      expect(makeReport(-3).comfortLabel, '寒冽冰冻');
      expect(makeReport(5).comfortLabel, '清冷料峭');
      expect(makeReport(15).comfortLabel, '微凉清爽');
      expect(makeReport(22).comfortLabel, '舒朗宜人');
      expect(makeReport(28, humidity: 80).comfortLabel, '潮湿闷热');
      expect(makeReport(28, humidity: 40).comfortLabel, '温热微燥');
      expect(makeReport(35).comfortLabel, '酷暑炎热');
    });

    test('night icon is reflected in dynamicIcon', () {
      final nightReport = CurrentWeatherReport(
        condition: WeatherCondition.sunny,
        isDay: false,
        latitude: 0,
        longitude: 0,
        fetchedAt: DateTime.now(),
      );

      expect(nightReport.dynamicIcon, '🌙');
    });

    test('effectiveDetailedDescription derives from weatherCode or explicit description', () {
      final thunderstormReport = CurrentWeatherReport(
        condition: WeatherCondition.thunderstorm,
        weatherCode: 95,
        temperature: 24.0,
        latitude: 0,
        longitude: 0,
        fetchedAt: DateTime.now(),
      );

      expect(thunderstormReport.effectiveDetailedDescription, '雷阵雨');
      expect(thunderstormReport.displayBadgeText, '24°C 雷阵雨');
    });
  });
}
