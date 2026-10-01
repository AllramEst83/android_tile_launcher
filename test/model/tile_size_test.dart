import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every 1-6 column by 1-6 row combination exists, once', () {
    final Set<(int, int)> shapes = <(int, int)>{
      for (final TileSize size in TileSize.values) (size.columns, size.rows),
    };

    // 36 shapes, plus plain 4x2/4x4 twins of the full-width wide/large.
    expect(TileSize.values.length, 38);
    expect(shapes.length, 36, reason: 'only wide/large share a shape');
    for (int columns = 1; columns <= 6; columns++) {
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

  test('a picked 4-column size never stretches to fill a 6-column mosaic', () {
    expect(TileSize.of(4, 2).spanIn(6), 4);
    expect(TileSize.of(4, 4).spanIn(6), 4);
    expect(TileSize.wide.spanIn(6), 6, reason: 'saved wide tiles unchanged');
  });

  test('a new size no wider than the mosaic keeps its own width', () {
    expect(TileSize.size3x1.spanIn(4), 3);
    expect(TileSize.size1x6.spanIn(4), 1);
  });

  test('a genuine 5 or 6 column size reaches its own width on a 6-column '
      'mosaic, not just by stretching', () {
    expect(TileSize.size5x2.fullWidth, isFalse);
    expect(TileSize.size6x3.fullWidth, isFalse);
    expect(TileSize.size5x2.spanIn(6), 5);
    expect(TileSize.size6x3.spanIn(6), 6);
  });

  test('a 5 or 6 column size clamps to 4 on the default mosaic, like any '
      'tile wider than the mosaic showing it', () {
    expect(TileSize.size5x2.spanIn(4), 4);
    expect(TileSize.size6x3.spanIn(4), 4);
  });

  group('of', () {
    test('finds the size matching any in-range columns x rows', () {
      expect(TileSize.of(1, 1), TileSize.small);
      expect(TileSize.of(4, 2), TileSize.size4x2);
      expect(TileSize.of(4, 4), TileSize.size4x4);
      expect(TileSize.of(3, 5), TileSize.size3x5);
      expect(TileSize.of(5, 3), TileSize.size5x3);
      expect(TileSize.of(6, 6), TileSize.size6x6);
      for (final TileSize size in TileSize.values) {
        if (size.fullWidth) continue;
        expect(TileSize.of(size.columns, size.rows), size);
      }
    });

    test('an out-of-range request falls back to small, not a crash', () {
      expect(TileSize.of(0, 0), TileSize.small);
      expect(TileSize.of(5, 7), TileSize.small);
      expect(TileSize.of(7, 1), TileSize.small);
    });
  });
}
