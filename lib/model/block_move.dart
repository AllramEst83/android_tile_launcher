import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_layout.dart';

/// Where the picked tiles ([ids]) end up, in the order the packer reads, when
/// they are dropped as one block beside [target].
///
/// The packer fills gaps in list order, so a block put straight into the list
/// can split: some of it settles in a gap beside one tile and the rest under
/// another. When that happens the block is slid to the nearest place in the
/// list where it lands in one piece, with no other tile inside its footprint.
/// If there is no such place, the plain [moveBlockBeside] order is used.
/// Pure.
List<PinnedTile> moveBlock(
  List<PinnedTile> items, {
  required Set<String> ids,
  required String target,
  required bool after,
  required int columns,
}) {
  final int at = items.indexWhere((PinnedTile p) => p.id == target);
  if (at == -1 || ids.contains(target)) return items;
  final List<PinnedTile> block = <PinnedTile>[
    for (final PinnedTile p in items)
      if (ids.contains(p.id)) p,
  ];
  if (block.isEmpty) return items;
  final List<PinnedTile> rest = <PinnedTile>[
    for (final PinnedTile p in items)
      if (!ids.contains(p.id)) p,
  ];
  final int wanted =
      rest.indexWhere((PinnedTile p) => p.id == target) + (after ? 1 : 0);

  List<PinnedTile> with_(int k) => <PinnedTile>[
    ...rest.sublist(0, k),
    ...block,
    ...rest.sublist(k),
  ];

  final List<int> slots = <int>[for (int k = 0; k <= rest.length; k++) k]
    ..sort((int a, int b) {
      final int byDistance = (a - wanted).abs().compareTo((b - wanted).abs());
      return byDistance != 0 ? byDistance : a.compareTo(b);
    });
  for (final int k in slots) {
    final List<PinnedTile> candidate = with_(k);
    if (blockFootprint(candidate, ids, columns) != null) return candidate;
  }
  return with_(wanted);
}

/// The cells ([column], [row], [columns] wide, [rows] tall) the picked tiles
/// cover in [items] once packed, or null when another tile sits inside that
/// footprint, i.e. the block is not in one piece.
({int column, int row, int columns, int rows})? blockFootprint(
  List<PinnedTile> items,
  Set<String> ids,
  int columns,
) {
  final List<PlacedTile> placed = packTiles(<Tile>[
    for (final PinnedTile p in items) p.toTile(),
  ], columns: columns);
  int left = columns, top = 1 << 30, right = 0, bottom = 0;
  for (final PlacedTile p in placed) {
    if (!ids.contains(p.tile.id)) continue;
    left = left < p.column ? left : p.column;
    top = top < p.row ? top : p.row;
    final int r = p.column + p.span;
    final int b = p.row + p.tile.size.rows;
    right = right > r ? right : r;
    bottom = bottom > b ? bottom : b;
  }
  if (right == 0) return null;
  for (final PlacedTile p in placed) {
    if (ids.contains(p.tile.id)) continue;
    final bool apartX = p.column + p.span <= left || p.column >= right;
    final bool apartY = p.row + p.tile.size.rows <= top || p.row >= bottom;
    if (!apartX && !apartY) return null;
  }
  return (column: left, row: top, columns: right - left, rows: bottom - top);
}
