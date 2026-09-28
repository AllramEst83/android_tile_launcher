import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/weather.dart';
import 'package:android_tile_launcher/model/weather_format.dart';
import 'package:android_tile_launcher/model/weather_snapshot.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/weather_icon.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key weatherNowKey = ValueKey<String>('weather-now');
Key weatherDayKey(int index) => ValueKey<String>('weather-day-$index');

/// The weather tile's content, fitted to whatever size the tile was given: a
/// small tile shows the sky and the temperature; a medium one adds the words
/// and the place; a wide (or larger) one puts the days ahead beside them. With
/// no forecast it says why, and a tap ([onTap]) is how the user fixes it
/// (allows location) or retries. `null` in the grid editor, where a tap
/// selects the tile instead.
class WeatherTileContentView extends StatelessWidget {
  const WeatherTileContentView({
    super.key,
    required this.snapshot,
    required this.ink,
    this.onTap,
  });

  final WeatherSnapshot snapshot;
  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget body = SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.gutter / 2),
        child: LayoutBuilder(
          builder: (context, constraints) => switch (snapshot) {
            WeatherReady(:final Forecast forecast, :final bool stale) =>
              _ForecastView(
                forecast: forecast,
                stale: stale,
                ink: ink,
                width: constraints.maxWidth,
              ),
            _ => _MessageView(lines: _messageFor(snapshot), ink: ink),
          },
        ),
      ),
    );
    final VoidCallback? tap = onTap;
    if (tap == null) return body;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tap,
      child: body,
    );
  }
}

List<String> _messageFor(WeatherSnapshot snapshot) => switch (snapshot) {
  WeatherNeedsPlace() => const <String>[Messages.weatherTapToLocate],
  WeatherLocationDenied(permanent: true) => const <String>[
    Messages.weatherAllowInSettings,
  ],
  WeatherLocationDenied() => const <String>[Messages.weatherTapToAllow],
  WeatherLocationUnavailable(:final String reason) => <String>[
    reason.toUpperCase(),
    Messages.weatherTapToRetry,
  ],
  WeatherOffline() => const <String>[
    Messages.weatherOffline,
    Messages.weatherTapToRetry,
  ],
  WeatherReady() => const <String>[],
};

TextStyle _text(Color ink, double size) =>
    TextStyle(fontFamily: kPixelFontFamily, fontSize: size, color: ink);

class _MessageView extends StatelessWidget {
  const _MessageView({required this.lines, required this.ink});

  final List<String> lines;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(Messages.weatherTitle, style: _text(ink, 10)),
        const SizedBox(height: 6),
        for (final String line in lines)
          Text(line, style: _text(ink, 8), softWrap: true),
      ],
    );
  }
}

class _ForecastView extends StatelessWidget {
  const _ForecastView({
    required this.forecast,
    required this.stale,
    required this.ink,
    required this.width,
  });

  final Forecast forecast;
  final bool stale;
  final Color ink;
  final double width;

  static const double _compact = 120;
  static const double _wide = 260;

  @override
  Widget build(BuildContext context) {
    final Conditions now = forecast.now;
    final WeatherKind kind = weatherKind(now.code);
    if (width < _compact) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Flexible(
            child: WeatherIcon(kind: kind, size: 40, color: ink),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(formatDegrees(now.temperature), style: _text(ink, 14)),
          ),
        ],
      );
    }

    final Widget current = Column(
      key: weatherNowKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          children: <Widget>[
            WeatherIcon(kind: kind, size: 36, color: ink),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatDegrees(now.temperature),
                  style: _text(ink, 24),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          describeWeather(now.code),
          style: _text(ink, 8),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          forecast.place.name.toUpperCase(),
          style: _text(ink, 8),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          stale
              ? '${forecast.source.toUpperCase()} ${Messages.weatherOld}'
              : forecast.source.toUpperCase(),
          style: _text(ink, 8),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    if (width < _wide) return current;
    return Row(
      children: <Widget>[
        Expanded(flex: 4, child: current),
        const SizedBox(width: 8),
        Expanded(
          flex: 7,
          child: Row(
            children: <Widget>[
              for (final (int i, DayForecast day)
                  in forecast.days.take(5).indexed)
                Expanded(
                  child: _DayColumn(key: weatherDayKey(i), day: day, ink: ink),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({super.key, required this.day, required this.ink});

  final DayForecast day;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(weekdayAbbreviation(day.date), style: _text(ink, 8)),
        ),
        const SizedBox(height: 4),
        WeatherIcon(kind: weatherKind(day.code), size: 22, color: ink),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(formatDegrees(day.high), style: _text(ink, 8)),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(formatDegrees(day.low), style: _text(ink, 8)),
        ),
      ],
    );
  }
}
