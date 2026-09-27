import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// The plain scrolling list that proves the app channel works, ahead of the
/// tile mosaic (plan.md, Phase 3). Pull down to refresh the cached listing.
class AppListView extends StatelessWidget {
  const AppListView({
    super.key,
    required this.apps,
    required this.onLaunch,
    required this.onRefresh,
  });

  final List<AppInfo> apps;
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
              child: Text(
                Messages.noAppsFound,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: TileColors.textBright,
      backgroundColor: TileColors.canvas,
      child: ListView.builder(
        itemCount: apps.length,
        itemBuilder: (BuildContext context, int index) {
          final AppInfo app = apps[index];
          return AppRow(
            key: ValueKey(app.packageName),
            app: app,
            onTap: () => onLaunch(app.packageName),
          );
        },
      ),
    );
  }
}

class AppRow extends StatelessWidget {
  const AppRow({super.key, required this.app, required this.onTap});

  final AppInfo app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TileMetrics.margin,
          vertical: TileMetrics.gutter * 1.5,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: TileColors.bezel)),
        ),
        child: Text(
          app.label.toUpperCase(),
          style: Theme.of(context).textTheme.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
