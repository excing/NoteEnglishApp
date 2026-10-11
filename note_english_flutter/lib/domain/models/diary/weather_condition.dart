/// 天气条件枚举 - 单一信源
enum WeatherCondition {
  sunny('晴朗', '☀️'),
  cloudy('多云', '⛅'),
  rainy('下雨', '🌧️'),
  snowy('下雪', '❄️'),
  windy('有风', '🌬️'),
  foggy('大雾', '🌫️');

  final String label;
  final String icon;

  const WeatherCondition(this.label, this.icon);

  static WeatherCondition fromString(String? value) {
    if (value == null) return WeatherCondition.sunny;
    return WeatherCondition.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.label == value,
      orElse: () => WeatherCondition.sunny,
    );
  }
}
