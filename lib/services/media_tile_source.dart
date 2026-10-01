import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/media_service.dart';
import 'package:android_tile_launcher/services/tile_source.dart';

/// The Now Playing tile's content: whatever is active right now.
class MediaTileSource implements TileSource {
  const MediaTileSource({required this.service});

  final MediaService service;

  @override
  Future<TileContent> read() async =>
      MediaContent(snapshot: await service.now());
}
