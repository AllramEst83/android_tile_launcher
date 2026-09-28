import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/app_matcher.dart';
import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/ui/grouped_list.dart';
import 'package:android_tile_launcher/ui/quick_actions_sheet.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// All Apps: every installed app, A to Z then Å Ä Ö (`GroupedList`, from
/// `model/alpha_grouping.dart`) with a jump index down the right edge, or —
/// while the search field has text — a flat list ranked best-match-first
/// instead (`model/app_matcher.dart`). Long-press a row for quick actions.
class AppDrawer extends StatefulWidget {
  const AppDrawer({
    super.key,
    required this.apps,
    required this.gridState,
    required this.onLaunch,
    required this.onOpenDetails,
    required this.onUninstall,
  });

  final List<AppInfo> apps;
  final GridState gridState;
  final ValueChanged<String> onLaunch;
  final Future<bool> Function(String packageName) onOpenDetails;
  final Future<bool> Function(String packageName) onUninstall;

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) => setState(() => _query = value);

  void _openQuickActions(AppInfo app) {
    showQuickActions(
      context,
      app: app,
      gridState: widget.gridState,
      onOpenDetails: widget.onOpenDetails,
      onUninstall: widget.onUninstall,
    );
  }

  Widget _row(AppInfo app) => _AppRow(
    key: ValueKey(app.packageName),
    app: app,
    onTap: () => widget.onLaunch(app.packageName),
    onLongPress: () => _openQuickActions(app),
  );

  @override
  Widget build(BuildContext context) {
    final bool searching = _query.trim().isNotEmpty;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TileMetrics.margin,
            TileMetrics.gutter,
            TileMetrics.margin,
            TileMetrics.gutter,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onQueryChanged,
            style: Theme.of(context).textTheme.bodyMedium,
            cursorColor: TileColors.textBright,
            decoration: InputDecoration(
              // Roomy, not dense, and the same as the contact picker's: a thin
              // field is hard to hit and to read.
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              hintText: Messages.searchApps,
              hintStyle: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: C64.lightGrey),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: TileColors.bezel),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: TileColors.textBright),
              ),
            ),
          ),
        ),
        Expanded(
          child: searching
              ? _SearchResults(
                  apps: rankApps(widget.apps, _query),
                  rowBuilder: _row,
                )
              : widget.apps.isEmpty
              ? Center(
                  child: Text(
                    Messages.noAppsFound,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : GroupedList<AppInfo>(
                  items: widget.apps,
                  label: (AppInfo a) => a.label,
                  rowBuilder: (BuildContext context, AppInfo app) => _row(app),
                ),
        ),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.apps, required this.rowBuilder});

  final List<AppInfo> apps;
  final Widget Function(AppInfo app) rowBuilder;

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return Center(
        child: Text(
          Messages.noSearchResults,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return ListView(
      children: <Widget>[for (final AppInfo app in apps) rowBuilder(app)],
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({
    super.key,
    required this.app,
    required this.onTap,
    required this.onLongPress,
  });

  final AppInfo app;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(
          horizontal: TileMetrics.margin,
          vertical: TileMetrics.gutter,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: TileColors.bezel)),
        ),
        child: Text(
          app.label.toUpperCase(),
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: TileColors.textBright),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
