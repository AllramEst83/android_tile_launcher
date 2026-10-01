import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
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
    // The live mosaic's own column count (4 or 6), not a fixed constant —
    // the size grid needs it below.
    final int columns = SettingsScope.of(context).columns;
    // What the grid really draws: a tile stored wider than this mosaic (or a
    // full-width wide/large) shows and reads at that width, so the
    // panel never disagrees with the tile above it after a column switch.
    final int? span = selected?.size.spanIn(columns);
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
                    '$span × ${selected.size.rows}',
                    style: text.labelSmall?.copyWith(
                      color: TileColors.highlight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TileMetrics.gutter),
              // The grid picker fills whatever width it is actually given,
              // not a fixed-size block off to one side of a much wider panel
              // (the user's own complaint, from testing Phase 37 on a phone).
              // It reaches every shape directly, so there is no FLIP button.
              TileSizeGridPicker(
                size: selected.size,
                maxColumns: columns,
                onSizeSelected: onSizeSelected,
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
