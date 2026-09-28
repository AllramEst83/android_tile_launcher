import 'package:android_tile_launcher/model/weather_snapshot.dart';
import 'package:android_tile_launcher/services/weather_repository.dart';

/// Answers with [snapshot]; [locate] switches to [afterLocate] (the forecast
/// the phone's position would give) and counts how often each was asked.
class FakeWeatherRepository implements WeatherRepository {
  FakeWeatherRepository([
    this.snapshot = const WeatherNeedsPlace(),
    this.afterLocate,
  ]);

  WeatherSnapshot snapshot;
  WeatherSnapshot? afterLocate;
  int currentCalls = 0;
  int forcedCalls = 0;
  int locateCalls = 0;

  @override
  Future<WeatherSnapshot> current({bool force = false}) async {
    currentCalls++;
    if (force) forcedCalls++;
    return snapshot;
  }

  @override
  Future<WeatherSnapshot> locate() async {
    locateCalls++;
    return snapshot = afterLocate ?? snapshot;
  }
}
