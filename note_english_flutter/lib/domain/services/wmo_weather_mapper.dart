import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';

/// WMO (世界气象组织) 国际通用天气代码映射器
class WmoWeatherMapper {
  const WmoWeatherMapper();

  /// 将 WMO 代码转换为应用内的 WeatherCondition 枚举
  WeatherCondition mapCodeToCondition({
    required int weatherCode,
    double? windSpeedKmh,
  }) {
    // 若风速大于等于 35 km/h (约 5 级清风以上) 且未发生降水，映射为大风/有风
    if (windSpeedKmh != null && windSpeedKmh >= 35.0 && weatherCode <= 3) {
      return WeatherCondition.windy;
    }

    switch (weatherCode) {
      case 0:
        return WeatherCondition.sunny;
      case 1:
      case 2:
      case 3:
        return WeatherCondition.cloudy;
      case 45:
      case 48:
        return WeatherCondition.foggy;
      // 毛毛雨、冻雨、阵雨、雷雨等各类降雨
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
      case 95:
      case 96:
      case 99:
        return WeatherCondition.rainy;
      // 降雪、雪粒与阵雪
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return WeatherCondition.snowy;
      default:
        return WeatherCondition.sunny;
    }
  }
}
