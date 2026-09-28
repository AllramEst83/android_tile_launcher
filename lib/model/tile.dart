import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/tile_size.dart';

/// What a tile is. `app` launches [Tile.id] as a package name; a system kind
/// (`clock`, `device`, ...) has no launch target — [Tile.id] is just a
/// fixed identity (`"clock"`) instead. More arrive one phase at a time
/// (mail in Phase 13, ...) — see "Adding a tile
/// kind" in .agents/architecture.md.
enum TileKind {
  app,
  clock,
  device,
  weather,
  agenda,
  contact,
  soundMode,
  flashlight,
}

/// The app package [tile] launches when tapped, or `null` for a tile with no
/// launch target (every kind but [TileKind.app]).
String? launchTargetOf(Tile tile) => tile.kind == TileKind.app ? tile.id : null;

/// A human label for a system kind — "SOUND" for [TileKind.soundMode]
/// — used wherever one is shown (the add-tile sheet, the grid editor's
/// inspector, a toggle tile's own label) instead of formatting [TileKind.name]
/// itself, which reads fine for one word (`CLOCK`) but not several
/// words.
String displayNameOf(TileKind kind) => switch (kind) {
  TileKind.app => '',
  TileKind.clock => 'CLOCK',
  TileKind.device => 'DEVICE',
  TileKind.weather => 'WEATHER',
  TileKind.agenda => 'AGENDA',
  TileKind.contact => 'CONTACT',
  TileKind.soundMode => 'SOUND',
  TileKind.flashlight => 'FLASHLIGHT',
};

/// The id of the tile for the contact with lookup [key]. Unlike a system kind
/// (at most one, so its id is just its name) there is one per person.
String contactTileId(String key) => '$contactIdPrefix$key';

/// The start of every contact tile's id.
const String contactIdPrefix = 'contact:';

/// The contact lookup key a contact tile's id carries, or `null` for any other
/// tile.
String? contactKeyOf(Tile tile) =>
    tile.kind == TileKind.contact && tile.id.startsWith(contactIdPrefix)
    ? tile.id.substring(contactIdPrefix.length)
    : null;

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
    this.label,
  });

  /// A package name for [TileKind.app]; a fixed id (`"clock"`) for a system
  /// kind, since there is at most one of each.
  final String id;
  final TileKind kind;
  final TileSize size;
  final C64Colour colour;

  /// A name the tile carries itself, for a kind whose id is not readable (a
  /// contact's is Android's lookup key). `null` for every other kind.
  final String? label;
}
