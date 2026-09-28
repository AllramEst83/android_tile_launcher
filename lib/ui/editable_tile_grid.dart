import 'dart:async';

import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_layout.dart';
import 'package:android_tile_launcher/services/tile_services.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_grid.dart';
import 'package:android_tile_launcher/ui/tile_view.dart';
import 'package:flutter/material.dart';

/// The grid editor's canvas: hold a tile and drag it onto another to put it in
/// that tile's place, tap one to select it (for the inspector panel below), or
/// delete it. Never launches an app — that only happens outside edit mode.
///
/// A tile is picked up by holding it, not by dragging it straight away, so a
/// plain drag still scrolls a grid taller than the screen; and while one is
/// held near the top or bottom edge of the scrolling area, the grid scrolls
/// itself, so every tile can be reached.
class EditableTileGrid extends StatefulWidget {
  const EditableTileGrid({
    super.key,
    required this.tiles,
    required this.labelFor,
    required this.services,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
    required this.onReorder,
  });

  final List<PinnedTile> tiles;
  final String Function(String id) labelFor;
  final TileServices services;
  final String? selected;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onDelete;
  final void Function(String moving, String target) onReorder;

  /// How long a tile is held before it comes off the grid.
  static const Duration pickUpDelay = Duration(milliseconds: 200);

  @override
  State<EditableTileGrid> createState() => _EditableTileGridState();
}

class _EditableTileGridState extends State<EditableTileGrid> {
  /// How close (px) to the top or bottom of the scrolling area a held tile
  /// starts it scrolling; the closer, the faster, up to [_maxStep] per tick.
  static const double _edge = 96;
  static const double _maxStep = 18;

  Timer? _scrollTimer;
  double _pointerY = 0;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    super.dispose();
  }

  void _dragMoved(Offset globalPosition) {
    _pointerY = globalPosition.dy;
    _scrollTimer ??= Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _scrollTowardsPointer(),
    );
  }

  void _dragEnded() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
  }

  void _scrollTowardsPointer() {
    if (!mounted) return;
    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    final RenderObject? box = scrollable?.context.findRenderObject();
    if (scrollable == null || box is! RenderBox || !box.attached) return;

    final Rect view = box.localToGlobal(Offset.zero) & box.size;
    double step = 0;
    if (_pointerY < view.top + _edge) {
      step = -_maxStep * ((view.top + _edge - _pointerY) / _edge).clamp(0, 1);
    } else if (_pointerY > view.bottom - _edge) {
      step =
          _maxStep * ((_pointerY - (view.bottom - _edge)) / _edge).clamp(0, 1);
    }
    if (step == 0) return;

    final ScrollPosition position = scrollable.position;
    final double target = (position.pixels + step).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target != position.pixels) position.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final List<PlacedTile> placed = packTiles([
      for (final PinnedTile p in widget.tiles) p.toTile(),
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
        labelFor: (t) => widget.labelFor(t.id),
        services: widget.services,
        interactive: false,
      ),
      selected: id == widget.selected,
      onTap: () => widget.onSelect(id),
      onDelete: () => widget.onDelete(id),
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
        onAcceptWithDetails: (details) => widget.onReorder(details.data, id),
        builder: (context, candidate, rejected) => LongPressDraggable<String>(
          data: id,
          delay: EditableTileGrid.pickUpDelay,
          onDragUpdate: (details) => _dragMoved(details.globalPosition),
          onDragEnd: (_) => _dragEnded(),
          // Held by its middle wherever it was grabbed, so the tile it lands
          // on is the one under the middle of the ghost, which is where the
          // eye puts it, not under the corner it happened to be picked up by.
          dragAnchorStrategy: (draggable, context, position) =>
              Offset(r.width / 2, r.height / 2),
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
          // The tile a held one is over takes a yellow frame: that is the
          // place the held one will land in if let go now.
          child: candidate.isEmpty
              ? view
              : Container(
                  foregroundDecoration: BoxDecoration(
                    border: Border.all(color: C64.yellow, width: 4),
                  ),
                  child: view,
                ),
        ),
      ),
    );
  }
}
