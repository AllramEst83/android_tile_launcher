import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/tile_size.dart';

/// The only tile kind that exists yet. More arrive one phase at a time (clock
/// and device in Phase 7, weather in Phase 8, ...) — see "Adding a tile kind"
/// in .agents/architecture.md.
enum TileKind { app }

/// What a tile is, how big, what colour and what it opens. Placement data
/// only: a live tile's current content comes from a `TileSource` once one
/// exists (Phase 7+); an app tile has none, its label and glyph come straight
/// from the `AppInfo` it names.
class Tile {
  const Tile({
    required this.id,
    required this.size,
    required this.colour,
    required this.appPackage,
    this.kind = TileKind.app,
  });

  final String id;
  final TileKind kind;
  final TileSize size;
  final C64Colour colour;

  /// The app this tile launches. The only kind of target that exists yet.
  final String appPackage;
}
