import 'package:equatable/equatable.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';

/// 实时天气报告领域模型
class CurrentWeatherReport extends Equatable {
  final WeatherCondition condition;
  final double? temperature; // 摄氏度
  final int? weatherCode; // WMO 代码
  final double? windSpeed; // km/h
  final String? locationName; // 地理位置/城市名称
  final double latitude;
  final double longitude;
  final DateTime fetchedAt;

  const CurrentWeatherReport({
    required this.condition,
    this.temperature,
    this.weatherCode,
    this.windSpeed,
    this.locationName,
    required this.latitude,
    required this.longitude,
    required this.fetchedAt,
  });

  /// 格式化用于 UI 展示的简短字符串 (如 "18°C 晴朗" 或 "🌧️ 下雨 · 16°C")
  String get displayDescription {
    final tempStr = temperature != null ? ' · ${temperature!.round()}°C' : '';
    return '${condition.icon} ${condition.label}$tempStr';
  }

  @override
  List<Object?> get props => [
        condition,
        temperature,
        weatherCode,
        windSpeed,
        locationName,
        latitude,
        longitude,
        fetchedAt,
      ];
}
