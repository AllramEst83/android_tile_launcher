import 'package:android_tile_launcher/model/weather.dart';

/// What the weather tile has to show right now: a forecast, or the reason
/// there is none. Every failure is a value the tile can word, never an
/// exception.
sealed class WeatherSnapshot {
  const WeatherSnapshot();
}

/// A forecast. [stale] means it is the last good one, kept because the latest
/// attempt to refresh it failed.
class WeatherReady extends WeatherSnapshot {
  const WeatherReady(this.forecast, {this.stale = false});

  final Forecast forecast;
  final bool stale;
}

/// No place is saved yet; a tap on the tile asks for the phone's location.
class WeatherNeedsPlace extends WeatherSnapshot {
  const WeatherNeedsPlace();
}

/// The user said no to location. [permanent] means Android will no longer
/// ask, so the tile can only say where the setting is.
class WeatherLocationDenied extends WeatherSnapshot {
  const WeatherLocationDenied({required this.permanent});

  final bool permanent;
}

/// Permission is fine but there is no position: location is switched off in
/// Android, or no fix arrived in time. [reason] is short and printable.
class WeatherLocationUnavailable extends WeatherSnapshot {
  const WeatherLocationUnavailable(this.reason);

  final String reason;
}

/// A place is saved but no forecast could be had, and none is kept from
/// before. [message] is worded for the user.
class WeatherOffline extends WeatherSnapshot {
  const WeatherOffline(this.message);

  final String message;
}
