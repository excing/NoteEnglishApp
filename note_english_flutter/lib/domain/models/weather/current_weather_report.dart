import 'package:equatable/equatable.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/domain/services/wmo_weather_mapper.dart';

/// 实时天气报告领域模型
class CurrentWeatherReport extends Equatable {
  final WeatherCondition condition;
  final double? temperature; // 摄氏度
  final double? apparentTemperature; // 体感温度
  final int? relativeHumidity; // 相对湿度 (0-100%)
  final double? precipitation; // 降水强度 (mm)
  final bool isDay; // 是否为白昼
  final int? weatherCode; // WMO 代码
  final String? detailedDescription; // 细分精准天气 (如 "雷阵雨", "倾盆暴雨")
  final double? windSpeed; // km/h
  final String? locationName; // 地理位置/城市名称
  final double latitude;
  final double longitude;
  final DateTime fetchedAt;

  const CurrentWeatherReport({
    required this.condition,
    this.temperature,
    this.apparentTemperature,
    this.relativeHumidity,
    this.precipitation,
    this.isDay = true,
    this.weatherCode,
    this.detailedDescription,
    this.windSpeed,
    this.locationName,
    required this.latitude,
    required this.longitude,
    required this.fetchedAt,
  });

  /// 获取精准细分天气名称 (若无显式指定则根据 weatherCode 解析)
  String get effectiveDetailedDescription {
    if (detailedDescription != null && detailedDescription!.trim().isNotEmpty) {
      return detailedDescription!;
    }
    if (weatherCode != null) {
      return const WmoWeatherMapper().getDetailedDescription(weatherCode!);
    }
    return condition.label;
  }

  /// 动态昼夜天气图标
  String get dynamicIcon => condition.getIcon(isDay: isDay);

  /// 徽标显示文本 (例如 "24°C 雷阵雨" 或 "雷阵雨")
  String get displayBadgeText {
    final tempStr = temperature != null ? '${temperature!.round()}°C ' : '';
    return '$tempStr$effectiveDetailedDescription';
  }

  /// 文学微气候舒适度标签 (纽约客质感)
  String get comfortLabel {
    final effectiveTemp = apparentTemperature ?? temperature;
    if (effectiveTemp == null) return '舒朗宜人';

    if (effectiveTemp < 0) return '寒冽冰冻';
    if (effectiveTemp <= 10) return '清冷料峭';
    if (effectiveTemp <= 18) return '微凉清爽';
    if (effectiveTemp <= 25) return '舒朗宜人';
    if (effectiveTemp <= 32) {
      if (relativeHumidity != null && relativeHumidity! > 75) {
        return '潮湿闷热';
      }
      return '温热微燥';
    }
    return '酷暑炎热';
  }

  /// 格式化用于 UI 展示的简短字符串 (如 "☀️ 晴朗 · 18°C")
  String get displayDescription {
    final tempStr = temperature != null ? ' · ${temperature!.round()}°C' : '';
    return '$dynamicIcon ${condition.label}$tempStr';
  }

  @override
  List<Object?> get props => [
        condition,
        temperature,
        apparentTemperature,
        relativeHumidity,
        precipitation,
        isDay,
        weatherCode,
        detailedDescription,
        windSpeed,
        locationName,
        latitude,
        longitude,
        fetchedAt,
      ];
}
