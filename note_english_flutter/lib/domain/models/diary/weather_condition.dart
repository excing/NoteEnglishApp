/// 天气条件枚举 - 单一信源
enum WeatherCondition {
  sunny('晴朗', '☀️'),
  cloudy('多云', '⛅'),
  overcast('阴天', '☁️'),
  rainy('下雨', '🌧️'),
  thunderstorm('雷雨', '⛈️'),
  snowy('下雪', '❄️'),
  windy('有风', '🌬️'),
  foggy('大雾', '🌫️');

  final String label;
  final String icon;

  const WeatherCondition(this.label, this.icon);

  /// 根据昼夜返回对应图标
  String getIcon({bool isDay = true}) {
    if (isDay) return icon;
    switch (this) {
      case WeatherCondition.sunny:
        return '🌙';
      case WeatherCondition.cloudy:
        return '☁️';
      case WeatherCondition.overcast:
        return '☁️';
      default:
        return icon;
    }
  }

  static WeatherCondition fromString(String? value) {
    if (value == null) return WeatherCondition.sunny;
    return WeatherCondition.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.label == value,
      orElse: () => WeatherCondition.sunny,
    );
  }
}
