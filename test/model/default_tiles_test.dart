import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/default_tiles.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/services/app_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one small app tile per app, keyed and targeted by package name', () {
    const apps = [
      AppInfo(label: 'Clock', packageName: 'pkg.clock'),
      AppInfo(label: 'Maps', packageName: 'pkg.maps'),
    ];

    final tiles = tilesForApps(apps);

    expect(tiles, hasLength(2));
    expect(tiles[0].id, 'pkg.clock');
    expect(tiles[0].appPackage, 'pkg.clock');
    expect(tiles[0].size, TileSize.small);
    expect(tiles[0].kind, TileKind.app);
    expect(tiles[1].id, 'pkg.maps');
    expect(tiles[1].appPackage, 'pkg.maps');
  });

  test('colours cycle deterministically', () {
    final apps = [
      for (var i = 0; i < 15; i++)
        AppInfo(label: 'App $i', packageName: 'pkg.$i'),
    ];

    final tiles = tilesForApps(apps);

    expect(tiles[0].colour, tiles[12].colour);
    expect(tiles.map((t) => t.colour).toSet().length, greaterThan(1));
  });

  test('never fills with the canvas, bezel, or black/white colours', () {
    final apps = [
      for (var i = 0; i < 20; i++)
        AppInfo(label: 'App $i', packageName: 'pkg.$i'),
    ];

    final colours = tilesForApps(apps).map((t) => t.colour).toSet();

    expect(colours, isNot(contains(C64Colour.blue)));
    expect(colours, isNot(contains(C64Colour.lightBlue)));
    expect(colours, isNot(contains(C64Colour.black)));
    expect(colours, isNot(contains(C64Colour.white)));
  });
}
