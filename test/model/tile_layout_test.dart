import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_layout.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:flutter_test/flutter_test.dart';

Tile _tile(String id, TileSize size) =>
    Tile(id: id, size: size, colour: C64Colour.red);

void main() {
  group('packTiles', () {
    test('uniform small tiles fill a row before wrapping', () {
      final tiles = [for (var i = 0; i < 5; i++) _tile('$i', TileSize.small)];

      final placed = packTiles(tiles);

      expect(placed.map((p) => (p.column, p.row)), [
        (0, 0),
        (1, 0),
        (2, 0),
        (3, 0),
        (0, 1),
      ]);
      expect(totalRows(placed), 2);
    });

    test('a medium tile leaves the skyline uneven for later small tiles', () {
      final tiles = [
        _tile('medium', TileSize.medium),
        _tile('a', TileSize.small),
        _tile('b', TileSize.small),
        _tile('c', TileSize.small),
      ];

      final placed = packTiles(tiles);

      expect(placed.map((p) => (p.column, p.row)), [
        (0, 0), // medium, 2x2
        (2, 0), // a: the shortest gap is column 2/3, not under the medium
        (3, 0), // b
        (2, 1), // c: column 2 is now the shortest again
      ]);
      expect(totalRows(placed), 2);
    });

    test('a wide tile always starts a fresh full-width row', () {
      final tiles = [_tile('a', TileSize.small), _tile('wide', TileSize.wide)];

      final placed = packTiles(tiles);

      expect(placed[0].column, 0);
      expect(placed[0].row, 0);
      expect(placed[1].column, 0);
      expect(placed[1].row, 1); // below the tallest column (the small tile)
      expect(totalRows(placed), 3); // 1 (small's row) + 2 (wide's height)
    });

    test('an empty list packs to zero rows', () {
      expect(totalRows(packTiles(const [])), 0);
    });
  });
}
