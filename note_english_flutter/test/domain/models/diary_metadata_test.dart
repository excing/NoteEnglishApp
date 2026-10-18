import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/domain/models/diary/diary_metadata.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';

void main() {
  group('DiaryMetadata Domain Model & Serialization Tests (TDD)', () {
    test('serializes and deserializes micro-climate properties correctly', () {
      final recordedAt = DateTime(2026, 10, 13, 10, 30);
      final metadata = DiaryMetadata(
        recordedAt: recordedAt,
        weather: WeatherCondition.cloudy,
        wordCount: 120,
        location: '杭州',
        temperature: 19.5,
        apparentTemperature: 18.8,
        humidity: 65,
        isDay: false,
        detailedWeather: '阴云蔽日',
      );

      final json = metadata.toJson();
      expect(json['temperature'], 19.5);
      expect(json['apparentTemperature'], 18.8);
      expect(json['humidity'], 65);
      expect(json['isDay'], false);
      expect(json['detailedWeather'], '阴云蔽日');

      final deserialized = DiaryMetadata.fromJson(json);
      expect(deserialized.recordedAt, recordedAt);
      expect(deserialized.weather, WeatherCondition.cloudy);
      expect(deserialized.temperature, 19.5);
      expect(deserialized.apparentTemperature, 18.8);
      expect(deserialized.humidity, 65);
      expect(deserialized.isDay, false);
      expect(deserialized.detailedWeather, '阴云蔽日');
      expect(deserialized.weatherIcon, '☁️'); // 夜间多云
    });

    test('backward compatibility: handles legacy json without micro-climate keys', () {
      final legacyJson = {
        'recordedAt': '2026-10-12T08:00:00.000',
        'weather': 'sunny',
        'wordCount': 50,
        'location': '北京',
      };

      final deserialized = DiaryMetadata.fromJson(legacyJson);
      expect(deserialized.weather, WeatherCondition.sunny);
      expect(deserialized.temperature, isNull);
      expect(deserialized.apparentTemperature, isNull);
      expect(deserialized.humidity, isNull);
      expect(deserialized.isDay, isNull);
      expect(deserialized.weatherIcon, '☀️'); // 默认日间
    });

    test('hasRealtimeWeather reflects whether temperature has been obtained', () {
      final withoutWeather = DiaryMetadata(recordedAt: DateTime.now());
      expect(withoutWeather.hasRealtimeWeather, isFalse);

      final withWeather = DiaryMetadata(
        recordedAt: DateTime.now(),
        temperature: 22.0,
      );
      expect(withWeather.hasRealtimeWeather, isTrue);
    });
  });
}
