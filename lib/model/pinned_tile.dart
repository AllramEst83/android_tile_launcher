import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';

/// A pinned tile's place on the home mosaic: which one, how big, what
/// colour. The unit `GridState` saves and the grid editor (Phase 6) changes;
/// [toTile] is the read-only view of it that the grid actually renders.
class PinnedTile {
  const PinnedTile({
    required this.id,
    required this.size,
    required this.colour,
    this.kind = TileKind.app,
    this.label,
  });

  /// A freshly-pinned app tile's starting size and colour: always small,
  /// cycling through [pinnableColours] by [index] (how many tiles were
  /// already pinned).
  factory PinnedTile.app({required String packageName, required int index}) =>
      PinnedTile(
        id: packageName,
        size: TileSize.small,
        colour: pinnableColours[index % pinnableColours.length],
      );

  /// A freshly-pinned contact tile: small, like an app's, carrying the person's
  /// [name] so it can be drawn (and labelled in the editor) without the phone
  /// book. Cycles colour the same way.
  factory PinnedTile.contact({
    required String key,
    required String name,
    required int index,
  }) => PinnedTile(
    id: contactTileId(key),
    kind: TileKind.contact,
    size: TileSize.small,
    colour: pinnableColours[index % pinnableColours.length],
    label: name,
  );

  /// A freshly-pinned system tile (anything but [TileKind.app]): wide, so an
  /// oversized numeral has room, cycling colour the same way an app tile
  /// does.
  factory PinnedTile.system({required TileKind kind, required int index}) {
    assert(kind != TileKind.app, 'use PinnedTile.app for an app tile');
    return PinnedTile(
      id: kind.name,
      kind: kind,
      size: TileSize.wide,
      colour: pinnableColours[index % pinnableColours.length],
    );
  }

  /// A package name for [TileKind.app]; a fixed id (`"clock"`) for a system
  /// kind.
  final String id;
  final TileKind kind;
  final TileSize size;
  final C64Colour colour;

  /// See [Tile.label].
  final String? label;

  PinnedTile copyWith({TileSize? size, C64Colour? colour}) => PinnedTile(
    id: id,
    kind: kind,
    size: size ?? this.size,
    colour: colour ?? this.colour,
    label: label,
  );

  Tile toTile() =>
      Tile(id: id, kind: kind, size: size, colour: colour, label: label);

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'kind': kind.name,
    'size': size.name,
    'colour': colour.name,
    'label': ?label,
  };

  /// `null` for anything malformed — a bad entry is dropped, not fatal.
  static PinnedTile? fromJson(Object? json) {
    if (json is! Map) return null;
    final Object? id = json['id'];
    final TileKind? kind = _kindByName[json['kind']];
    final TileSize? size = _sizeByName[json['size']];
    final C64Colour? colour = _colourByName[json['colour']];
    if (id is! String || kind == null || size == null || colour == null) {
      return null;
    }
    final Object? label = json['label'];
    return PinnedTile(
      id: id,
      kind: kind,
      size: size,
      colour: colour,
      label: label is String ? label : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PinnedTile &&
      other.id == id &&
      other.kind == kind &&
      other.size == size &&
      other.colour == colour &&
      other.label == label;

  @override
  int get hashCode => Object.hash(id, kind, size, colour, label);

  @override
  String toString() => 'PinnedTile($id, $kind, $size, $colour)';
}

/// Colours a tile may use: the sixteen VIC-II colours minus blue and light
/// blue (the canvas and the bezel/text colour — a tile in either would vanish
/// into the chrome) and black/white (too easily mistaken for text or
/// background).
const List<C64Colour> pinnableColours = <C64Colour>[
  C64Colour.red,
  C64Colour.orange,
  C64Colour.yellow,
  C64Colour.green,
  C64Colour.cyan,
  C64Colour.purple,
  C64Colour.brown,
  C64Colour.lightRed,
  C64Colour.lightGreen,
  C64Colour.grey,
  C64Colour.darkGrey,
  C64Colour.lightGrey,
];

final Map<String, TileKind> _kindByName = <String, TileKind>{
  for (final TileKind kind in TileKind.values) kind.name: kind,
};

final Map<String, TileSize> _sizeByName = <String, TileSize>{
  for (final TileSize size in TileSize.values) size.name: size,
};

final Map<String, C64Colour> _colourByName = <String, C64Colour>{
  for (final C64Colour colour in C64Colour.values) colour.name: colour,
};
