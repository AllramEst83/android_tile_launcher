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

  // Proportional, not a scroll-to-widget: with a long app list most letters
  // haven't been built yet (ListView only builds what's near the viewport),
  // so there's no GlobalKey/context to scroll to. A fraction of
  // maxScrollExtent works everywhere and tracks a drag 1:1.
  void _jumpToIndex(int index, int count) {
    if (!_scrollController.hasClients) return;
    final ScrollPosition position = _scrollController.position;
    final double fraction = count <= 1 ? 0 : index / (count - 1);
    position.jumpTo(
      (position.maxScrollExtent * fraction).clamp(
        0.0,
        position.maxScrollExtent,
      ),
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
                  onTap: widget.onLaunch,
                  onLongPress: _openQuickActions,
                )
              : _BrowseList(
                  apps: widget.apps,
                  scrollController: _scrollController,
                  onJumpTo: _jumpToIndex,
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
  final void Function(int index, int count) onJumpTo;
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ListView(
            controller: scrollController,
            children: <Widget>[
              for (final InitialGroup<AppInfo> group in groups) ...<Widget>[
                _SectionHeader(initial: group.initial),
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
          key: const Key('jump-index'),
          initials: [for (final InitialGroup<AppInfo> g in groups) g.initial],
          onTap: (int index) => onJumpTo(index, groups.length),
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
  const _SectionHeader({required this.initial});

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
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: TileColors.textBright),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// A–Z down the right edge: tap a letter to jump, or drag up and down the
/// whole strip to scrub through it — every row a finger passes over jumps in
/// turn, with a thin bar tracking the touch so a fast scrub still shows where
/// it is.
class _JumpIndex extends StatefulWidget {
  const _JumpIndex({super.key, required this.initials, required this.onTap});

  final List<String> initials;
  final ValueChanged<int> onTap;

  @override
  State<_JumpIndex> createState() => _JumpIndexState();
}

class _JumpIndexState extends State<_JumpIndex> {
  static const double _rowHeight = 20;

  int? _active;

  void _handleAt(double localY) {
    final int index = (localY / _rowHeight).floor().clamp(
      0,
      widget.initials.length - 1,
    );
    if (index == _active) return;
    setState(() => _active = index);
    widget.onTap(index);
  }

  void _release() => setState(() => _active = null);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => _handleAt(details.localPosition.dy),
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      onVerticalDragStart: (details) => _handleAt(details.localPosition.dy),
      onVerticalDragUpdate: (details) => _handleAt(details.localPosition.dy),
      onVerticalDragEnd: (_) => _release(),
      child: SizedBox(
        width: 20,
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                for (final (int i, String initial) in widget.initials.indexed)
                  SizedBox(
                    height: _rowHeight,
                    child: Center(
                      child: Text(
                        initial,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: i == _active
                              ? C64.white
                              : TileColors.textBright,
                          fontWeight: i == _active ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (_active != null)
              Positioned(
                left: 0,
                right: 0,
                top: _active! * _rowHeight + _rowHeight - 2,
                child: Container(height: 2, color: TileColors.textBright),
              ),
          ],
        ),
      ),
    );
  }
}
