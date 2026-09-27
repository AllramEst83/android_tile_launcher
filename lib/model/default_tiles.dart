import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/services/app_info.dart';

/// A starting layout before there is anywhere to save one (Phase 5) or edit
/// one (Phase 6): every app as a small tile, in listing order, cycling
/// through a fixed set of VIC-II colours. Blue and light blue are skipped —
/// they are the canvas and the bezel/text colour, so a tile in either would
/// vanish into the chrome; black and white are skipped for the same reason
/// in reverse (too easily mistaken for text or background).
List<Tile> tilesForApps(List<AppInfo> apps) => <Tile>[
  for (final (int index, AppInfo app) in apps.indexed)
    Tile(
      id: app.packageName,
      size: TileSize.small,
      colour: _fillCycle[index % _fillCycle.length],
      appPackage: app.packageName,
    ),
];

const List<C64Colour> _fillCycle = <C64Colour>[
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
