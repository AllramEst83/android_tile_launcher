import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/alarm_service.dart';
import 'package:android_tile_launcher/services/tile_source.dart';

/// The alarm tile's content: the next alarm due, read from [AlarmService].
class AlarmTileSource implements TileSource {
  const AlarmTileSource({required this.service});

  final AlarmService service;

  @override
  Future<TileContent> read() async => AlarmContent(next: await service.next());
}
