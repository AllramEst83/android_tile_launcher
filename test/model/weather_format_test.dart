import 'package:android_tile_launcher/model/weather.dart';
import 'package:android_tile_launcher/model/weather_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDegrees', () {
    test('rounds to whole degrees', () {
      expect(formatDegrees(15.5), '16°');
      expect(formatDegrees(12.4), '12°');
    });

    test('keeps the sign of a cold day', () {
      expect(formatDegrees(-3.2), '-3°');
    });

    test('never shows negative zero', () {
      expect(formatDegrees(-0.4), '0°');
    });
  });

  test('weekdayAbbreviation names the day in capitals', () {
    expect(weekdayAbbreviation(DateTime(2026, 9, 28)), 'MON');
    expect(weekdayAbbreviation(DateTime(2026, 9, 30)), 'WED');
    expect(weekdayAbbreviation(DateTime(2026, 10, 4)), 'SUN');
  });

  group('weatherKind', () {
    test('pictures the common codes', () {
      expect(weatherKind(0), WeatherKind.clear);
      expect(weatherKind(2), WeatherKind.partlyCloudy);
      expect(weatherKind(3), WeatherKind.cloudy);
      expect(weatherKind(45), WeatherKind.fog);
      expect(weatherKind(53), WeatherKind.drizzle);
      expect(weatherKind(63), WeatherKind.rain);
      expect(weatherKind(81), WeatherKind.rain);
      expect(weatherKind(73), WeatherKind.snow);
      expect(weatherKind(68), WeatherKind.snow);
      expect(weatherKind(95), WeatherKind.thunder);
    });

    test('takes a code it does not know for cloud', () {
      expect(weatherKind(1234), WeatherKind.cloudy);
    });
  });

  group('describeWeather', () {
    test('words a code in capitals', () {
      expect(describeWeather(61), 'LIGHT RAIN');
    });

    test('names a code it does not know', () {
      expect(describeWeather(1234), 'WEATHER 1234');
    });
  });
}
