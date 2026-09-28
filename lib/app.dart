import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'messages.dart';
import 'services/app_repository.dart';
import 'services/grid_state.dart';
import 'services/settings_state.dart';
import 'services/tile_services.dart';
import 'ui/home_shell.dart';
import 'ui/settings_scope.dart';
import 'ui/theme.dart';

class TileLauncherApp extends StatefulWidget {
  const TileLauncherApp({
    super.key,
    required this.appRepository,
    required this.gridState,
    required this.settingsState,
    required this.services,
  });

  final AppRepository appRepository;
  final GridState gridState;
  final SettingsState settingsState;
  final TileServices services;

  @override
  State<TileLauncherApp> createState() => _TileLauncherAppState();
}

class _TileLauncherAppState extends State<TileLauncherApp> {
  @override
  void initState() {
    super.initState();
    // The palette is in place before the first frame, so nothing is drawn in
    // the wrong colours and then redrawn.
    _applyPalette();
    widget.settingsState.addListener(_settingsChanged);
  }

  @override
  void dispose() {
    widget.settingsState.removeListener(_settingsChanged);
    super.dispose();
  }

  /// Makes the palette the settings name the one the launcher draws in, and
  /// dresses the system bars to match. Says whether it changed.
  bool _applyPalette() {
    final TilePalette palette = TilePalette.of(
      widget.settingsState.settings.theme,
    );
    final bool changed = !identical(palette, TileColors.current);
    TileColors.current = palette;
    SystemChrome.setSystemUIOverlayStyle(systemUiStyleFor(palette));
    return changed;
  }

  void _settingsChanged() {
    final bool paletteChanged = _applyPalette();
    setState(() {});
    // The colours are read straight from `TileColors`, not through the widget
    // tree, so Flutter cannot tell what depends on them: after a change,
    // rebuild every widget once. Their state (scroll positions, an open sheet)
    // is kept.
    if (paletteChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _rebuildEverything(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      state: widget.settingsState,
      child: MaterialApp(
        title: Messages.appTitle,
        debugShowCheckedModeBanner: false,
        theme: tileLauncherTheme(),
        home: HomeShell(
          appRepository: widget.appRepository,
          gridState: widget.gridState,
          services: widget.services,
        ),
      ),
    );
  }
}

/// Rebuilds every widget below [context], keeping their state.
void _rebuildEverything(BuildContext context) {
  void rebuild(Element element) {
    element.markNeedsBuild();
    element.visitChildren(rebuild);
  }

  (context as Element).visitChildren(rebuild);
}
