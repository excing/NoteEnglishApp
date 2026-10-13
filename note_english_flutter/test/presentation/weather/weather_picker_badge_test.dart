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

      await tester.tap(find.text('下雨'));
      await tester.pumpAndSettle();

      expect(selected, WeatherCondition.rainy);
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
  });
}
