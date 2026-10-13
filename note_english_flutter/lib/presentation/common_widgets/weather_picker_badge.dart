import 'package:flutter/material.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';

/// 天气切换与实时获取交互徽标
class WeatherPickerBadge extends StatelessWidget {
  final WeatherCondition currentWeather;
  final String? location;
  final ValueChanged<WeatherCondition> onWeatherChanged;
  final VoidCallback? onAutoFetchWeather;
  final ValueChanged<String>? onCityWeatherRequested;
  final bool isFetching;

  const WeatherPickerBadge({
    super.key,
    required this.currentWeather,
    this.location,
    required this.onWeatherChanged,
    this.onAutoFetchWeather,
    this.onCityWeatherRequested,
    this.isFetching = false,
  });

  void _showCityInputDialog(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final ctrl = TextEditingController(text: location ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_city, color: tokens.terracotta, size: 22),
            const SizedBox(width: 8),
            Text(
              '按城市获取实时天气',
              style: TextStyle(
                color: tokens.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '输入城市名称（支持中文或英文，如：北京、上海、Tokyo、London），通过 Open-Meteo 免 Key 实时拉取：',
              style: TextStyle(color: tokens.textMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: TextStyle(color: tokens.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: '例如: 上海 / New York',
                hintStyle: TextStyle(
                  color: tokens.textMuted.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: tokens.canvas,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: tokens.cardBorder),
                ),
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  Navigator.of(ctx).pop();
                  onCityWeatherRequested?.call(text.trim());
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('取消', style: TextStyle(color: tokens.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.terracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(ctx).pop();
                onCityWeatherRequested?.call(text);
              }
            },
            child: const Text('获取天气'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);

    return PopupMenuButton<dynamic>(
      tooltip: '天气设置与实时获取',
      color: tokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: tokens.cardBorder),
      ),
      onSelected: (value) {
        if (value is WeatherCondition) {
          onWeatherChanged(value);
        } else if (value == 'auto_fetch') {
          onAutoFetchWeather?.call();
        } else if (value == 'by_city') {
          _showCityInputDialog(context);
        }
      },
      itemBuilder: (context) => [
        // 1. 自动实时获取选项
        if (onAutoFetchWeather != null)
          PopupMenuItem<dynamic>(
            value: 'auto_fetch',
            child: Row(
              children: [
                Icon(Icons.cloud_sync_outlined,
                    size: 18, color: tokens.terracotta),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '自动获取实时天气 (Open-Meteo)',
                    style: TextStyle(
                      color: tokens.terracotta,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (onCityWeatherRequested != null)
          PopupMenuItem<dynamic>(
            value: 'by_city',
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: tokens.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '按城市搜索天气...',
                    style: TextStyle(color: tokens.textPrimary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        if (onAutoFetchWeather != null || onCityWeatherRequested != null)
          const PopupMenuDivider(),

        // 2. 预设手动天气条件
        ...WeatherCondition.values.map((w) {
          final isSelected = w == currentWeather;
          return PopupMenuItem<dynamic>(
            value: w,
            child: Row(
              children: [
                Text(w.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    w.label,
                    style: TextStyle(
                      color: isSelected ? tokens.terracotta : tokens.textPrimary,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, size: 16, color: tokens.terracotta),
              ],
            ),
          );
        }),
      ],
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
            if (isFetching) ...[
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: tokens.terracotta,
                ),
              ),
              const SizedBox(width: 6),
            ] else ...[
              Text(currentWeather.icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
            ],
            Text(
              currentWeather.label,
              style: TextStyle(
                fontSize: 13,
                color: tokens.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (location != null && location!.trim().isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                '· ${location!}',
                style: TextStyle(
                  fontSize: 12,
                  color: tokens.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
