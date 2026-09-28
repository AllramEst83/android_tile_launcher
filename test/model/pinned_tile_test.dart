import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PinnedTile.app', () {
    test('always starts small, and is a TileKind.app', () {
      final tile = PinnedTile.app(packageName: 'pkg.clock', index: 0);

      expect(tile.size, TileSize.small);
      expect(tile.kind, TileKind.app);
      expect(tile.id, 'pkg.clock');
    });

    test('cycles colours by index', () {
      final first = PinnedTile.app(packageName: 'a', index: 0);
      final wrapped = PinnedTile.app(
        packageName: 'b',
        index: pinnableColours.length,
      );

      expect(first.colour, wrapped.colour);
    });

    test('never uses the canvas, bezel, or black/white colours', () {
      final colours = {
        for (int i = 0; i < pinnableColours.length; i++)
          PinnedTile.app(packageName: '$i', index: i).colour,
      };

      expect(colours, isNot(contains(C64Colour.blue)));
      expect(colours, isNot(contains(C64Colour.lightBlue)));
      expect(colours, isNot(contains(C64Colour.black)));
      expect(colours, isNot(contains(C64Colour.white)));
    });
  });

  group('PinnedTile.system', () {
    test('always starts wide, keyed by the kind\'s own name', () {
      final tile = PinnedTile.system(kind: TileKind.clock, index: 0);

      expect(tile.size, TileSize.wide);
      expect(tile.kind, TileKind.clock);
      expect(tile.id, 'clock');
    });

    test('rejects TileKind.app', () {
      expect(
        () => PinnedTile.system(kind: TileKind.app, index: 0),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('copyWith', () {
    test('changes only what is given', () {
      const tile = PinnedTile(
        id: 'pkg.clock',
        size: TileSize.small,
        colour: C64Colour.red,
      );

      expect(
        tile.copyWith(size: TileSize.wide),
        const PinnedTile(
          id: 'pkg.clock',
          size: TileSize.wide,
          colour: C64Colour.red,
        ),
      );
      expect(
        tile.copyWith(colour: C64Colour.cyan),
        const PinnedTile(
          id: 'pkg.clock',
          size: TileSize.small,
          colour: C64Colour.cyan,
        ),
      );
    });

    test('preserves kind', () {
      const tile = PinnedTile(
        id: 'clock',
        kind: TileKind.clock,
        size: TileSize.wide,
        colour: C64Colour.red,
      );

      expect(tile.copyWith(size: TileSize.large).kind, TileKind.clock);
    });
  });

  group('toTile', () {
    test('carries id, kind, size and colour straight across', () {
      const tile = PinnedTile(
        id: 'pkg.clock',
        size: TileSize.medium,
        colour: C64Colour.green,
      );

      final t = tile.toTile();

      expect(t.id, 'pkg.clock');
      expect(t.kind, TileKind.app);
      expect(t.size, TileSize.medium);
      expect(t.colour, C64Colour.green);
    });
  });

  group('JSON', () {
    test('round-trips through toJson/fromJson', () {
      const tile = PinnedTile(
        id: 'pkg.clock',
        size: TileSize.large,
        colour: C64Colour.purple,
      );

      expect(PinnedTile.fromJson(tile.toJson()), tile);
    });

    test('round-trips a system tile, kind included', () {
      const tile = PinnedTile(
        id: 'clock',
        kind: TileKind.clock,
        size: TileSize.wide,
        colour: C64Colour.orange,
      );

      expect(PinnedTile.fromJson(tile.toJson()), tile);
    });

    test('fromJson rejects anything malformed', () {
      expect(PinnedTile.fromJson(null), isNull);
      expect(PinnedTile.fromJson('not a map'), isNull);
      expect(PinnedTile.fromJson(<String, Object?>{}), isNull);
      expect(
        PinnedTile.fromJson({'id': 'pkg.clock', 'kind': 'app', 'size': 'huge'}),
        isNull,
      );
      expect(
        PinnedTile.fromJson({
          'id': 'pkg.clock',
          'kind': 'app',
          'size': 'small',
          'colour': 'neon',
        }),
        isNull,
      );
      expect(
        PinnedTile.fromJson({
          'id': 'pkg.clock',
          'kind': 'spreadsheet',
          'size': 'small',
          'colour': 'red',
        }),
        isNull,
      );
    });
  });

  group('PinnedTile.contact', () {
    test('starts small, keyed by the person, carrying their name', () {
      final tile = PinnedTile.contact(key: 'k1', name: 'Anna', index: 0);

      expect(tile.size, TileSize.small);
      expect(tile.kind, TileKind.contact);
      expect(tile.id, 'contact:k1');
      expect(tile.label, 'Anna');
      expect(tile.toTile().label, 'Anna');
      expect(contactKeyOf(tile.toTile()), 'k1');
    });

    test('the label round-trips through JSON, and is optional', () {
      final tile = PinnedTile.contact(key: 'k1', name: 'Anna', index: 2);

      expect(PinnedTile.fromJson(tile.toJson()), tile);
      expect(
        PinnedTile.fromJson({
          'id': 'pkg.clock',
          'kind': 'app',
          'size': 'small',
          'colour': 'red',
        })?.label,
        isNull,
      );
      expect(
        PinnedTile.app(packageName: 'a', index: 0).toJson(),
        isNot(contains('label')),
      );
    });

    test('copyWith keeps the label', () {
      final tile = PinnedTile.contact(key: 'k1', name: 'Anna', index: 0);

      expect(tile.copyWith(size: TileSize.wide).label, 'Anna');
    });

    test('only a contact tile has a contact key', () {
      expect(
        contactKeyOf(PinnedTile.app(packageName: 'a', index: 0).toTile()),
        isNull,
      );
    });
  });
}
