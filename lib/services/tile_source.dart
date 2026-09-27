import 'package:android_tile_launcher/model/tile_content.dart';

/// A live tile's current content, on demand. `read` is called on a timer
/// (`ui/tile_poller.dart`) while the launcher is resumed; `async` because a
/// platform-backed source (`ToggleTileSource`) queries a channel, not because
/// implementations should ever be slow.
abstract interface class TileSource {
  Future<TileContent> read();
}
