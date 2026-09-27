import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/tile_layout.dart';
import 'package:android_tile_launcher/ui/tile_grid.dart';
import 'package:android_tile_launcher/ui/tile_view.dart';
import 'package:flutter/material.dart';

/// The grid editor's canvas: drag a tile onto another to reorder, tap one to
/// select it (for the inspector panel below), or delete it. Never launches an
/// app — that only happens outside edit mode.
class EditableTileGrid extends StatelessWidget {
  const EditableTileGrid({
    super.key,
    required this.tiles,
    required this.labelFor,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
    required this.onReorder,
  });

  final List<PinnedTile> tiles;
  final String Function(String packageName) labelFor;
  final String? selected;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onDelete;
  final void Function(String moving, String target) onReorder;

  @override
  Widget build(BuildContext context) {
    final List<PlacedTile> placed = packTiles([
      for (final PinnedTile p in tiles) p.toTile(),
    ]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final List<TileRect> rects = layoutTiles(
          placed,
          maxWidth: constraints.maxWidth,
        );
        return SizedBox(
          height: gridHeight(placed, maxWidth: constraints.maxWidth),
          child: Stack(
            children: <Widget>[for (final TileRect r in rects) _slot(r)],
          ),
        );
      },
    );
  }

  Widget _slot(TileRect r) {
    final String packageName = r.tile.appPackage;
    final Widget view = TileView(
      tile: r.tile,
      label: labelFor(packageName),
      selected: packageName == selected,
      onTap: () => onSelect(packageName),
      onDelete: () => onDelete(packageName),
    );

    return Positioned(
      key: ValueKey(r.tile.id),
      left: r.left,
      top: r.top,
      width: r.width,
      height: r.height,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) => details.data != packageName,
        onAcceptWithDetails: (details) => onReorder(details.data, packageName),
        builder: (context, candidate, rejected) => Draggable<String>(
          data: packageName,
          // The feedback widget renders in the root Overlay, outside this
          // tree's Material ancestor -- TileView's InkWell needs its own.
          feedback: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              width: r.width,
              height: r.height,
              child: Opacity(opacity: 0.75, child: view),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: view),
          child: view,
        ),
      ),
    );
  }
}
