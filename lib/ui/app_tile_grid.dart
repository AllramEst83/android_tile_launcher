import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_layout.dart';
import 'package:android_tile_launcher/services/system_control_service.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_grid.dart';
import 'package:flutter/material.dart';

/// The home mosaic: [tiles] packed and rendered. [emptyMessage] is the
/// caller's call — an empty grid means something different on the curated
/// home page than it does for a genuinely appless drawer search. Pull down
/// to refresh; long-press a tile to enter the grid editor (Phase 6).
class AppTileGrid extends StatelessWidget {
  const AppTileGrid({
    super.key,
    required this.tiles,
    required this.labelFor,
    required this.systemControl,
    required this.emptyMessage,
    required this.onLaunch,
    required this.onRefresh,
    this.onLongPress,
  });

  final List<Tile> tiles;
  final String Function(Tile tile) labelFor;
  final SystemControlService systemControl;
  final String emptyMessage;
  final ValueChanged<String> onLaunch;
  final Future<void> Function() onRefresh;
  final ValueChanged<String>? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: TileColors.textBright,
        backgroundColor: TileColors.canvas,
        child: Stack(
          children: <Widget>[
            ListView(),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(TileMetrics.margin),
                child: Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final List<PlacedTile> placed = packTiles(tiles);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: TileColors.textBright,
      backgroundColor: TileColors.canvas,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(TileMetrics.margin),
        child: TileGrid(
          placed: placed,
          labelFor: labelFor,
          systemControl: systemControl,
          onLaunch: onLaunch,
          onLongPress: onLongPress,
        ),
      ),
    );
  }
}
