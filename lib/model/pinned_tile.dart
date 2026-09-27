import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';

/// A pinned app's place on the home mosaic: which app, how big, what colour.
/// The unit `GridState` saves and the grid editor (Phase 6) changes; [toTile]
/// is the read-only view of it that the grid actually renders.
class PinnedTile {
  const PinnedTile({
    required this.packageName,
    required this.size,
    required this.colour,
  });

  /// A freshly-pinned tile's starting size and colour: always small, cycling
  /// through [pinnableColours] by [index] (how many tiles were already
  /// pinned).
  factory PinnedTile.withDefaults({
    required String packageName,
    required int index,
  }) => PinnedTile(
    packageName: packageName,
    size: TileSize.small,
    colour: pinnableColours[index % pinnableColours.length],
  );

  final String packageName;
  final TileSize size;
  final C64Colour colour;

  PinnedTile copyWith({TileSize? size, C64Colour? colour}) => PinnedTile(
    packageName: packageName,
    size: size ?? this.size,
    colour: colour ?? this.colour,
  );

  Tile toTile() => Tile(
    id: packageName,
    size: size,
    colour: colour,
    appPackage: packageName,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'packageName': packageName,
    'size': size.name,
    'colour': colour.name,
  };

  /// `null` for anything malformed — a bad entry is dropped, not fatal.
  static PinnedTile? fromJson(Object? json) {
    if (json is! Map) return null;
    final Object? packageName = json['packageName'];
    final TileSize? size = _sizeByName[json['size']];
    final C64Colour? colour = _colourByName[json['colour']];
    if (packageName is! String || size == null || colour == null) return null;
    return PinnedTile(packageName: packageName, size: size, colour: colour);
  }

  @override
  bool operator ==(Object other) =>
      other is PinnedTile &&
      other.packageName == packageName &&
      other.size == size &&
      other.colour == colour;

  @override
  int get hashCode => Object.hash(packageName, size, colour);

  @override
  String toString() => 'PinnedTile($packageName, $size, $colour)';
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

final Map<String, TileSize> _sizeByName = <String, TileSize>{
  for (final TileSize size in TileSize.values) size.name: size,
};

final Map<String, C64Colour> _colourByName = <String, C64Colour>{
  for (final C64Colour colour in C64Colour.values) colour.name: colour,
};
