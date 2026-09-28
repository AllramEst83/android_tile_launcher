import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/model/weather_snapshot.dart';
import 'package:android_tile_launcher/services/weather_tile_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_weather_repository.dart';

void main() {
  test('reads what the repository has, without forcing a fetch', () async {
    final repository = FakeWeatherRepository(const WeatherNeedsPlace());
    final source = WeatherTileSource(repository: repository);

    final content = await source.read();

    expect(content, isA<WeatherContent>());
    expect((content as WeatherContent).snapshot, isA<WeatherNeedsPlace>());
    expect(repository.currentCalls, 1);
    expect(repository.forcedCalls, 0);
  });
}
