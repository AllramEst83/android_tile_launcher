import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'messages.dart';
import 'services/app_repository.dart';
import 'services/first_run.dart';
import 'services/grid_state.dart';
import 'services/launch_stats.dart';
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
    this.firstRun,
    this.launchStats,
  });

  final AppRepository appRepository;
  final GridState gridState;
  final SettingsState settingsState;
  final TileServices services;
  final FirstRun? firstRun;
  final LaunchStats? launchStats;

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
        // A multiplier on whatever the phone's own accessibility text size
        // already asks for, not a replacement of it: the FONT SIZE setting
        // never takes away a scale the user already relies on.
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: _scaledBy(
              MediaQuery.textScalerOf(context),
              widget.settingsState.settings.fontScale.factor,
            ),
          ),
          child: child!,
        ),
        home: HomeShell(
          appRepository: widget.appRepository,
          gridState: widget.gridState,
          services: widget.services,
          firstRun: widget.firstRun,
          launchStats: widget.launchStats,
        ),
      ),
    );
  }
}

/// [ambient] scaled again by [factor]: every text style in the app reads its
/// size through Flutter's ambient text scaler somewhere along the way (`Text`
/// by default, or a manual `TextPainter` that was written to ask for it, as
/// `TvRow` and a few tile content views do for a Text TV page's fixed grid),
/// so overriding it once here is enough to reach all of them.
TextScaler _scaledBy(TextScaler ambient, double factor) =>
    _ScaledTextScaler(ambient, factor);

class _ScaledTextScaler extends TextScaler {
  const _ScaledTextScaler(this._ambient, this._factor);

  final TextScaler _ambient;
  final double _factor;

  @override
  double scale(double fontSize) => _ambient.scale(fontSize) * _factor;

  @override
  double get textScaleFactor => scale(1);

  @override
  bool operator ==(Object other) =>
      other is _ScaledTextScaler &&
      other._ambient == _ambient &&
      other._factor == _factor;

  @override
  int get hashCode => Object.hash(_ambient, _factor);
}

/// Rebuilds every widget below [context], keeping their state.
void _rebuildEverything(BuildContext context) {
  void rebuild(Element element) {
    element.markNeedsBuild();
    element.visitChildren(rebuild);
  }

  (context as Element).visitChildren(rebuild);
}
