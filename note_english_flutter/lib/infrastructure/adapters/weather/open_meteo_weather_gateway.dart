import 'package:dio/dio.dart';
import 'package:note_english_flutter/domain/gateways/weather_gateway.dart';
import 'package:note_english_flutter/domain/models/weather/current_weather_report.dart';
import 'package:note_english_flutter/domain/services/wmo_weather_mapper.dart';

/// 基于 Open-Meteo 开放天气服务网关实现 (无需 API Key)
class OpenMeteoWeatherGateway implements IWeatherGateway {
  static const String _forecastBaseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _geocodingBaseUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  // 默认备用基准位置 (北京)
  static const double defaultLatitude = 39.9042;
  static const double defaultLongitude = 116.4074;
  static const String defaultCityName = '北京';

  final Dio _dio;
  final WmoWeatherMapper _mapper;

  OpenMeteoWeatherGateway({
    Dio? dio,
    WmoWeatherMapper mapper = const WmoWeatherMapper(),
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            )),
        _mapper = mapper;

  @override
  Future<CurrentWeatherReport> fetchWeatherByCoordinates({
    required double latitude,
    required double longitude,
    String? locationName,
  }) async {
    try {
      final response = await _dio.get(
        _forecastBaseUrl,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'current':
              'temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,is_day,wind_speed_10m,weather_code',
          'timezone': 'auto',
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Open-Meteo 天气响应格式异常');
      }

      final current = data['current'] as Map<String, dynamic>? ?? {};
      final temp = (current['temperature_2m'] as num?)?.toDouble();
      final apparentTemp =
          (current['apparent_temperature'] as num?)?.toDouble();
      final humidity = (current['relative_humidity_2m'] as num?)?.toInt();
      final precip = (current['precipitation'] as num?)?.toDouble();
      final isDay = (current['is_day'] as num?)?.toInt() != 0;
      final wind = (current['wind_speed_10m'] as num?)?.toDouble();
      final code = (current['weather_code'] as num?)?.toInt() ?? 0;

      final condition = _mapper.mapCodeToCondition(
        weatherCode: code,
        windSpeedKmh: wind,
      );

      return CurrentWeatherReport(
        condition: condition,
        temperature: temp,
        apparentTemperature: apparentTemp,
        relativeHumidity: humidity,
        precipitation: precip,
        isDay: isDay,
        weatherCode: code,
        windSpeed: wind,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        fetchedAt: DateTime.now(),
      );
    } catch (e) {
      if (e is DioException) {
        throw Exception('连接 Open-Meteo 天气服务超时或失败，请检查网络');
      }
      rethrow;
    }
  }

  @override
  Future<CurrentWeatherReport> fetchWeatherByCity(String cityName) async {
    final query = cityName.trim();
    if (query.isEmpty) {
      throw Exception('请输入有效的城市名称');
    }

    try {
      final response = await _dio.get(
        _geocodingBaseUrl,
        queryParameters: {
          'name': query,
          'count': 1,
          'language': 'zh',
          'format': 'json',
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('地理位置解析异常');
      }

      final results = data['results'] as List<dynamic>? ?? [];
      if (results.isEmpty) {
        throw Exception('未能识别城市 "$query" 的经纬度，请核对城市名称');
      }

      final first = results.first as Map<String, dynamic>;
      final lat = (first['latitude'] as num).toDouble();
      final lon = (first['longitude'] as num).toDouble();
      final resolvedName = (first['name'] as String?) ?? query;

      return await fetchWeatherByCoordinates(
        latitude: lat,
        longitude: lon,
        locationName: resolvedName,
      );
    } catch (e) {
      if (e is DioException) {
        throw Exception('城市地理编码解析超时或失败: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<CurrentWeatherReport> fetchWeatherAuto() async {
    // 优先尝试 IP 地理定位快速反查，若因网络限制失败则平滑降级至默认城市
    try {
      final ipRes = await _dio.get(
        'https://freeipapi.com/api/json',
        options: Options(receiveTimeout: const Duration(seconds: 3)),
      );
      if (ipRes.statusCode == 200 && ipRes.data is Map<String, dynamic>) {
        final d = ipRes.data as Map<String, dynamic>;
        final lat = (d['latitude'] as num?)?.toDouble();
        final lon = (d['longitude'] as num?)?.toDouble();
        final city = (d['cityName'] as String?)?.trim();

        if (lat != null && lon != null) {
          return await fetchWeatherByCoordinates(
            latitude: lat,
            longitude: lon,
            locationName: city?.isNotEmpty == true ? city : defaultCityName,
          );
        }
      }
    } catch (_) {
      // 降级使用默认地理位置
    }

    return fetchWeatherByCoordinates(
      latitude: defaultLatitude,
      longitude: defaultLongitude,
      locationName: defaultCityName,
    );
  }
}
