import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every 1-4 column by 1-6 row combination exists, once', () {
    final Set<(int, int)> shapes = <(int, int)>{
      for (final TileSize size in TileSize.values) (size.columns, size.rows),
    };

    expect(TileSize.values.length, 24);
    expect(shapes.length, 24, reason: 'no two sizes share a shape');
    for (int columns = 1; columns <= 4; columns++) {
      for (int rows = 1; rows <= 6; rows++) {
        expect(
          shapes.contains((columns, rows)),
          isTrue,
          reason: '$columns x $rows is missing',
        );
      }
    }
  });

  test('the original eight sizes kept their names and shapes', () {
    expect((TileSize.small.columns, TileSize.small.rows), (1, 1));
    expect((TileSize.flat.columns, TileSize.flat.rows), (2, 1));
    expect((TileSize.tall.columns, TileSize.tall.rows), (1, 2));
    expect((TileSize.medium.columns, TileSize.medium.rows), (2, 2));
    expect((TileSize.broad.columns, TileSize.broad.rows), (3, 2));
    expect((TileSize.wide.columns, TileSize.wide.rows), (4, 2));
    expect((TileSize.tower.columns, TileSize.tower.rows), (2, 4));
    expect((TileSize.large.columns, TileSize.large.rows), (4, 4));
  });

  test('only wide and large are full-width hero bands', () {
    for (final TileSize size in TileSize.values) {
      expect(
        size.fullWidth,
        size == TileSize.wide || size == TileSize.large,
        reason: '${size.name}.fullWidth',
      );
    }
  });

  test('a new 4-column size stays 4 wide on a 6-column mosaic', () {
    expect(TileSize.size4x1.spanIn(6), 4);
    expect(TileSize.size4x3.spanIn(6), 4);
  });

  test('a new size no wider than the mosaic keeps its own width', () {
    expect(TileSize.size3x1.spanIn(4), 3);
    expect(TileSize.size1x6.spanIn(4), 1);
  });
}
