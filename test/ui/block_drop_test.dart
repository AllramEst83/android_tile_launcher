import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/ui/block_drop.dart';
import 'package:flutter_test/flutter_test.dart';

PinnedTile _t(String id, TileSize size) =>
    PinnedTile(id: id, size: size, colour: C64Colour.values.first);

List<String> _ids(BlockDrop d) => [for (final p in d.order) p.id];

void main() {
  // A 6-column grid like the phone's: a row of three flat tiles, READY, a
  // SOUND tile, and six tall app tiles.
  final List<PinnedTile> items = [
    _t('a', TileSize.flat),
    _t('b', TileSize.flat),
    _t('c', TileSize.flat),
    _t('ready', TileSize.size3x1),
    _t('sound', TileSize.flat),
    for (int i = 1; i <= 6; i++) _t('t$i', TileSize.size1x3),
  ];
  final Set<String> ids = {for (int i = 1; i <= 6; i++) 't$i'};

  BlockDrop? at(double left, double top) => nearestBlockDrop(
    items,
    ids,
    toLeft: left,
    toTop: top,
    columns: 6,
    maxWidth: 600,
    gap: 0,
  );

  test('held at the very top, the block goes first', () {
    final BlockDrop d = at(0, 0)!;

    expect(_ids(d).take(6), ['t1', 't2', 't3', 't4', 't5', 't6']);
    expect(d.left, 0);
    expect(d.top, 0);
  });

  test('held lower, the block lands lower', () {
    expect(at(0, 100000)!.top, greaterThan(at(0, 0)!.top));
  });

  test('the block is never split, wherever it is held', () {
    for (double y = 0; y < 900; y += 20) {
      final BlockDrop d = at(0, y)!;
      // Whole: it lands as one run in the order, and its box is full width
      // (six one-column tiles).
      expect(d.width, 600, reason: 'y=$y');
      expect(d.height, greaterThan(0));
    }
  });

  test('the landing follows the ghost down the grid', () {
    double previous = -1;
    for (double y = 0; y < 1200; y += 50) {
      final double top = at(0, y)!.top;
      expect(top, greaterThanOrEqualTo(previous));
      previous = top;
    }
  });

  test('nothing picked has nowhere to land', () {
    expect(
      nearestBlockDrop(
        items,
        {},
        toLeft: 0,
        toTop: 0,
        columns: 6,
        maxWidth: 600,
        gap: 0,
      ),
      isNull,
    );
  });
}
