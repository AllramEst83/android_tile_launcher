import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/tile_source.dart';
import 'package:android_tile_launcher/services/weather_repository.dart';

/// The weather tile's content: whatever the repository has right now.
class WeatherTileSource implements TileSource {
  const WeatherTileSource({required this.repository});

  final WeatherRepository repository;

  @override
  Future<TileContent> read() async =>
      WeatherContent(snapshot: await repository.current());
}
