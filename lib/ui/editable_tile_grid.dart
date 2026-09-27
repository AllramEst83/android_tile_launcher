import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_layout.dart';
import 'package:android_tile_launcher/services/system_control_service.dart';
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
    required this.systemControl,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
    required this.onReorder,
  });

  final List<PinnedTile> tiles;
  final String Function(String id) labelFor;
  final SystemControlService systemControl;
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
    final Tile tile = r.tile;
    final String id = tile.id;
    final Widget view = TileView(
      colour: tile.colour,
      content: tileContent(
        tile,
        labelFor: (t) => labelFor(t.id),
        systemControl: systemControl,
        interactive: false,
      ),
      selected: id == selected,
      onTap: () => onSelect(id),
      onDelete: () => onDelete(id),
      deleteKey: ValueKey('delete-$id'),
    );

    return Positioned(
      key: ValueKey(id),
      left: r.left,
      top: r.top,
      width: r.width,
      height: r.height,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) => details.data != id,
        onAcceptWithDetails: (details) => onReorder(details.data, id),
        builder: (context, candidate, rejected) => Draggable<String>(
          data: id,
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
