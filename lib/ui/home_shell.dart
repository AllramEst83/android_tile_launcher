import 'dart:async';

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/list_reorder.dart';
import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/services/app_repository.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/services/tile_services.dart';
import 'package:android_tile_launcher/ui/add_tile_sheet.dart';
import 'package:android_tile_launcher/ui/app_drawer.dart';
import 'package:android_tile_launcher/ui/app_tile_grid.dart';
import 'package:android_tile_launcher/ui/editable_tile_grid.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:android_tile_launcher/ui/settings_screen.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_inspector.dart';
import 'package:flutter/material.dart';

/// What Android shows when Home is pressed.
///
/// Back must never leave a launcher (there is nowhere to go), so the whole
/// shell is wrapped in a `PopScope` that refuses to pop. The boot screen is
/// also the loading and error state for the tile mosaic. A `PageView` holds
/// the two pages a swipe reaches: the curated home grid, then All Apps.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.appRepository,
    required this.gridState,
    required this.services,
  });

  final AppRepository appRepository;
  final GridState gridState;
  final TileServices services;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late Future<List<AppInfo>> _apps;
  final PageController _pageController = PageController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _apps = widget.appRepository.listApps();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final Future<List<AppInfo>> next = widget.appRepository.listApps(
      refresh: true,
    );
    setState(() {
      _apps = next;
    });
    // Swallowed here: the FutureBuilder below is already watching `next` and
    // renders the error state itself once it completes.
    await next.then((_) {}, onError: (_) {});
  }

  /// What a swipe down or up on Home was set to do (see settings).
  /// Pull-to-refresh is not here: the grid does that itself.
  void _perform(GestureAction action) {
    switch (action) {
      case GestureAction.notifications:
        unawaited(widget.services.shade.expandNotifications());
      case GestureAction.quickSettings:
        unawaited(widget.services.shade.expandQuickSettings());
      case GestureAction.searchApps:
        unawaited(_showDrawer(search: true));
      case GestureAction.allApps:
        unawaited(_showDrawer());
      case GestureAction.refreshApps:
      case GestureAction.none:
        break;
    }
  }

  Future<void> _showDrawer({bool search = false}) async {
    if (!_pageController.hasClients) return;
    await _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    if (search && mounted) _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const RainbowRule(),
              Expanded(
                child: FutureBuilder<List<AppInfo>>(
                  future: _apps,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const _BootScreen(error: true);
                    }
                    final List<AppInfo>? apps = snapshot.data;
                    if (apps == null) return const _BootScreen();
                    final Map<String, String> labelByPackage = <String, String>{
                      for (final AppInfo app in apps)
                        app.packageName: app.label,
                    };
                    String labelFor(String id) {
                      final String? appLabel = labelByPackage[id];
                      if (appLabel != null) return appLabel;
                      final TileKind? kind = tileKindNamed(id);
                      return kind == null
                          ? id.toUpperCase()
                          : displayNameOf(kind);
                    }

                    return ListenableBuilder(
                      listenable: widget.gridState,
                      builder: (context, _) => PageView(
                        controller: _pageController,
                        children: <Widget>[
                          _HomePage(
                            pinned: widget.gridState.pinned,
                            labelFor: labelFor,
                            gridState: widget.gridState,
                            services: widget.services,
                            onLaunch: widget.appRepository.launch,
                            onRefresh: _refresh,
                            onGesture: _perform,
                          ),
                          AppDrawer(
                            apps: apps,
                            gridState: widget.gridState,
                            onLaunch: widget.appRepository.launch,
                            onOpenDetails: widget.appRepository.openAppDetails,
                            onUninstall: widget.appRepository.uninstall,
                            searchFocus: _searchFocus,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home, or — while [_scratch] is non-null — the grid editor: long-press a
/// tile to start, drag one onto another to reorder, tap one to select it for
/// the inspector panel, delete with its badge. Changes only reach [GridState]
/// on Apply; Cancel discards them. [labelFor] resolves any tile id — an app's
/// package name, or a system kind's fixed id — to what its tile should show.
class _HomePage extends StatefulWidget {
  const _HomePage({
    required this.pinned,
    required this.labelFor,
    required this.gridState,
    required this.services,
    required this.onLaunch,
    required this.onRefresh,
    required this.onGesture,
  });

  final List<PinnedTile> pinned;
  final String Function(String id) labelFor;
  final GridState gridState;
  final TileServices services;
  final ValueChanged<String> onLaunch;
  final Future<void> Function() onRefresh;
  final ValueChanged<GestureAction> onGesture;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  List<PinnedTile>? _scratch;
  String? _selected;

  bool get _editing => _scratch != null;

  void _startEditing(String id) {
    setState(() {
      _scratch = List<PinnedTile>.of(widget.pinned);
      _selected = id;
    });
  }

  void _cancelEditing() {
    setState(() {
      _scratch = null;
      _selected = null;
    });
  }

  void _applyEditing() {
    final List<PinnedTile> result = _scratch!;
    setState(() {
      _scratch = null;
      _selected = null;
    });
    // The pin/order/size/colour changes already show on screen; only the
    // save to disk is still pending, and there is no error surface here for
    // it to report through if it fails (see GridState's failure contract).
    unawaited(widget.gridState.replaceAll(result));
  }

  void _select(String id) => setState(() => _selected = id);

  void _delete(String id) => setState(() {
    _scratch!.removeWhere((PinnedTile p) => p.id == id);
    if (_selected == id) _selected = null;
  });

  void _reorder(String moving, String target, bool after) => setState(() {
    final List<PinnedTile> scratch = _scratch!;
    final int from = scratch.indexWhere((PinnedTile p) => p.id == moving);
    final int to = scratch.indexWhere((PinnedTile p) => p.id == target);
    if (from == -1 || to == -1) return;
    _scratch = moveBeside(scratch, from: from, target: to, after: after);
  });

  void _resize(TileSize size) => _updateSelected((p) => p.copyWith(size: size));

  void _recolor(C64Colour colour) =>
      _updateSelected((p) => p.copyWith(colour: colour));

  void _updateSelected(PinnedTile Function(PinnedTile) update) => setState(() {
    final List<PinnedTile> scratch = _scratch!;
    final int i = scratch.indexWhere((PinnedTile p) => p.id == _selected);
    if (i == -1) return;
    scratch[i] = update(scratch[i]);
  });

  PinnedTile? _find(List<PinnedTile> tiles, String? id) {
    for (final PinnedTile p in tiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _openSettings() {
    final SettingsState? settings = SettingsScope.stateOf(context);
    if (settings == null) return;
    unawaited(
      showSettings(
        context,
        settings: settings,
        gridState: widget.gridState,
        services: widget.services,
      ),
    );
  }

  void _addTile() {
    unawaited(
      showAddTileSheet(
        context,
        gridState: widget.gridState,
        contacts: widget.services.contacts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      final List<PinnedTile> scratch = _scratch!;
      final PinnedTile? selectedTile = _find(scratch, _selected);
      return Column(
        children: <Widget>[
          _EditorBar(onCancel: _cancelEditing),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(TileMetrics.margin),
              child: EditableTileGrid(
                tiles: scratch,
                labelFor: widget.labelFor,
                services: widget.services,
                selected: _selected,
                onSelect: _select,
                onDelete: _delete,
                onReorder: _reorder,
              ),
            ),
          ),
          TileInspector(
            label: selectedTile == null
                ? ''
                : selectedTile.label ?? widget.labelFor(selectedTile.id),
            tile: selectedTile,
            onApply: _applyEditing,
            onSizeSelected: _resize,
            onColourSelected: _recolor,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TileMetrics.margin,
            TileMetrics.gutter,
            TileMetrics.margin,
            TileMetrics.gutter,
          ),
          child: Row(
            children: <Widget>[
              InkWell(
                onTap: _openSettings,
                child: Text(
                  Messages.settingsButton,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _addTile,
                child: Text(
                  Messages.addTile,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: AppTileGrid(
            tiles: [for (final PinnedTile p in widget.pinned) p.toTile()],
            labelFor: (Tile tile) => tile.label ?? widget.labelFor(tile.id),
            services: widget.services,
            emptyMessage: Messages.nothingPinned,
            onLaunch: widget.onLaunch,
            onLongPress: _startEditing,
            onRefresh: widget.onRefresh,
            onGesture: widget.onGesture,
          ),
        ),
        // Its own row under the grid, not laid over it: tiles that run past
        // the bottom of the screen scroll up to this line and stop, instead
        // of passing beneath the text.
        Padding(
          padding: const EdgeInsets.symmetric(vertical: TileMetrics.gutter),
          child: Center(
            child: Text(
              Messages.swipeForAllApps,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditorBar extends StatelessWidget {
  const _EditorBar({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TileMetrics.margin,
        vertical: TileMetrics.gutter,
      ),
      child: Row(
        children: <Widget>[
          InkWell(
            onTap: onCancel,
            child: Text(Messages.cancel, style: style),
          ),
        ],
      ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen({this.error = false});

  final bool error;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(TileMetrics.margin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(Messages.bootBanner, style: text.bodyMedium),
          const SizedBox(height: TileMetrics.gutter),
          Text(Messages.bootMemory, style: text.bodyMedium),
          const SizedBox(height: TileMetrics.gutter * 2),
          Text(
            error ? Messages.appListError : Messages.bootReady,
            style: text.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// The Commodore stripe, drawn as five stacked bars.
class RainbowRule extends StatelessWidget {
  const RainbowRule({super.key, this.barHeight = 3});

  final double barHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final Color color in C64.rainbow)
          Container(height: barHeight, color: color),
      ],
    );
  }
}
