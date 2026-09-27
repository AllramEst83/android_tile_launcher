import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/alpha_grouping.dart';
import 'package:android_tile_launcher/model/app_matcher.dart';
import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/ui/quick_actions_sheet.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// All Apps: every installed app, A to Z then Å Ä Ö (`model/alpha_grouping.dart`)
/// with a jump index down the right edge, or — while the search field has
/// text — a flat list ranked best-match-first instead (`model/app_matcher.dart`).
/// Long-press a row for quick actions.
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
  final ScrollController _scrollController = ScrollController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) => setState(() => _query = value);

  void _jumpTo(GlobalKey key) {
    final BuildContext? sectionContext = key.currentContext;
    if (sectionContext == null) return;
    Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _openQuickActions(AppInfo app) {
    showQuickActions(
      context,
      app: app,
      gridState: widget.gridState,
      onOpenDetails: widget.onOpenDetails,
      onUninstall: widget.onUninstall,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool searching = _query.trim().isNotEmpty;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TileMetrics.margin,
            TileMetrics.margin,
            TileMetrics.margin,
            TileMetrics.gutter,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onQueryChanged,
            style: Theme.of(context).textTheme.bodyMedium,
            cursorColor: TileColors.textBright,
            decoration: InputDecoration(
              isDense: true,
              hintText: Messages.searchApps,
              hintStyle: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: TileColors.textDim),
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
                  onTap: widget.onLaunch,
                  onLongPress: _openQuickActions,
                )
              : _BrowseList(
                  apps: widget.apps,
                  scrollController: _scrollController,
                  onJumpTo: _jumpTo,
                  onTap: widget.onLaunch,
                  onLongPress: _openQuickActions,
                ),
        ),
      ],
    );
  }
}

class _BrowseList extends StatelessWidget {
  const _BrowseList({
    required this.apps,
    required this.scrollController,
    required this.onJumpTo,
    required this.onTap,
    required this.onLongPress,
  });

  final List<AppInfo> apps;
  final ScrollController scrollController;
  final ValueChanged<GlobalKey> onJumpTo;
  final ValueChanged<String> onTap;
  final ValueChanged<AppInfo> onLongPress;

  @override
  Widget build(BuildContext context) {
    final List<InitialGroup<AppInfo>> groups = groupByInitial(
      apps,
      (AppInfo a) => a.label,
    );
    if (groups.isEmpty) {
      return Center(
        child: Text(
          Messages.noAppsFound,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    final Map<String, GlobalKey> headerKeys = <String, GlobalKey>{
      for (final InitialGroup<AppInfo> g in groups) g.initial: GlobalKey(),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ListView(
            controller: scrollController,
            children: <Widget>[
              for (final InitialGroup<AppInfo> group in groups) ...<Widget>[
                _SectionHeader(
                  key: headerKeys[group.initial],
                  initial: group.initial,
                ),
                for (final AppInfo app in group.items)
                  _AppRow(
                    key: ValueKey(app.packageName),
                    app: app,
                    onTap: () => onTap(app.packageName),
                    onLongPress: () => onLongPress(app),
                  ),
              ],
            ],
          ),
        ),
        _JumpIndex(
          initials: [for (final InitialGroup<AppInfo> g in groups) g.initial],
          onTap: (String initial) => onJumpTo(headerKeys[initial]!),
        ),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.apps,
    required this.onTap,
    required this.onLongPress,
  });

  final List<AppInfo> apps;
  final ValueChanged<String> onTap;
  final ValueChanged<AppInfo> onLongPress;

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
      children: <Widget>[
        for (final AppInfo app in apps)
          _AppRow(
            key: ValueKey(app.packageName),
            app: app,
            onTap: () => onTap(app.packageName),
            onLongPress: () => onLongPress(app),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({super.key, required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TileMetrics.margin,
        TileMetrics.gutter * 2,
        TileMetrics.margin,
        TileMetrics.gutter,
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(color: TileColors.textDim),
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
          style: Theme.of(context).textTheme.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _JumpIndex extends StatelessWidget {
  const _JumpIndex({required this.initials, required this.onTap});

  final List<String> initials;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          for (final String initial in initials)
            InkWell(
              onTap: () => onTap(initial),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TileMetrics.gutter,
                  vertical: 2,
                ),
                child: Text(
                  initial,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(fontSize: 10, color: TileColors.textBright),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
