import 'package:android_tile_launcher/model/default_tiles.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_layout.dart';
import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_grid.dart';
import 'package:flutter/material.dart';

/// The home mosaic: [apps] as small tiles, ahead of a saved layout (Phase 5)
/// or an editor to change it (Phase 6). Pull down to refresh. [emptyMessage]
/// is the caller's call — an empty grid means something different on the
/// curated home page than it does for a genuinely appless drawer search.
class AppTileGrid extends StatelessWidget {
  const AppTileGrid({
    super.key,
    required this.apps,
    required this.emptyMessage,
    required this.onLaunch,
    required this.onRefresh,
  });

  final List<AppInfo> apps;
  final String emptyMessage;
  final ValueChanged<String> onLaunch;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
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

    final Map<String, String> labelByPackage = <String, String>{
      for (final AppInfo app in apps) app.packageName: app.label,
    };
    final List<PlacedTile> placed = packTiles(tilesForApps(apps));

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: TileColors.textBright,
      backgroundColor: TileColors.canvas,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(TileMetrics.margin),
        child: TileGrid(
          placed: placed,
          labelFor: (Tile tile) =>
              labelByPackage[tile.appPackage] ?? tile.appPackage,
          onLaunch: onLaunch,
        ),
      ),
    );
  }
}
