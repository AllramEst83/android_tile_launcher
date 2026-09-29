import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_size_grid_picker.dart';
import 'package:flutter/material.dart';

/// The panel below the canvas in the grid editor. The label/Apply row is
/// always there — deleting the selected tile must not strand Apply
/// somewhere unreachable — with the size and colour pickers underneath only
/// while a tile ([tile]) is actually selected.
class TileInspector extends StatelessWidget {
  const TileInspector({
    super.key,
    required this.label,
    required this.tile,
    required this.onApply,
    required this.onSizeSelected,
    required this.onColourSelected,
  });

  final String label;
  final PinnedTile? tile;
  final VoidCallback onApply;
  final ValueChanged<TileSize> onSizeSelected;
  final ValueChanged<C64Colour> onColourSelected;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final PinnedTile? selected = tile;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: TileColors.bezel)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(label.toUpperCase(), style: text.bodyMedium),
                ),
                InkWell(
                  onTap: onApply,
                  child: Text(Messages.apply, style: text.bodyMedium),
                ),
              ],
            ),
            if (selected != null) ...<Widget>[
              const SizedBox(height: TileMetrics.gutter * 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(Messages.tileSize, style: text.labelSmall),
                  Text(
                    '${selected.size.columns} × ${selected.size.rows}',
                    style: text.labelSmall?.copyWith(
                      color: TileColors.highlight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TileMetrics.gutter),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TileSizeGridPicker(
                    size: selected.size,
                    onSizeSelected: onSizeSelected,
                  ),
                  const SizedBox(width: TileMetrics.gutter),
                  Expanded(
                    child: PadKey(
                      label: Messages.tileSizeFlip,
                      height: 44,
                      fontSize: 9,
                      // Flipping only ever makes sense when the result still
                      // fits `TileSize`'s own 4-column cap — a tile taller
                      // than 4 rows has no matching width to flip into.
                      onTap: selected.size.rows > 4
                          ? null
                          : () => onSizeSelected(
                              TileSize.of(
                                selected.size.rows,
                                selected.size.columns,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TileMetrics.gutter * 2),
              Text(Messages.tileColour, style: text.labelSmall),
              const SizedBox(height: TileMetrics.gutter),
              Wrap(
                spacing: TileMetrics.gutter,
                runSpacing: TileMetrics.gutter,
                children: <Widget>[
                  for (final C64Colour colour in pinnableColours)
                    _ColourSwatch(
                      key: ValueKey(colour),
                      colour: colour,
                      selected: colour == selected.colour,
                      onTap: () => onColourSelected(colour),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColourSwatch extends StatelessWidget {
  const _ColourSwatch({
    super.key,
    required this.colour,
    required this.selected,
    required this.onTap,
  });

  final C64Colour colour;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colour.fill,
          border: Border.all(
            color: selected ? C64.white : Colors.transparent,
            width: TileMetrics.bevel,
          ),
        ),
      ),
    );
  }
}
