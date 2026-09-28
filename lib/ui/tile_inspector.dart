import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:android_tile_launcher/ui/theme.dart';
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
              Text(Messages.tileSize, style: text.labelSmall),
              const SizedBox(height: TileMetrics.gutter),
              Wrap(
                spacing: TileMetrics.gutter,
                runSpacing: TileMetrics.gutter,
                children: <Widget>[
                  for (final TileSize size in TileSize.values)
                    _SizeButton(
                      size: size,
                      selected: size == selected.size,
                      onTap: () => onSizeSelected(size),
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

class _SizeButton extends StatelessWidget {
  const _SizeButton({
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final TileSize size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? TileColors.bezel : Colors.transparent,
          border: Border.all(color: TileColors.bezel, width: TileMetrics.bevel),
        ),
        child: Text(
          '${size.spanIn(SettingsScope.of(context).columns)}x${size.rows}',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: selected ? C64.black : TileColors.textBright),
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
