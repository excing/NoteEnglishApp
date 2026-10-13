import 'package:flutter/material.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';

/// 天气徽标显示模式（自适应省略显示元素，不缩小字号）
enum WeatherBadgeDisplayMode {
  /// 完整显示: 图标 + 温度 + 天气描述 + 城市 (如 ⛅ 23°C 多云 · 大理)
  full,

  /// 省略城市: 图标 + 温度 + 天气描述 (如 ⛅ 23°C 多云)
  noLocation,

  /// 紧凑模式: 省略城市与天气名，仅显示 图标 + 温度 (如 ⛅ 23°C，若无温度则显示天气名)
  compact,

  /// 极简模式: 仅显示天气图标 (如 ⛅)
  iconOnly,
}

/// 天气切换与实时获取交互徽标
class WeatherPickerBadge extends StatelessWidget {
  final WeatherCondition currentWeather;
  final String? detailedWeather;
  final String? location;
  final double? temperature;
  final double? apparentTemperature;
  final int? humidity;
  final bool? isDay;
  final ValueChanged<WeatherCondition> onWeatherChanged;
  final VoidCallback? onAutoFetchWeather;
  final ValueChanged<String>? onCityWeatherRequested;
  final bool isFetching;
  final bool isCompact;
  final WeatherBadgeDisplayMode displayMode;

  const WeatherPickerBadge({
    super.key,
    required this.currentWeather,
    this.detailedWeather,
    this.location,
    this.temperature,
    this.apparentTemperature,
    this.humidity,
    this.isDay,
    required this.onWeatherChanged,
    this.onAutoFetchWeather,
    this.onCityWeatherRequested,
    this.isFetching = false,
    this.isCompact = false,
    this.displayMode = WeatherBadgeDisplayMode.full,
  });

  WeatherBadgeDisplayMode get effectiveDisplayMode {
    if (displayMode != WeatherBadgeDisplayMode.full) return displayMode;
    if (isCompact) return WeatherBadgeDisplayMode.compact;
    return WeatherBadgeDisplayMode.full;
  }

  String _calcComfortLabel(double? appTemp, double? temp, int? hum) {
    final effective = appTemp ?? temp;
    if (effective == null) return '舒朗宜人';
    if (effective < 0) return '寒冽冰冻';
    if (effective <= 10) return '清冷料峭';
    if (effective <= 18) return '微凉清爽';
    if (effective <= 25) return '舒朗宜人';
    if (effective <= 32) {
      if (hum != null && hum > 75) return '潮湿闷热';
      return '温热微燥';
    }
    return '酷暑炎热';
  }

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
    final displayIcon = currentWeather.getIcon(isDay: isDay ?? true);
    final weatherName = detailedWeather ?? currentWeather.label;
    final tempStr = temperature != null ? '${temperature!.round()}°C ' : '';

    return PopupMenuButton<dynamic>(
      tooltip: '天气设置与微气候信息',
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
        // 0. 微气候概览卡片 (若存在温度数据)
        if (temperature != null) ...[
          PopupMenuItem<dynamic>(
            enabled: false,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tokens.canvas,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.cardBorder, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        location?.isNotEmpty == true ? location! : '当前观测地',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tokens.terracotta.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _calcComfortLabel(
                              apparentTemperature, temperature, humidity),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: tokens.terracotta,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(displayIcon, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text(
                        '${temperature!.round()}°C',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: tokens.textPrimary,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        weatherName,
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (apparentTemperature != null)
                        Text(
                          '体感 ${apparentTemperature!.round()}°C',
                          style: TextStyle(
                            fontSize: 11,
                            color: tokens.textMuted,
                          ),
                        ),
                      if (humidity != null)
                        Text(
                          '湿度 $humidity%',
                          style: TextStyle(
                            fontSize: 11,
                            color: tokens.textMuted,
                          ),
                        ),
                      Text(
                        (isDay ?? true) ? '白昼' : '夜幕',
                        style: TextStyle(
                          fontSize: 11,
                          color: tokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),
        ],

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
                Text(
                  w.getIcon(isDay: isDay ?? true),
                  style: const TextStyle(fontSize: 16),
                ),
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
        padding: EdgeInsets.symmetric(
          horizontal: effectiveDisplayMode == WeatherBadgeDisplayMode.iconOnly
              ? 6
              : (effectiveDisplayMode == WeatherBadgeDisplayMode.compact ? 8 : 10),
          vertical: 4,
        ),
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
              if (effectiveDisplayMode != WeatherBadgeDisplayMode.iconOnly)
                const SizedBox(width: 4),
            ] else ...[
              Text(displayIcon, style: const TextStyle(fontSize: 14)),
              if (effectiveDisplayMode != WeatherBadgeDisplayMode.iconOnly)
                const SizedBox(width: 4),
            ],
            if (effectiveDisplayMode != WeatherBadgeDisplayMode.iconOnly)
              Text(
                effectiveDisplayMode == WeatherBadgeDisplayMode.compact
                    ? (tempStr.isNotEmpty ? tempStr.trim() : weatherName)
                    : '$tempStr$weatherName',
                style: TextStyle(
                  fontSize: 13,
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (effectiveDisplayMode == WeatherBadgeDisplayMode.full &&
                location != null &&
                location!.trim().isNotEmpty) ...[
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
