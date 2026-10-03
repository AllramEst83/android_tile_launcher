import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_layout.dart';
import 'package:android_tile_launcher/ui/tile_grid.dart';

/// Where a dropped block of picked tiles ends up: the whole list in packing
/// order, and the pixel box the block covers once packed.
typedef BlockDrop = ({
  List<PinnedTile> order,
  double left,
  double top,
  double width,
  double height,
});

/// The place to drop the picked tiles ([ids]) as one block so that it lands
/// nearest the point ([toLeft], [toTop]), the top-left of the block as the
/// user is holding it, in the pixels of a grid [maxWidth] wide.
///
/// The packer fills gaps in list order, so a block put into the list can
/// split, some of it settling beside one tile and the rest under another.
/// Only places where it lands in one piece, with no other tile inside its
/// footprint, are considered; if there is none, every place is. Pure.
BlockDrop? nearestBlockDrop(
  List<PinnedTile> items,
  Set<String> ids, {
  required double toLeft,
  required double toTop,
  required int columns,
  required double maxWidth,
  required double gap,
}) {
  final List<PinnedTile> block = <PinnedTile>[
    for (final PinnedTile p in items)
      if (ids.contains(p.id)) p,
  ];
  if (block.isEmpty) return null;
  final List<PinnedTile> rest = <PinnedTile>[
    for (final PinnedTile p in items)
      if (!ids.contains(p.id)) p,
  ];

  BlockDrop? bestWhole;
  BlockDrop? bestAny;
  double wholeDistance = double.infinity;
  double anyDistance = double.infinity;
  for (int k = 0; k <= rest.length; k++) {
    final List<PinnedTile> order = <PinnedTile>[
      ...rest.sublist(0, k),
      ...block,
      ...rest.sublist(k),
    ];
    final List<PlacedTile> placed = packTiles(<Tile>[
      for (final PinnedTile p in order) p.toTile(),
    ], columns: columns);
    final List<TileRect> rects = layoutTiles(
      placed,
      maxWidth: maxWidth,
      columns: columns,
      gap: gap,
    );
    double left = double.infinity, top = double.infinity;
    double right = 0, bottom = 0;
    for (final TileRect r in rects) {
      if (!ids.contains(r.tile.id)) continue;
      left = left < r.left ? left : r.left;
      top = top < r.top ? top : r.top;
      right = right > r.left + r.width ? right : r.left + r.width;
      bottom = bottom > r.top + r.height ? bottom : r.top + r.height;
    }
    bool whole = true;
    for (final TileRect r in rects) {
      if (ids.contains(r.tile.id)) continue;
      final bool apartX = r.left + r.width <= left || r.left >= right;
      final bool apartY = r.top + r.height <= top || r.top >= bottom;
      if (!apartX && !apartY) {
        whole = false;
        break;
      }
    }
    final double dx = left - toLeft;
    final double dy = top - toTop;
    final double distance = dx * dx + dy * dy;
    final BlockDrop drop = (
      order: order,
      left: left,
      top: top,
      width: right - left,
      height: bottom - top,
    );
    if (distance < anyDistance) {
      anyDistance = distance;
      bestAny = drop;
    }
    if (whole && distance < wholeDistance) {
      wholeDistance = distance;
      bestWhole = drop;
    }
  }
  return bestWhole ?? bestAny;
}
