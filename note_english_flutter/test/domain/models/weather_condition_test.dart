import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';

void main() {
  group('WeatherCondition Domain Tests (TDD)', () {
    test('provides day and night icons correctly', () {
      expect(WeatherCondition.sunny.getIcon(isDay: true), '☀️');
      expect(WeatherCondition.sunny.getIcon(isDay: false), '🌙');

      expect(WeatherCondition.cloudy.getIcon(isDay: true), '⛅');
      expect(WeatherCondition.cloudy.getIcon(isDay: false), '☁️');

      expect(WeatherCondition.overcast.getIcon(isDay: true), '☁️');
      expect(WeatherCondition.overcast.getIcon(isDay: false), '☁️');

      expect(WeatherCondition.rainy.getIcon(isDay: true), '🌧️');
      expect(WeatherCondition.rainy.getIcon(isDay: false), '🌧️');

      expect(WeatherCondition.thunderstorm.getIcon(isDay: true), '⛈️');
      expect(WeatherCondition.thunderstorm.getIcon(isDay: false), '⛈️');

      expect(WeatherCondition.snowy.getIcon(isDay: true), '❄️');
      expect(WeatherCondition.windy.getIcon(isDay: true), '🌬️');
      expect(WeatherCondition.foggy.getIcon(isDay: true), '🌫️');
    });

    test('verifies 8 primary mood categories are present', () {
      expect(WeatherCondition.values.length, 8);
      expect(WeatherCondition.overcast.label, '阴天');
      expect(WeatherCondition.thunderstorm.label, '雷雨');
    });

    test('default icon remains day icon for backwards compatibility', () {
      expect(WeatherCondition.sunny.icon, '☀️');
      expect(WeatherCondition.cloudy.icon, '⛅');
      expect(WeatherCondition.overcast.icon, '☁️');
      expect(WeatherCondition.thunderstorm.icon, '⛈️');
    });

    test('fromString parses correctly or falls back to sunny', () {
      expect(WeatherCondition.fromString('rainy'), WeatherCondition.rainy);
      expect(WeatherCondition.fromString('下雨'), WeatherCondition.rainy);
      expect(WeatherCondition.fromString('overcast'), WeatherCondition.overcast);
      expect(WeatherCondition.fromString('阴天'), WeatherCondition.overcast);
      expect(WeatherCondition.fromString('thunderstorm'), WeatherCondition.thunderstorm);
      expect(WeatherCondition.fromString('雷雨'), WeatherCondition.thunderstorm);
      expect(WeatherCondition.fromString('unknown_val'), WeatherCondition.sunny);
      expect(WeatherCondition.fromString(null), WeatherCondition.sunny);
    });
  });
}
