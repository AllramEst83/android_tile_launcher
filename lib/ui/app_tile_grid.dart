import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_layout.dart';
import 'package:android_tile_launcher/services/tile_services.dart';
import 'package:android_tile_launcher/ui/overscroll_gestures.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_grid.dart';
import 'package:flutter/material.dart';

/// The home mosaic: [tiles] packed and rendered. [emptyMessage] is the
/// caller's call — an empty grid means something different on the curated
/// home page than it does for a genuinely appless drawer search. Pull down
/// to refresh (or whatever the swipe gestures are set to); long-press a tile to enter the grid editor (Phase 6).
class AppTileGrid extends StatelessWidget {
  const AppTileGrid({
    super.key,
    required this.tiles,
    required this.labelFor,
    required this.services,
    required this.emptyMessage,
    required this.onLaunch,
    required this.onRefresh,
    this.onLongPress,
    this.onGesture,
  });

  final List<Tile> tiles;
  final String Function(Tile tile) labelFor;
  final TileServices services;
  final String emptyMessage;
  final ValueChanged<String> onLaunch;
  final Future<void> Function() onRefresh;
  final ValueChanged<String>? onLongPress;

  /// Told which action the swipe down or swipe up on the grid is set to (see
  /// `LauncherSettings`). Not told about pull-to-refresh, which the grid does
  /// itself.
  final ValueChanged<GestureAction>? onGesture;

  @override
  Widget build(BuildContext context) {
    final LauncherSettings settings = SettingsScope.of(context);
    // Pull-to-refresh is one of the things a swipe down can be set to; when it
    // is something else, the indicator would fight it for the same drag.
    final bool refreshes = settings.swipeDown == GestureAction.refreshApps;

    Widget content;
    if (tiles.isEmpty) {
      content = Stack(
        children: <Widget>[
          ListView(physics: const AlwaysScrollableScrollPhysics()),
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
      );
    } else {
      content = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(TileMetrics.margin),
        child: TileGrid(
          placed: packTiles(tiles, columns: settings.columns),
          labelFor: labelFor,
          services: services,
          onLaunch: onLaunch,
          onLongPress: onLongPress,
        ),
      );
    }

    if (refreshes) {
      content = RefreshIndicator(
        onRefresh: onRefresh,
        color: TileColors.textBright,
        backgroundColor: TileColors.canvas,
        child: content,
      );
    }

    final ValueChanged<GestureAction>? onGesture = this.onGesture;
    if (onGesture == null) return content;
    return OverscrollGestures(
      onPullDown: refreshes ? null : () => onGesture(settings.swipeDown),
      onPushUp: () => onGesture(settings.swipeUp),
      child: content,
    );
  }
}
