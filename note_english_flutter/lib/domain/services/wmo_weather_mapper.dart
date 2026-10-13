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
        return WeatherCondition.cloudy;
      case 3:
        return WeatherCondition.overcast;
      case 45:
      case 48:
        return WeatherCondition.foggy;
      // 毛毛雨、冻雨、普通降雨、阵雨
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
        return WeatherCondition.rainy;
      // 雷阵雨、强雷暴伴冰雹
      case 95:
      case 96:
      case 99:
        return WeatherCondition.thunderstorm;
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

  /// 获取 WMO 代码对应的精准细分气象描述 (20+ 种状态)
  String getDetailedDescription(int weatherCode) {
    switch (weatherCode) {
      case 0:
        return '晴朗无云';
      case 1:
        return '大致晴朗';
      case 2:
        return '晴间多云';
      case 3:
        return '阴云蔽日';
      case 45:
        return '大雾';
      case 48:
        return '附冰浓雾';
      case 51:
        return '毛毛细雨';
      case 53:
        return '中度细雨';
      case 55:
        return '密实细雨';
      case 56:
      case 57:
        return '冻毛毛雨';
      case 61:
        return '小雨';
      case 63:
        return '中雨';
      case 65:
        return '倾盆暴雨';
      case 66:
      case 67:
        return '冻雨';
      case 71:
        return '小雪';
      case 73:
        return '中雪';
      case 75:
        return '暴雪';
      case 77:
        return '雪霰冰粒';
      case 80:
        return '小阵雨';
      case 81:
        return '阵雨';
      case 82:
        return '强阵雨';
      case 85:
        return '轻度阵雪';
      case 86:
        return '强阵雪';
      case 95:
        return '雷阵雨';
      case 96:
        return '雷雨伴轻雹';
      case 99:
        return '强雷暴伴冰雹';
      default:
        return mapCodeToCondition(weatherCode: weatherCode).label;
    }
  }
}
