import 'package:equatable/equatable.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';

/// 随笔日记元数据值对象
class DiaryMetadata extends Equatable {
  final DateTime recordedAt;
  final WeatherCondition weather;
  final int wordCount;
  final String? location;

  const DiaryMetadata({
    required this.recordedAt,
    this.weather = WeatherCondition.sunny,
    this.wordCount = 0,
    this.location,
  });

  DiaryMetadata copyWith({
    DateTime? recordedAt,
    WeatherCondition? weather,
    int? wordCount,
    String? location,
  }) {
    return DiaryMetadata(
      recordedAt: recordedAt ?? this.recordedAt,
      weather: weather ?? this.weather,
      wordCount: wordCount ?? this.wordCount,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recordedAt': recordedAt.toIso8601String(),
      'weather': weather.name,
      'wordCount': wordCount,
      'location': location,
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
    );
  }

  @override
  List<Object?> get props => [recordedAt, weather, wordCount, location];
}
