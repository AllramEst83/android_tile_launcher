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
/// [maxColumns]/[maxRows] are [TileSize]'s own bounds (4 and 6), not this
/// mosaic's live column count — a tile's own footprint is capped there
/// whatever the grid setting is, the same way it always has been.
class TileSizeGridPicker extends StatefulWidget {
  const TileSizeGridPicker({
    super.key,
    required this.size,
    required this.onSizeSelected,
    this.maxColumns = 4,
    this.maxRows = 6,
    this.cellSize = 28,
    this.cellGap = 3,
  });

  final TileSize size;
  final ValueChanged<TileSize> onSizeSelected;
  final int maxColumns;
  final int maxRows;
  final double cellSize;
  final double cellGap;

  @override
  State<TileSizeGridPicker> createState() => _TileSizeGridPickerState();
}

class _TileSizeGridPickerState extends State<TileSizeGridPicker> {
  /// The cell the finger is over mid-gesture, 0-based; `null` between
  /// gestures, when [TileSizeGridPicker.size] is what is actually painted.
  (int, int)? _hover;

  double get _step => widget.cellSize + widget.cellGap;

  (int, int) _cellAt(Offset local) {
    final int column = (local.dx / _step).floor().clamp(
      0,
      widget.maxColumns - 1,
    );
    final int row = (local.dy / _step).floor().clamp(0, widget.maxRows - 1);
    return (column, row);
  }

  void _updateHover(Offset local) => setState(() => _hover = _cellAt(local));

  void _commit() {
    final (int, int)? hover = _hover;
    setState(() => _hover = null);
    if (hover == null) return;
    widget.onSizeSelected(TileSize.of(hover.$1 + 1, hover.$2 + 1));
  }

  @override
  Widget build(BuildContext context) {
    final (int, int) painted =
        _hover ?? (widget.size.columns - 1, widget.size.rows - 1);
    final double width = widget.maxColumns * _step - widget.cellGap;
    final double height = widget.maxRows * _step - widget.cellGap;
    return GestureDetector(
      key: sizeGridPickerKey,
      behavior: HitTestBehavior.opaque,
      onPanStart: (DragStartDetails details) =>
          _updateHover(details.localPosition),
      onPanUpdate: (DragUpdateDetails details) =>
          _updateHover(details.localPosition),
      onPanEnd: (DragEndDetails _) => _commit(),
      onPanCancel: () => setState(() => _hover = null),
      onTapUp: (TapUpDetails details) {
        _updateHover(details.localPosition);
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
                  left: column * _step,
                  top: row * _step,
                  width: widget.cellSize,
                  height: widget.cellSize,
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
