import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/tile_size.dart';

/// What a tile is. `app` launches [Tile.id] as a package name; a system kind
/// (`clock`, `silentMode`, ...) has no launch target — [Tile.id] is just a
/// fixed identity (`"clock"`) instead. More arrive one phase at a time (a
/// device tile in Phase 8, weather in Phase 9, ...) — see "Adding a tile
/// kind" in .agents/architecture.md.
enum TileKind { app, clock, silentMode, vibrationMode, flashlight }

/// The app package [tile] launches when tapped, or `null` for a tile with no
/// launch target (every kind but [TileKind.app]).
String? launchTargetOf(Tile tile) => tile.kind == TileKind.app ? tile.id : null;

/// A human label for a system kind — "SILENT MODE" for [TileKind.silentMode]
/// — used wherever one is shown (the add-tile sheet, the grid editor's
/// inspector, a toggle tile's own label) instead of formatting [TileKind.name]
/// itself, which reads fine for one word (`CLOCK`) but not two
/// (`SILENTMODE`).
String displayNameOf(TileKind kind) => switch (kind) {
  TileKind.app => '',
  TileKind.clock => 'CLOCK',
  TileKind.silentMode => 'SILENT MODE',
  TileKind.vibrationMode => 'VIBRATION MODE',
  TileKind.flashlight => 'FLASHLIGHT',
};

/// The kind named [id] (a system tile's id is always its kind's own name), or
/// `null` — an app tile's id is a package name and never matches one.
TileKind? tileKindNamed(String id) {
  for (final TileKind kind in TileKind.values) {
    if (kind.name == id) return kind;
  }
  return null;
}

/// What a tile is, how big, what colour and what it opens (if anything).
/// Placement data only: a live tile's current content comes from a
/// `TileSource` (Phase 7+); an app tile has none, its label and glyph come
/// straight from the `AppInfo` it names.
class Tile {
  const Tile({
    required this.id,
    required this.size,
    required this.colour,
    this.kind = TileKind.app,
  });

  /// A package name for [TileKind.app]; a fixed id (`"clock"`) for a system
  /// kind, since there is at most one of each.
  final String id;
  final TileKind kind;
  final TileSize size;
  final C64Colour colour;
}
