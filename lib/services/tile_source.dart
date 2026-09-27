import 'package:android_tile_launcher/model/tile_content.dart';

/// A live tile's current content, on demand. Implementations should be cheap
/// — `read` is called on a timer (`ui/tile_poller.dart`) while the launcher
/// is resumed, and must never block the UI thread.
abstract interface class TileSource {
  TileContent read();
}
