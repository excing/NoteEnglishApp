import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/core/theme/app_theme_tokens.dart';
import 'package:note_english_flutter/domain/models/diary/weather_condition.dart';
import 'package:note_english_flutter/presentation/common_widgets/weather_picker_badge.dart';

void main() {
  group('WeatherPickerBadge Widget Tests (TDD)', () {
    testWidgets('renders weather condition and location', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeTokens.createThemeData(isDark: false),
          home: Scaffold(
            body: WeatherPickerBadge(
              currentWeather: WeatherCondition.rainy,
              location: '北京',
              onWeatherChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('下雨'), findsOneWidget);
      expect(find.textContaining('北京'), findsOneWidget);
    });

    testWidgets('selects manual weather from menu', (tester) async {
      WeatherCondition? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeTokens.createThemeData(isDark: false),
          home: Scaffold(
            body: WeatherPickerBadge(
              currentWeather: WeatherCondition.sunny,
              onWeatherChanged: (w) => selected = w,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(WeatherPickerBadge));
      await tester.pumpAndSettle();

      // 验证新增的 阴天 和 雷雨 选项出现在菜单中
      expect(find.text('阴天'), findsOneWidget);
      expect(find.text('雷雨'), findsOneWidget);

      await tester.tap(find.text('雷雨'));
      await tester.pumpAndSettle();

      expect(selected, WeatherCondition.thunderstorm);
    });

    testWidgets('triggers auto fetch weather callback', (tester) async {
      bool autoFetched = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeTokens.createThemeData(isDark: false),
          home: Scaffold(
            body: WeatherPickerBadge(
              currentWeather: WeatherCondition.sunny,
              onWeatherChanged: (_) {},
              onAutoFetchWeather: () => autoFetched = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(WeatherPickerBadge));
      await tester.pumpAndSettle();

      final autoItem = find.textContaining('自动获取实时天气');
      expect(autoItem, findsOneWidget);
      await tester.tap(autoItem);
      await tester.pumpAndSettle();

      expect(autoFetched, isTrue);
    });

    testWidgets('renders micro-climate badge and card with comfort label and night icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeTokens.createThemeData(isDark: false),
          home: Scaffold(
            body: WeatherPickerBadge(
              currentWeather: WeatherCondition.sunny,
              location: '杭州',
              temperature: 20.0,
              apparentTemperature: 19.5,
              humidity: 58,
              isDay: false,
              onWeatherChanged: (_) {},
            ),
          ),
        ),
      );

      // 验证徽标上呈现夜间图标 🌙 以及气温 20°C
      expect(find.textContaining('🌙'), findsOneWidget);
      expect(find.textContaining('20°C'), findsOneWidget);
      expect(find.textContaining('杭州'), findsOneWidget);

      // 打开菜单
      await tester.tap(find.byType(WeatherPickerBadge));
      await tester.pumpAndSettle();

      // 验证菜单中的微气候卡片呈现舒适度标签和湿度
      expect(find.textContaining('舒朗宜人'), findsOneWidget);
      expect(find.textContaining('体感 20°C'), findsOneWidget);
      expect(find.textContaining('湿度 58%'), findsOneWidget);
    });

    testWidgets('renders detailedWeather in badge and microclimate card when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeTokens.createThemeData(isDark: false),
          home: Scaffold(
            body: WeatherPickerBadge(
              currentWeather: WeatherCondition.thunderstorm,
              detailedWeather: '强雷暴伴冰雹',
              location: '广州',
              temperature: 28.0,
              onWeatherChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('强雷暴伴冰雹'), findsOneWidget);
    });

    testWidgets('respects displayMode progressive omissions without font shrinking', (tester) async {
      // 1. noLocation 模式: 省略城市，保留温度和天气
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeTokens.createThemeData(isDark: false),
          home: Scaffold(
            body: WeatherPickerBadge(
              displayMode: WeatherBadgeDisplayMode.noLocation,
              currentWeather: WeatherCondition.sunny,
              location: '大理',
              temperature: 23.0,
              onWeatherChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.textContaining('23°C'), findsOneWidget);
      expect(find.textContaining('大理'), findsNothing);

      // 2. compact 模式: 省略城市和天气名，仅保留温度
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeTokens.createThemeData(isDark: false),
          home: Scaffold(
            body: WeatherPickerBadge(
              displayMode: WeatherBadgeDisplayMode.compact,
              currentWeather: WeatherCondition.sunny,
              location: '大理',
              temperature: 23.0,
              onWeatherChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('23°C'), findsOneWidget);
      expect(find.textContaining('晴天'), findsNothing);
      expect(find.textContaining('大理'), findsNothing);

      // 3. iconOnly 模式: 仅保留图标胶囊
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeTokens.createThemeData(isDark: false),
          home: Scaffold(
            body: WeatherPickerBadge(
              displayMode: WeatherBadgeDisplayMode.iconOnly,
              currentWeather: WeatherCondition.sunny,
              location: '大理',
              temperature: 23.0,
              onWeatherChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.textContaining('☀️'), findsOneWidget);
      expect(find.textContaining('23°C'), findsNothing);
      expect(find.textContaining('晴天'), findsNothing);
      expect(find.textContaining('大理'), findsNothing);
    });

    testWidgets('shows current location in auto fetch weather menu label when location is set', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeTokens.createThemeData(isDark: false),
          home: Scaffold(
            body: WeatherPickerBadge(
              currentWeather: WeatherCondition.sunny,
              location: '深圳',
              onWeatherChanged: (_) {},
              onAutoFetchWeather: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(WeatherPickerBadge));
      await tester.pumpAndSettle();

      expect(find.text('自动获取实时天气 (深圳)'), findsOneWidget);
    });
  });
}
