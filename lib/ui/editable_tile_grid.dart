import 'dart:async';

import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_layout.dart';
import 'package:android_tile_launcher/services/tile_services.dart';
import 'package:android_tile_launcher/ui/block_drop.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_grid.dart';
import 'package:android_tile_launcher/ui/tile_view.dart';
import 'package:flutter/material.dart';

/// The grid editor's canvas: hold a tile and drag it to another to move it
/// there, tap one to select it (for the inspector panel below), or delete it.
/// Never launches an app — that only happens outside edit mode.
///
/// While a tile is held over another, a line along that tile's near edge
/// shows where it will go: the tile it is over is split by its two
/// diagonals into four triangles, and whichever one the finger is in — left,
/// right, top or bottom — decides the edge, so a tile can be dropped beside
/// its target (reordered) or above/below it (stacked into another row) by
/// the same gesture. Each tile's drop area also reaches a little past its
/// own edges, into the gutter around it, so the marker appears as soon as a
/// held tile nears its target rather than only once it is fully over it.
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
    this.onMoveGroup,
    this.group = const <String>{},
  });

  final List<PinnedTile> tiles;
  final String Function(String id) labelFor;
  final TileServices services;
  final String? selected;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onDelete;

  /// [after] is which side of [target] the moved tile goes on.
  final void Function(String moving, String target, bool after) onReorder;

  /// A held group was dropped: every tile's id, in its new order.
  final ValueChanged<List<String>>? onMoveGroup;

  /// The tiles picked to move together (empty outside move-many). Holding
  /// any one of them lifts all of them: one ghost, one insertion line, and
  /// [onReorder] is told which tile was held.
  final Set<String> group;

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

  /// Width (or, for a horizontal marker, height) of the insertion line; it
  /// sits in the gutter between two tiles.
  static const double _lineWidth = 6;

  final GlobalKey _gridKey = GlobalKey();
  Timer? _scrollTimer;
  Offset _pointer = Offset.zero;

  /// Where the finger sits in the ghost: the middle of the held tile, which
  /// for a group is the middle of that tile inside the picked tiles' block.
  Offset _anchor = Offset.zero;

  /// The tile a held one is over and which edge of it the drop would be on,
  /// or null when it is over none.
  ({String id, _Edge edge})? _drop;

  /// Where a held group would land right now: the whole new order and the
  /// box the block covers, or null when none is held over the grid.
  BlockDrop? _groupDrop;

  /// The grid's last layout, for working out a group's landing spot.
  ({int columns, double gap, double width}) _metrics = (
    columns: 4,
    gap: 0,
    width: 0,
  );

  bool _isGroupDrag(String moving) =>
      widget.onMoveGroup != null &&
      widget.group.length > 1 &&
      widget.group.contains(moving);

  /// The block lands where it can stay whole nearest the held ghost's
  /// top-left, wherever over the grid it is, so the line and the ghost stay
  /// together instead of the line being tied to the tile under the finger.
  BlockDrop? _landingFor(Offset ghostTopLeft) {
    final RenderObject? grid = _gridKey.currentContext?.findRenderObject();
    if (grid is! RenderBox || !grid.attached) return null;
    final Offset local = grid.globalToLocal(ghostTopLeft);
    return nearestBlockDrop(
      widget.tiles,
      widget.group,
      toLeft: local.dx,
      toTop: local.dy,
      columns: _metrics.columns,
      maxWidth: _metrics.width,
      gap: _metrics.gap,
    );
  }

  void _hoverGroup(Offset ghostTopLeft) {
    final BlockDrop? next = _landingFor(ghostTopLeft);
    final BlockDrop? last = _groupDrop;
    if (next == null ||
        (last != null &&
            last.left == next.left &&
            last.top == next.top &&
            last.width == next.width &&
            last.height == next.height &&
            _sameOrder(last.order, next.order))) {
      return;
    }
    setState(() => _groupDrop = next);
  }

  static bool _sameOrder(List<PinnedTile> a, List<PinnedTile> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  void _dropGroup(Offset ghostTopLeft) {
    final BlockDrop? landing = _landingFor(ghostTopLeft) ?? _groupDrop;
    if (mounted) setState(() => _groupDrop = null);
    if (landing == null) return;
    widget.onMoveGroup!(<String>[
      for (final PinnedTile p in landing.order) p.id,
    ]);
  }

  /// Whether the held tile is one of [EditableTileGrid.group], so the rest
  /// of the group is lifted with it.
  bool _holdingGroup = false;

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
    if (mounted && (_holdingGroup || _groupDrop != null)) {
      setState(() {
        _holdingGroup = false;
        _groupDrop = null;
      });
    }
  }

  /// A group never lands on one of its own tiles.
  bool _blocked(String moving, String target) =>
      moving == target ||
      (widget.group.contains(moving) && widget.group.contains(target));

  /// Which edge of [r], the tile it is over, the finger is closest to: [r] is
  /// split by its two diagonals into four triangles, and the one the finger
  /// falls in decides the edge, so a wide or tall tile still splits evenly
  /// by fraction of its own width/height rather than raw pixels.
  /// [ghostTopLeft] is where the drag details put the held tile's ghost; the
  /// finger is read from that rather than from the drag's own updates, which
  /// can arrive after the target's.
  _Edge _edgeOf(TileRect r, Offset ghostTopLeft) {
    final RenderObject? grid = _gridKey.currentContext?.findRenderObject();
    if (grid is! RenderBox || !grid.attached) return _Edge.left;
    final Offset finger = ghostTopLeft + _anchor;
    final Offset local = grid.globalToLocal(finger);
    final double dx = (local.dx - r.left) / r.width - 0.5;
    final double dy = (local.dy - r.top) / r.height - 0.5;
    if (dx.abs() > dy.abs()) {
      return dx > 0 ? _Edge.right : _Edge.left;
    }
    return dy > 0 ? _Edge.bottom : _Edge.top;
  }

  void _hoverOver(TileRect r, Offset ghostTopLeft) {
    final ({String id, _Edge edge}) next = (
      id: r.tile.id,
      edge: _edgeOf(r, ghostTopLeft),
    );
    if (_drop == next) return;
    setState(() => _drop = next);
  }

  void _clearDrop([String? onlyIfOver]) {
    final ({String id, _Edge edge})? drop = _drop;
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
    final LauncherSettings settings = SettingsScope.of(context);
    final List<PlacedTile> placed = packTiles(<Tile>[
      for (final PinnedTile p in widget.tiles) p.toTile(),
    ], columns: settings.columns);

    return LayoutBuilder(
      builder: (context, constraints) {
        _metrics = (
          columns: settings.columns,
          gap: settings.gap.pixels,
          width: constraints.maxWidth,
        );
        final List<TileRect> rects = layoutTiles(
          placed,
          maxWidth: constraints.maxWidth,
          columns: settings.columns,
          gap: settings.gap.pixels,
        );
        // What a held group would look like once dropped: just its own tiles,
        // packed together as they will land.
        final List<TileRect> preview = widget.group.length > 1
            ? layoutTiles(
                packTiles(<Tile>[
                  for (final PinnedTile p in widget.tiles)
                    if (widget.group.contains(p.id)) p.toTile(),
                ], columns: settings.columns),
                maxWidth: constraints.maxWidth,
                columns: settings.columns,
                gap: settings.gap.pixels,
              )
            : const <TileRect>[];
        return SizedBox(
          key: _gridKey,
          height: gridHeight(
            placed,
            maxWidth: constraints.maxWidth,
            columns: settings.columns,
            gap: settings.gap.pixels,
          ),
          child: Stack(
            // The line in the outermost gutter sticks out past the grid.
            clipBehavior: Clip.none,
            children: <Widget>[
              // Under the tiles: a held group can also be dropped on the
              // gaps between and around them, not only on a tile.
              Positioned.fill(
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (d) => _isGroupDrag(d.data),
                  onMove: (d) => _hoverGroup(d.offset),
                  onAcceptWithDetails: (d) => _dropGroup(d.offset),
                  builder: (context, candidate, rejected) =>
                      const SizedBox.expand(),
                ),
              ),
              for (final TileRect r in rects)
                _slot(r, settings.gap.pixels, preview),
              ?_dropLine(rects, settings.gap.pixels),
            ],
          ),
        );
      },
    );
  }

  /// The line along the edge of the tile a held one is over, on the side it
  /// would be dropped on; in the gutter, so it never covers a tile. For a held
  /// group it is the leading edge of where the whole block will really land
  /// (see [nearestBlockDrop]), as long as the block is.
  Widget? _dropLine(List<TileRect> rects, double gap) {
    final BlockDrop? landing = _groupDrop;
    if (landing != null) {
      // One line on the block's leading edge: its left side when it sits
      // beside something, its top when it starts a row.
      final bool beside = landing.left > gap;
      return Positioned(
        key: const ValueKey('drop-line'),
        left: beside ? landing.left - gap / 2 - _lineWidth / 2 : landing.left,
        top: beside ? landing.top : landing.top - gap / 2 - _lineWidth / 2,
        width: beside ? _lineWidth : landing.width,
        height: beside ? landing.height : _lineWidth,
        child: IgnorePointer(child: ColoredBox(color: TileColors.highlight)),
      );
    }
    final ({String id, _Edge edge})? drop = _drop;
    if (drop == null) return null;
    for (final TileRect r in rects) {
      if (r.tile.id != drop.id) continue;
      return Positioned(
        key: const ValueKey('drop-line'),
        left: drop.edge == _Edge.right
            ? r.left + r.width + gap / 2 - _lineWidth / 2
            : drop.edge == _Edge.left
            ? r.left - gap / 2 - _lineWidth / 2
            : r.left,
        top: drop.edge == _Edge.bottom
            ? r.top + r.height + gap / 2 - _lineWidth / 2
            : drop.edge == _Edge.top
            ? r.top - gap / 2 - _lineWidth / 2
            : r.top,
        width: drop.edge == _Edge.top || drop.edge == _Edge.bottom
            ? r.width
            : _lineWidth,
        height: drop.edge == _Edge.left || drop.edge == _Edge.right
            ? r.height
            : _lineWidth,
        child: IgnorePointer(child: ColoredBox(color: TileColors.highlight)),
      );
    }
    return null;
  }

  static Size _boundsOf(List<TileRect> rects) {
    double right = 0;
    double bottom = 0;
    for (final TileRect p in rects) {
      right = right < p.left + p.width ? p.left + p.width : right;
      bottom = bottom < p.top + p.height ? p.top + p.height : bottom;
    }
    return Size(right, bottom);
  }

  Widget _viewOf(Tile tile) {
    final String id = tile.id;
    return TileView(
      colour: tile.colour,
      content: tileContent(
        tile,
        labelFor: (t) => t.label ?? widget.labelFor(t.id),
        services: widget.services,
        interactive: false,
      ),
      selected: id == widget.selected || widget.group.contains(id),
      onTap: () => widget.onSelect(id),
      onDelete: () => widget.onDelete(id),
      deleteKey: ValueKey('delete-$id'),
    );
  }

  /// The picked tiles laid out as they will land, each at its own place in
  /// [preview].
  Widget _groupGhost(List<TileRect> preview) {
    final Size bounds = _boundsOf(preview);
    return SizedBox(
      width: bounds.width,
      height: bounds.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          for (final TileRect p in preview)
            Positioned(
              left: p.left,
              top: p.top,
              width: p.width,
              height: p.height,
              child: _viewOf(p.tile),
            ),
        ],
      ),
    );
  }

  /// [gap]'s a tile's drop area reaches past its own edges, meeting its
  /// neighbours' halfway across the gutter, so hovering the gutter itself —
  /// not just the tile beyond it — already shows a marker.
  Widget _slot(TileRect r, double gap, List<TileRect> preview) {
    final Tile tile = r.tile;
    final String id = tile.id;
    final double pad = gap / 2;
    // The ghost: the held tile alone, or, for a picked tile, the whole group
    // laid out as it will land, held by this tile's middle.
    final TileRect? held = widget.group.contains(id)
        ? preview.where((TileRect p) => p.tile.id == id).firstOrNull
        : null;
    final Offset anchor = held == null
        ? Offset(r.width / 2, r.height / 2)
        : Offset(held.left + held.width / 2, held.top + held.height / 2);
    final Widget view = _viewOf(tile);

    return Positioned(
      left: r.left - pad,
      top: r.top - pad,
      width: r.width + pad * 2,
      height: r.height + pad * 2,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) =>
            _isGroupDrag(details.data) || !_blocked(details.data, id),
        onMove: (details) {
          if (_isGroupDrag(details.data)) {
            _hoverGroup(details.offset);
            return;
          }
          // Every tile under the finger is told about a move, the held one
          // included; only another tile is somewhere to go.
          if (_blocked(details.data, id)) {
            _clearDrop();
          } else {
            _hoverOver(r, details.offset);
          }
        },
        onLeave: (_) => _clearDrop(id),
        onAcceptWithDetails: (details) {
          if (_isGroupDrag(details.data)) {
            _dropGroup(details.offset);
            return;
          }
          final _Edge edge = _edgeOf(r, details.offset);
          _clearDrop();
          widget.onReorder(
            details.data,
            id,
            edge == _Edge.right || edge == _Edge.bottom,
          );
        },
        // The padding gives the target its extra reach without moving the
        // tile itself, which keeps the same key and bounds the rest of the
        // widget tree (and tests) expect from the tile's own rect.
        builder: (context, candidate, rejected) => Padding(
          padding: EdgeInsets.all(pad),
          child: KeyedSubtree(
            key: ValueKey(id),
            child: LongPressDraggable<String>(
              data: id,
              delay: EditableTileGrid.pickUpDelay,
              onDragStarted: () {
                _anchor = anchor;
                if (widget.group.contains(id)) {
                  setState(() => _holdingGroup = true);
                }
              },
              onDragUpdate: (details) => _dragMoved(details.globalPosition),
              onDragEnd: (_) => _dragEnded(),
              // Held by its middle wherever it was grabbed, so the tile it
              // goes beside is the one under the middle of the ghost, which
              // is where the eye puts it, not under the corner it was
              // picked up by.
              dragAnchorStrategy: (draggable, context, position) => anchor,
              // The feedback widget renders in the root Overlay, outside
              // this tree's Material ancestor -- TileView's InkWell needs
              // its own.
              feedback: Material(
                type: MaterialType.transparency,
                child: Opacity(
                  opacity: 0.75,
                  child: held == null
                      ? SizedBox(width: r.width, height: r.height, child: view)
                      : _groupGhost(preview),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: view),
              // The rest of a lifted group fades like the held tile does.
              child: _holdingGroup && widget.group.contains(id)
                  ? Opacity(opacity: 0.3, child: view)
                  : view,
            ),
          ),
        ),
      ),
    );
  }
}

/// Which side of a tile a held one is being dropped on.
enum _Edge { left, right, top, bottom }
