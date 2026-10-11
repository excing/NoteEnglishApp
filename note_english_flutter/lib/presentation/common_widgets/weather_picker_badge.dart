import 'package:flutter/material.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';

/// 天气切换交互徽标
class WeatherPickerBadge extends StatelessWidget {
  final WeatherCondition currentWeather;
  final ValueChanged<WeatherCondition> onWeatherChanged;

  const WeatherPickerBadge({
    super.key,
    required this.currentWeather,
    required this.onWeatherChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);

    return PopupMenuButton<WeatherCondition>(
      initialValue: currentWeather,
      onSelected: onWeatherChanged,
      tooltip: '切换天气',
      color: tokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: tokens.cardBorder),
      ),
      itemBuilder: (context) => WeatherCondition.values.map((w) {
        return PopupMenuItem<WeatherCondition>(
          value: w,
          child: Row(
            children: [
              Text(w.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                w.label,
                style: TextStyle(color: tokens.textPrimary, fontSize: 14),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: tokens.highlight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.cardBorder, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currentWeather.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              currentWeather.label,
              style: TextStyle(
                fontSize: 13,
                color: tokens.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
