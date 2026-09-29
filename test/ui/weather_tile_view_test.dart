import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/weather.dart';
import 'package:android_tile_launcher/model/weather_snapshot.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/weather_icon.dart';
import 'package:android_tile_launcher/ui/weather_tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final Forecast _forecast = Forecast(
  place: const Place(name: 'Gothenburg', latitude: 57.7, longitude: 11.97),
  source: 'SMHI',
  now: const Conditions(
    temperature: 12.4,
    feelsLike: 10,
    humidity: 80,
    code: 61,
    windSpeed: 4,
    windDirection: 200,
    precipitation: 0.2,
  ),
  days: [
    for (int i = 0; i < 5; i++)
      DayForecast(
        date: DateTime(2026, 9, 28 + i),
        code: 3,
        low: 5.0 + i,
        high: 12.0 + i,
        precipitation: 0,
      ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  WeatherSnapshot snapshot, {
  Size size = const Size(185, 185),
  VoidCallback? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: WeatherTileContentView(
            snapshot: snapshot,
            ink: Colors.white,
            onTap: onTap,
          ),
        ),
      ),
    ),
  ),
);

void main() {
  group('a forecast', () {
    testWidgets('medium: the temperature, the words, the place, the source', (
      WidgetTester tester,
    ) async {
      await _pump(tester, WeatherReady(_forecast));

      expect(find.text('12°'), findsOneWidget);
      expect(find.text('LIGHT RAIN'), findsOneWidget);
      expect(find.text('GOTHENBURG'), findsOneWidget);
      expect(find.text('SMHI'), findsOneWidget);
      expect(find.byKey(weatherDayKey(0)), findsNothing);
    });

    testWidgets('wide: the days ahead beside the weather now', (
      WidgetTester tester,
    ) async {
      await _pump(tester, WeatherReady(_forecast), size: const Size(380, 185));

      expect(find.byKey(weatherNowKey), findsOneWidget);
      for (int i = 0; i < 5; i++) {
        expect(find.byKey(weatherDayKey(i)), findsOneWidget);
      }
      expect(find.text('MON'), findsOneWidget);
      expect(find.text('FRI'), findsOneWidget);
      expect(find.text('12°'), findsWidgets);
    });

    testWidgets('small: just the sky and the temperature', (
      WidgetTester tester,
    ) async {
      await _pump(tester, WeatherReady(_forecast), size: const Size(90, 90));

      expect(find.text('12°'), findsOneWidget);
      expect(find.text('LIGHT RAIN'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('says when the forecast is out of date', (
      WidgetTester tester,
    ) async {
      await _pump(tester, WeatherReady(_forecast, stale: true));

      expect(find.text('SMHI ${Messages.weatherOld}'), findsOneWidget);
    });

    testWidgets(
      'medium on a short tile: the place and source drop before the tile '
      'overflows, the description never disappears',
      (WidgetTester tester) async {
        // Regression: this block had no height budget at all — the row,
        // the description, the place and the source were always all
        // stacked, so a medium tile shorter than that (a real one, on a
        // phone whose grid gives it less headroom than the square 185x185
        // this group otherwise tests) overflowed at its bottom edge.
        await _pump(tester, WeatherReady(_forecast), size: const Size(200, 80));

        expect(tester.takeException(), isNull);
        expect(find.text('12°'), findsOneWidget);
      },
    );
  });

  group('without a forecast', () {
    testWidgets('no place yet: offers to use the phone\'s location', (
      WidgetTester tester,
    ) async {
      await _pump(tester, const WeatherNeedsPlace());

      expect(find.text(Messages.weatherTapToLocate), findsOneWidget);
    });

    testWidgets('refused but askable: offers to allow it', (
      WidgetTester tester,
    ) async {
      await _pump(tester, const WeatherLocationDenied(permanent: false));

      expect(find.text(Messages.weatherTapToAllow), findsOneWidget);
    });

    testWidgets('refused for good: says where the setting is', (
      WidgetTester tester,
    ) async {
      await _pump(tester, const WeatherLocationDenied(permanent: true));

      expect(find.text(Messages.weatherAllowInSettings), findsOneWidget);
    });

    testWidgets('no position: says why and offers a retry', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const WeatherLocationUnavailable('location is switched off'),
      );

      expect(find.text('LOCATION IS SWITCHED OFF'), findsOneWidget);
      expect(find.text(Messages.weatherTapToRetry), findsOneWidget);
    });

    testWidgets('offline: says so and offers a retry', (
      WidgetTester tester,
    ) async {
      await _pump(tester, const WeatherOffline('no network'));

      expect(find.text(Messages.weatherOffline), findsOneWidget);
      expect(find.text(Messages.weatherTapToRetry), findsOneWidget);
    });
  });

  group('taps', () {
    testWidgets('anywhere on the tile calls onTap', (
      WidgetTester tester,
    ) async {
      var taps = 0;
      await _pump(tester, const WeatherNeedsPlace(), onTap: () => taps++);

      final Rect tile = tester.getRect(find.byType(WeatherTileContentView));
      await tester.tapAt(tile.centerRight - const Offset(5, 0));
      await tester.tapAt(tile.bottomLeft + const Offset(5, -5));

      expect(taps, 2);
    });

    testWidgets('without onTap there is nothing to tap', (
      WidgetTester tester,
    ) async {
      await _pump(tester, const WeatherNeedsPlace());

      expect(find.byType(GestureDetector), findsNothing);
    });
  });

  testWidgets('every kind of sky has a picture', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            for (final WeatherKind kind in WeatherKind.values)
              WeatherIcon(kind: kind, size: 24, color: Colors.white),
          ],
        ),
      ),
    );

    expect(find.byType(WeatherIcon), findsNWidgets(WeatherKind.values.length));
    expect(tester.takeException(), isNull);
  });
}
