import 'dart:async';

import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_layout.dart';
import 'package:android_tile_launcher/services/tile_services.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_grid.dart';
import 'package:android_tile_launcher/ui/tile_view.dart';
import 'package:flutter/material.dart';

/// The grid editor's canvas: hold a tile and drag it to another to move it
/// there, tap one to select it (for the inspector panel below), or delete it.
/// Never launches an app — that only happens outside edit mode.
///
/// While a tile is held over another, a line down that tile's left or right
/// edge shows where it will go: before it if the finger is on its left half,
/// after it if on its right half.
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

  /// [after] is which side of [target] the moved tile goes on.
  final void Function(String moving, String target, bool after) onReorder;

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

  /// Width of the insertion line; it sits in the gutter between two tiles.
  static const double _lineWidth = 6;

  final GlobalKey _gridKey = GlobalKey();
  Timer? _scrollTimer;
  Offset _pointer = Offset.zero;

  /// The size of the tile being held. The ghost is anchored by its middle, so
  /// the finger is that far in from the ghost's top-left corner.
  Size _heldSize = Size.zero;

  /// The tile a held one is over and which side of it the drop would be on,
  /// or null when it is over none.
  ({String id, bool after})? _drop;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    super.dispose();
  }

  void _dragMoved(Offset globalPosition) {
    _pointer = globalPosition;
    _scrollTimer ??= Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _scrollTowardsPointer(),
    );
  }

  void _dragEnded() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _clearDrop();
  }

  /// Whether the finger is on the right half of [r], the tile it is over.
  /// [ghostTopLeft] is where the drag details put the held tile's ghost; the
  /// finger is read from that rather than from the drag's own updates, which
  /// can arrive after the target's.
  bool _onRightHalf(TileRect r, Offset ghostTopLeft) {
    final RenderObject? grid = _gridKey.currentContext?.findRenderObject();
    if (grid is! RenderBox || !grid.attached) return false;
    final Offset finger = ghostTopLeft + _heldSize.center(Offset.zero);
    return grid.globalToLocal(finger).dx > r.left + r.width / 2;
  }

  void _hoverOver(TileRect r, Offset ghostTopLeft) {
    final ({String id, bool after}) next = (
      id: r.tile.id,
      after: _onRightHalf(r, ghostTopLeft),
    );
    if (_drop == next) return;
    setState(() => _drop = next);
  }

  void _clearDrop([String? onlyIfOver]) {
    final ({String id, bool after})? drop = _drop;
    if (drop == null || (onlyIfOver != null && drop.id != onlyIfOver)) return;
    if (mounted) setState(() => _drop = null);
  }

  void _scrollTowardsPointer() {
    if (!mounted) return;
    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    final RenderObject? box = scrollable?.context.findRenderObject();
    if (scrollable == null || box is! RenderBox || !box.attached) return;

    final Rect view = box.localToGlobal(Offset.zero) & box.size;
    double step = 0;
    if (_pointer.dy < view.top + _edge) {
      step = -_maxStep * ((view.top + _edge - _pointer.dy) / _edge).clamp(0, 1);
    } else if (_pointer.dy > view.bottom - _edge) {
      step =
          _maxStep *
          ((_pointer.dy - (view.bottom - _edge)) / _edge).clamp(0, 1);
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
          key: _gridKey,
          height: gridHeight(placed, maxWidth: constraints.maxWidth),
          child: Stack(
            // The line in the outermost gutter sticks out past the grid.
            clipBehavior: Clip.none,
            children: <Widget>[
              for (final TileRect r in rects) _slot(r),
              ?_dropLine(rects),
            ],
          ),
        );
      },
    );
  }

  /// The line down the edge of the tile a held one is over, on the side it
  /// would be dropped on; in the gutter, so it never covers a tile.
  Widget? _dropLine(List<TileRect> rects) {
    final ({String id, bool after})? drop = _drop;
    if (drop == null) return null;
    for (final TileRect r in rects) {
      if (r.tile.id != drop.id) continue;
      final double edge = drop.after
          ? r.left + r.width + TileMetrics.gutter / 2
          : r.left - TileMetrics.gutter / 2;
      return Positioned(
        key: const ValueKey('drop-line'),
        left: edge - _lineWidth / 2,
        top: r.top,
        width: _lineWidth,
        height: r.height,
        child: const IgnorePointer(child: ColoredBox(color: C64.yellow)),
      );
    }
    return null;
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
        onMove: (details) {
          // Every tile under the finger is told about a move, the held one
          // included; only another tile is somewhere to go.
          if (details.data == id) {
            _clearDrop();
          } else {
            _hoverOver(r, details.offset);
          }
        },
        onLeave: (_) => _clearDrop(id),
        onAcceptWithDetails: (details) {
          final bool after = _onRightHalf(r, details.offset);
          _clearDrop();
          widget.onReorder(details.data, id, after);
        },
        builder: (context, candidate, rejected) => LongPressDraggable<String>(
          data: id,
          delay: EditableTileGrid.pickUpDelay,
          onDragStarted: () => _heldSize = Size(r.width, r.height),
          onDragUpdate: (details) => _dragMoved(details.globalPosition),
          onDragEnd: (_) => _dragEnded(),
          // Held by its middle wherever it was grabbed, so the tile it goes
          // beside is the one under the middle of the ghost, which is where
          // the eye puts it, not under the corner it was picked up by.
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
          child: view,
        ),
      ),
    );
  }
}
