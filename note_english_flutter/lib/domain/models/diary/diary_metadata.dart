import 'package:equatable/equatable.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';

/// 随笔日记元数据值对象
class DiaryMetadata extends Equatable {
  final DateTime recordedAt;
  final WeatherCondition weather;
  final int wordCount;
  final String? location;
  final double? temperature;
  final double? apparentTemperature;
  final int? humidity;
  final bool? isDay;
  final String? detailedWeather;

  const DiaryMetadata({
    required this.recordedAt,
    this.weather = WeatherCondition.sunny,
    this.wordCount = 0,
    this.location,
    this.temperature,
    this.apparentTemperature,
    this.humidity,
    this.isDay,
    this.detailedWeather,
  });

  /// 动态昼夜天气图标 (未指定昼夜时默认日间)
  String get weatherIcon => weather.getIcon(isDay: isDay ?? true);

  /// 是否已获取真实实时天气数据 (气温已取得)
  bool get hasRealtimeWeather => temperature != null;

  DiaryMetadata copyWith({
    DateTime? recordedAt,
    WeatherCondition? weather,
    int? wordCount,
    String? location,
    double? temperature,
    double? apparentTemperature,
    int? humidity,
    bool? isDay,
    String? detailedWeather,
  }) {
    return DiaryMetadata(
      recordedAt: recordedAt ?? this.recordedAt,
      weather: weather ?? this.weather,
      wordCount: wordCount ?? this.wordCount,
      location: location ?? this.location,
      temperature: temperature ?? this.temperature,
      apparentTemperature: apparentTemperature ?? this.apparentTemperature,
      humidity: humidity ?? this.humidity,
      isDay: isDay ?? this.isDay,
      detailedWeather: detailedWeather ?? this.detailedWeather,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recordedAt': recordedAt.toIso8601String(),
      'weather': weather.name,
      'wordCount': wordCount,
      'location': location,
      'temperature': temperature,
      'apparentTemperature': apparentTemperature,
      'humidity': humidity,
      'isDay': isDay,
      'detailedWeather': detailedWeather,
    };
  }

  factory DiaryMetadata.fromJson(Map<String, dynamic> json) {
    return DiaryMetadata(
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'] as String)
          : DateTime.now(),
      weather: WeatherCondition.fromString(json['weather'] as String?),
      wordCount: (json['wordCount'] as num?)?.toInt() ?? 0,
      location: json['location'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      apparentTemperature: (json['apparentTemperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toInt(),
      isDay: json['isDay'] as bool?,
      detailedWeather: json['detailedWeather'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        recordedAt,
        weather,
        wordCount,
        location,
        temperature,
        apparentTemperature,
        humidity,
        isDay,
        detailedWeather,
      ];
}
