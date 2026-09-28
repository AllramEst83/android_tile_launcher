import 'package:android_tile_launcher/model/weather_snapshot.dart';

/// The weather for the weather tile. Both calls never throw: every failure is
/// a [WeatherSnapshot] the tile can word.
abstract interface class WeatherRepository {
  /// The forecast for the saved place. Recent answers are reused, so polling
  /// this is cheap; [force] fetches afresh (a tap on the tile).
  Future<WeatherSnapshot> current({bool force = false});

  /// Finds where the phone is (asking for location permission if needed),
  /// saves that as the place, and returns its forecast. Only ever called from
  /// a tap: a permission dialog must never appear on its own.
  Future<WeatherSnapshot> locate();
}
