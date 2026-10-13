import 'package:note_english_flutter/domain/models/weather/current_weather_report.dart';

/// 真实天气服务网关接口 (DDD Gateway Interface)
abstract class IWeatherGateway {
  /// 根据经纬度获取当前天气
  Future<CurrentWeatherReport> fetchWeatherByCoordinates({
    required double latitude,
    required double longitude,
    String? locationName,
  });

  /// 根据城市名称搜索并获取当前天气
  Future<CurrentWeatherReport> fetchWeatherByCity(String cityName);

  /// 自动探测（IP 或默认地理位置）获取当前实时天气
  Future<CurrentWeatherReport> fetchWeatherAuto();
}
