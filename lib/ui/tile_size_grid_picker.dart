import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key sizeGridPickerKey = ValueKey<String>('size-grid-picker');
Key sizeGridCellKey(int columns, int rows) =>
    ValueKey<String>('size-grid-cell-$columns-$rows');

/// An Excel-"insert table"-style grid: tap or drag toward a cell to paint
/// every size from 1x1 up to that cell's own columns x rows — the rectangle
/// from the top-left corner to wherever the finger is. Replaces 24 separate
/// size buttons (one per [TileSize]) with the shape itself, once that many
/// stopped being a reasonable thing to lay out in a `Wrap`.
///
/// [maxColumns] is the *live* mosaic's own column count (4 or 6 —
/// `LauncherSettings.columnChoices`), not a fixed constant: a tile picked at
/// 6 wide only makes sense while the mosaic actually has 6 columns to put it
/// in, the same reasoning `TileInspector` already applies by passing it in
/// fresh from `SettingsScope` rather than this widget assuming one. [maxRows]
/// stays fixed at [TileSize]'s own row cap (6) — nothing in Settings
/// configures how tall a tile may be.
///
/// [cellSize] is normally left unset: the grid then fills whatever width its
/// parent actually gives it (a `LayoutBuilder`, not a fixed 28px block off to
/// one side of a much wider panel), clamped between [minCellSize] and
/// [maxCellSize] so it neither shrinks unreadably small nor grows past a
/// sensible size on a wide panel. A test that needs the exact pixel geometry
/// of a tap or drag can still pin it to a known value.
class TileSizeGridPicker extends StatefulWidget {
  const TileSizeGridPicker({
    super.key,
    required this.size,
    required this.onSizeSelected,
    required this.maxColumns,
    this.maxRows = 6,
    this.cellSize,
    this.cellGap = 3,
    this.minCellSize = 20,
    this.maxCellSize = 36,
  });

  final TileSize size;
  final ValueChanged<TileSize> onSizeSelected;
  final int maxColumns;
  final int maxRows;
  final double? cellSize;
  final double cellGap;
  final double minCellSize;
  final double maxCellSize;

  @override
  State<TileSizeGridPicker> createState() => _TileSizeGridPickerState();
}

class _TileSizeGridPickerState extends State<TileSizeGridPicker> {
  /// The cell the finger is over mid-gesture, 0-based; `null` between
  /// gestures, when [TileSizeGridPicker.size] is what is actually painted.
  (int, int)? _hover;

  (int, int) _cellAt(Offset local, double step) {
    final int column = (local.dx / step).floor().clamp(
      0,
      widget.maxColumns - 1,
    );
    final int row = (local.dy / step).floor().clamp(0, widget.maxRows - 1);
    return (column, row);
  }

  void _updateHover(Offset local, double step) =>
      setState(() => _hover = _cellAt(local, step));

  void _commit() {
    final (int, int)? hover = _hover;
    setState(() => _hover = null);
    if (hover == null) return;
    widget.onSizeSelected(TileSize.of(hover.$1 + 1, hover.$2 + 1));
  }

  @override
  Widget build(BuildContext context) {
    final double? fixed = widget.cellSize;
    if (fixed != null) return _grid(fixed);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double fromWidth =
            (constraints.maxWidth - (widget.maxColumns - 1) * widget.cellGap) /
            widget.maxColumns;
        final double cell = fromWidth.clamp(
          widget.minCellSize,
          widget.maxCellSize,
        );
        return _grid(cell);
      },
    );
  }

  Widget _grid(double cellSize) {
    final double step = cellSize + widget.cellGap;
    final (int, int) painted =
        _hover ?? (widget.size.columns - 1, widget.size.rows - 1);
    final double width = widget.maxColumns * step - widget.cellGap;
    final double height = widget.maxRows * step - widget.cellGap;
    return GestureDetector(
      key: sizeGridPickerKey,
      behavior: HitTestBehavior.opaque,
      onPanStart: (DragStartDetails details) =>
          _updateHover(details.localPosition, step),
      onPanUpdate: (DragUpdateDetails details) =>
          _updateHover(details.localPosition, step),
      onPanEnd: (DragEndDetails _) => _commit(),
      onPanCancel: () => setState(() => _hover = null),
      onTapUp: (TapUpDetails details) {
        _updateHover(details.localPosition, step);
        _commit();
      },
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: <Widget>[
            for (int row = 0; row < widget.maxRows; row++)
              for (int column = 0; column < widget.maxColumns; column++)
                Positioned(
                  left: column * step,
                  top: row * step,
                  width: cellSize,
                  height: cellSize,
                  child: _Cell(
                    key: sizeGridCellKey(column + 1, row + 1),
                    filled: column <= painted.$1 && row <= painted.$2,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({super.key, required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled ? TileColors.accent : Colors.transparent,
        border: Border.all(color: TileColors.bezel, width: TileMetrics.bevel),
      ),
    );
  }
}
