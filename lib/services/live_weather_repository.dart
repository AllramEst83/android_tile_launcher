import 'package:android_tile_launcher/model/weather.dart';
import 'package:android_tile_launcher/model/weather_snapshot.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
import 'package:android_tile_launcher/services/location_service.dart';
import 'package:android_tile_launcher/services/network_exception.dart';
import 'package:android_tile_launcher/services/weather.dart';
import 'package:android_tile_launcher/services/weather_repository.dart';

DateTime _systemNow() => DateTime.now();

/// [WeatherRepository] on [Weather] (the forecast, the saved place) and a
/// [LocationService] (where the phone is). Keeps the last forecast in memory
/// for [maxAge], so the tile's poll and every return to the launcher cost
/// nothing, and past that as a stale fallback if the network fails.
class LiveWeatherRepository implements WeatherRepository {
  LiveWeatherRepository({
    required this.weather,
    required this.location,
    this.maxAge = const Duration(minutes: 15),
    this.clock = _systemNow,
  });

  final Weather weather;
  final LocationService location;
  final Duration maxAge;
  final DateTime Function() clock;

  Place? _place;
  Forecast? _forecast;
  DateTime? _fetchedAt;
  Future<WeatherSnapshot>? _locating;

  // Why the last lookup found nothing. Kept because the tile re-reads with
  // `current()` right after a tap, which would otherwise forget it and show
  // "tap to use my location" again as if nothing had happened.
  WeatherSnapshot? _locateFailure;

  @override
  Future<WeatherSnapshot> current({bool force = false}) async {
    final Place? place = _place ??= await weather.home();
    if (place == null) return _locateFailure ?? const WeatherNeedsPlace();

    final Forecast? kept = _forecast;
    final DateTime? at = _fetchedAt;
    if (!force &&
        kept != null &&
        at != null &&
        clock().difference(at) < maxAge) {
      return WeatherReady(kept);
    }
    try {
      final Forecast fresh = await weather.forecast(place);
      _forecast = fresh;
      _fetchedAt = clock();
      return WeatherReady(fresh);
    } on NetworkException catch (error) {
      if (kept != null) return WeatherReady(kept, stale: true);
      return WeatherOffline(error.message);
    }
  }

  // One lookup at a time: a second tap while the permission dialog is up
  // joins the first instead of asking Android again.
  @override
  Future<WeatherSnapshot> locate() =>
      _locating ??= _locate().whenComplete(() => _locating = null);

  Future<WeatherSnapshot> _locate() async {
    final LocationResult found = await location.current();
    switch (found) {
      case LocationDenied(:final bool permanent):
        return _locateFailure = WeatherLocationDenied(permanent: permanent);
      case LocationUnavailable(:final String reason):
        return _locateFailure = WeatherLocationUnavailable(reason);
      case LocationFound():
        final Place place = Place(
          name: found.name ?? 'HERE',
          region: found.region,
          country: found.country,
          latitude: found.latitude,
          longitude: found.longitude,
        );
        // A place that cannot be saved still works for this run.
        try {
          await weather.setHome(place);
        } on LocalStoreException {
          // Ignored: `_place` below keeps it until the launcher restarts.
        }
        _place = place;
        _locateFailure = null;
        _forecast = null;
        _fetchedAt = null;
        return current(force: true);
    }
  }
}
