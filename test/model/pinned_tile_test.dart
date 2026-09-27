import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PinnedTile.withDefaults', () {
    test('always starts small', () {
      final tile = PinnedTile.withDefaults(packageName: 'pkg.clock', index: 0);

      expect(tile.size, TileSize.small);
    });

    test('cycles colours by index', () {
      final first = PinnedTile.withDefaults(packageName: 'a', index: 0);
      final wrapped = PinnedTile.withDefaults(
        packageName: 'b',
        index: pinnableColours.length,
      );

      expect(first.colour, wrapped.colour);
    });

    test('never uses the canvas, bezel, or black/white colours', () {
      final colours = {
        for (int i = 0; i < pinnableColours.length; i++)
          PinnedTile.withDefaults(packageName: '$i', index: i).colour,
      };

      expect(colours, isNot(contains(C64Colour.blue)));
      expect(colours, isNot(contains(C64Colour.lightBlue)));
      expect(colours, isNot(contains(C64Colour.black)));
      expect(colours, isNot(contains(C64Colour.white)));
    });
  });

  group('copyWith', () {
    test('changes only what is given', () {
      const tile = PinnedTile(
        packageName: 'pkg.clock',
        size: TileSize.small,
        colour: C64Colour.red,
      );

      expect(
        tile.copyWith(size: TileSize.wide),
        const PinnedTile(
          packageName: 'pkg.clock',
          size: TileSize.wide,
          colour: C64Colour.red,
        ),
      );
      expect(
        tile.copyWith(colour: C64Colour.cyan),
        const PinnedTile(
          packageName: 'pkg.clock',
          size: TileSize.small,
          colour: C64Colour.cyan,
        ),
      );
    });
  });

  group('toTile', () {
    test('targets its own package, by the same id', () {
      const tile = PinnedTile(
        packageName: 'pkg.clock',
        size: TileSize.medium,
        colour: C64Colour.green,
      );

      final t = tile.toTile();

      expect(t.id, 'pkg.clock');
      expect(t.appPackage, 'pkg.clock');
      expect(t.size, TileSize.medium);
      expect(t.colour, C64Colour.green);
    });
  });

  group('JSON', () {
    test('round-trips through toJson/fromJson', () {
      const tile = PinnedTile(
        packageName: 'pkg.clock',
        size: TileSize.large,
        colour: C64Colour.purple,
      );

      expect(PinnedTile.fromJson(tile.toJson()), tile);
    });

    test('fromJson rejects anything malformed', () {
      expect(PinnedTile.fromJson(null), isNull);
      expect(PinnedTile.fromJson('not a map'), isNull);
      expect(PinnedTile.fromJson(<String, Object?>{}), isNull);
      expect(
        PinnedTile.fromJson({'packageName': 'pkg.clock', 'size': 'huge'}),
        isNull,
      );
      expect(
        PinnedTile.fromJson({
          'packageName': 'pkg.clock',
          'size': 'small',
          'colour': 'neon',
        }),
        isNull,
      );
    });
  });
}
