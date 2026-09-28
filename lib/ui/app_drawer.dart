import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/app_matcher.dart';
import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/services/app_repository.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/ui/app_icon.dart';
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
    this.searchFocus,
    this.iconOf,
  });

  final List<AppInfo> apps;
  final GridState gridState;
  final ValueChanged<String> onLaunch;
  final Future<bool> Function(String packageName) onOpenDetails;
  final Future<bool> Function(String packageName) onUninstall;

  /// Lets the caller put the cursor in the search field (the swipe-up
  /// "search apps" gesture).
  final FocusNode? searchFocus;

  /// Where a row gets its app's icon from; without it rows show a letter.
  final AppIconLoader? iconOf;

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
    iconOf: widget.iconOf,
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
            focusNode: widget.searchFocus,
            onChanged: _onQueryChanged,
            style: Theme.of(context).textTheme.bodyMedium,
            cursorColor: TileColors.textBright,
            decoration: InputDecoration(
              // Roomy, not dense, and the same as the contact picker's: a thin
              // field is hard to hit and to read.
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              hintText: Messages.searchApps,
              hintStyle: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: TileColors.muted),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: TileColors.bezel),
              ),
              focusedBorder: UnderlineInputBorder(
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

/// How big an app's icon is on a drawer row.
const double rowIconSize = 32;

/// An app's first letter in a frame, for while its icon loads, or when it has
/// none, so every row keeps the same indent.
class _LetterBox extends StatelessWidget {
  const _LetterBox({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: TileColors.bezel, width: TileMetrics.bevel),
      ),
      child: Text(
        letter.isEmpty ? '?' : letter[0].toUpperCase(),
        style: TextStyle(
          fontFamily: kPixelFontFamily,
          fontSize: 12,
          color: TileColors.textDim,
        ),
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({
    super.key,
    required this.app,
    required this.onTap,
    required this.onLongPress,
    this.iconOf,
  });

  final AppInfo app;
  final AppIconLoader? iconOf;
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
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: TileColors.bezel)),
        ),
        child: Row(
          children: <Widget>[
            if (iconOf != null) ...<Widget>[
              AppIcon(
                packageName: app.packageName,
                loader: iconOf!,
                size: rowIconSize,
                fallback: _LetterBox(letter: app.label),
              ),
              const SizedBox(width: TileMetrics.margin),
            ],
            Expanded(
              child: Text(
                app.label.toUpperCase(),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: TileColors.textBright),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
