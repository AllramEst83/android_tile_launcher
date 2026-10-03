import 'package:android_tile_launcher/model/block_move.dart';
import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:flutter_test/flutter_test.dart';

PinnedTile _t(String id, TileSize size) =>
    PinnedTile(id: id, size: size, colour: C64Colour.values.first);

List<String> _ids(List<PinnedTile> tiles) => [for (final p in tiles) p.id];

void main() {
  // A 6-column grid like the phone's: a row of three flat-ish tiles, a wide
  // READY, a SOUND tile, and six tall app tiles.
  final List<PinnedTile> a = [
    _t('a', TileSize.flat),
    _t('b', TileSize.flat),
    _t('c', TileSize.flat),
    _t('ready', TileSize.size3x1),
    _t('sound', TileSize.flat),
  ];
  final List<PinnedTile> six = [
    for (int i = 1; i <= 6; i++) _t('t$i', TileSize.size1x3),
  ];
  final Set<String> ids = {for (final p in six) p.id};

  test('a block that fits where dropped goes exactly there', () {
    final List<PinnedTile> items = [...a, ...six];
    final List<PinnedTile> moved = moveBlock(
      items,
      ids: ids,
      target: 'a',
      after: false,
      columns: 6,
    );

    expect(_ids(moved).take(7), ['t1', 't2', 't3', 't4', 't5', 't6', 'a']);
  });

  test('a block the packer would split is slid to where it stays whole', () {
    final List<PinnedTile> items = [...a, ...six];
    // Before SOUND would drop three tall tiles beside READY and three under
    // it; the nearest whole landing is before READY.
    final List<PinnedTile> moved = moveBlock(
      items,
      ids: ids,
      target: 'sound',
      after: false,
      columns: 6,
    );

    expect(_ids(moved), [
      'a',
      'b',
      'c',
      't1',
      't2',
      't3',
      't4',
      't5',
      't6',
      'ready',
      'sound',
    ]);
    expect(blockFootprint(moved, ids, 6), isNotNull);
  });

  test('a target inside the block changes nothing', () {
    final List<PinnedTile> items = [...a, ...six];
    expect(
      moveBlock(items, ids: ids, target: 't2', after: true, columns: 6),
      same(items),
    );
  });
}
