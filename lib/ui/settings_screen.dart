import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/layout_export.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/model/wallpaper.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/services/tile_services.dart';
import 'package:android_tile_launcher/services/wallpaper_service.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keys so tests can find the parts.
const Key settingsCloseKey = ValueKey<String>('settings-close');
Key settingsKey(String name) => ValueKey<String>('settings-$name');
const Key settingsHomeStatusKey = ValueKey<String>('settings-home-status');
const Key settingsMessageKey = ValueKey<String>('settings-message');
const Key settingsAskKey = ValueKey<String>('settings-ask');
const Key settingsYesKey = ValueKey<String>('settings-yes');
const Key settingsNoKey = ValueKey<String>('settings-no');

/// Opens the settings over the whole screen, like the Text TV viewer: a close
/// key on top, then the theme, the grid, the gestures, the Home-app shortcut,
/// and the layout (export, import, clear) and reset.
Future<void> showSettings(
  BuildContext context, {
  required SettingsState settings,
  required GridState gridState,
  required TileServices services,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (BuildContext context) => SettingsScreen(
        settings: settings,
        gridState: gridState,
        services: services,
      ),
    ),
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.gridState,
    required this.services,
  });

  final SettingsState settings;
  final GridState gridState;
  final TileServices services;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool? _isHome;
  bool _homeKnown = false;

  // A change that cannot be taken back asks first: what it will do, and the
  // action to run on YES.
  String? _ask;
  Future<void> Function()? _onYes;

  String? _message;

  // Which section the current question and message belong to, so each shows
  // under the keys that raised it.
  String _where = 'layout';

  // The wallpaper picture and screen picked but not yet set. The picture
  // follows the theme until one is chosen.
  ThemeVariant? _paperTheme;
  WallpaperTarget _paperTarget = WallpaperTarget.lock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkHome();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Coming back from Android's Home app page, show what was chosen there.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkHome();
  }

  Future<void> _checkHome() async {
    final bool? isHome = await widget.services.homeRole.isDefault();
    if (!mounted) return;
    setState(() {
      _isHome = isHome;
      _homeKnown = true;
    });
  }

  LauncherSettings get _current => widget.settings.settings;

  void _change(LauncherSettings next) {
    setState(() => _message = null);
    widget.settings.update(next);
  }

  void _askThen(
    String question,
    Future<void> Function() action, {
    String where = 'layout',
  }) => setState(() {
    _where = where;
    _ask = question;
    _onYes = action;
    _message = null;
  });

  void _dismissAsk() => setState(() {
    _ask = null;
    _onYes = null;
  });

  Future<void> _confirmed() async {
    final Future<void> Function()? action = _onYes;
    _dismissAsk();
    if (action != null) await action();
  }

  Future<void> _export() async {
    _where = 'layout';
    final String text = exportLayout(
      tiles: widget.gridState.pinned,
      settings: _current,
    );
    final bool ok = await widget.services.clipboard.write(text);
    if (!mounted) return;
    setState(() {
      _message = ok
          ? Messages.settingsExported(widget.gridState.pinned.length)
          : '${Messages.failedPrefix}${Messages.settingsClipboardRefused}';
    });
  }

  Future<void> _import() async {
    _where = 'layout';
    final String? text = await widget.services.clipboard.read();
    if (!mounted) return;
    final LayoutImport parsed = parseLayout(text);
    switch (parsed) {
      case LayoutRejected(:final String reason):
        setState(
          () => _message = '${Messages.failedPrefix}${reason.toUpperCase()}',
        );
      case LayoutImported(:final tiles, :final settings, :final int skipped):
        _askThen(Messages.settingsImportAsk(tiles.length, skipped), () async {
          await widget.gridState.replaceAll(tiles);
          await widget.settings.update(settings);
          if (!mounted) return;
          setState(() => _message = Messages.settingsImported(tiles.length));
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TileColors.canvas,
      body: Column(
        children: <Widget>[
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(TileMetrics.gutter),
              child: Row(
                children: <Widget>[
                  PadKey(
                    key: settingsCloseKey,
                    label: 'X',
                    height: 48,
                    fontSize: 12,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: TileMetrics.margin),
                  Text(
                    Messages.settingsTitle,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.settings,
              builder: (BuildContext context, Widget? _) =>
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      TileMetrics.margin,
                      0,
                      TileMetrics.margin,
                      TileMetrics.margin,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _themeSection(),
                        _gridSection(),
                        _gestureSection(),
                        _feelSection(),
                        _wallpaperSection(),
                        _systemSection(),
                        _layoutSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // --- sections ------------------------------------------------------------

  Widget _themeSection() {
    return _Section(
      title: Messages.settingsTheme,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (final ThemeVariant variant in ThemeVariant.values)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: variant == ThemeVariant.values.last ? 0 : 4,
                  ),
                  child: _ThemeChip(
                    key: settingsKey('theme-${variant.name}'),
                    variant: variant,
                    selected: _current.theme == variant,
                    onTap: () => _change(_current.copyWith(theme: variant)),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _gridSection() {
    return _Section(
      title: Messages.settingsGrid,
      children: <Widget>[
        _Label(text: Messages.settingsColumns),
        _Choices<int>(
          values: LauncherSettings.columnChoices,
          selected: _current.columns,
          labelOf: (int c) => '$c',
          keyOf: (int c) => settingsKey('columns-$c'),
          onSelect: (int c) => _change(_current.copyWith(columns: c)),
        ),
        _Label(text: Messages.settingsGap),
        _Choices<GridGap>(
          values: GridGap.values,
          selected: _current.gap,
          labelOf: (GridGap g) => g.label,
          keyOf: (GridGap g) => settingsKey('gap-${g.name}'),
          onSelect: (GridGap g) => _change(_current.copyWith(gap: g)),
        ),
      ],
    );
  }

  Widget _gestureSection() {
    return _Section(
      title: Messages.settingsGestures,
      children: <Widget>[
        const _Note(text: Messages.settingsSwipeLeft),
        _Label(text: Messages.settingsSwipeDown),
        _Choices<GestureAction>(
          values: LauncherSettings.swipeDownChoices,
          selected: _current.swipeDown,
          labelOf: (GestureAction a) => a.label,
          keyOf: (GestureAction a) => settingsKey('down-${a.name}'),
          onSelect: (GestureAction a) =>
              _change(_current.copyWith(swipeDown: a)),
        ),
        const _Note(text: Messages.settingsSwipeDownNote),
        _Label(text: Messages.settingsSwipeUp),
        _Choices<GestureAction>(
          values: LauncherSettings.swipeUpChoices,
          selected: _current.swipeUp,
          labelOf: (GestureAction a) => a.label,
          keyOf: (GestureAction a) => settingsKey('up-${a.name}'),
          onSelect: (GestureAction a) => _change(_current.copyWith(swipeUp: a)),
        ),
        const _Note(text: Messages.settingsSwipeUpNote),
      ],
    );
  }

  Widget _feelSection() {
    return _Section(
      title: Messages.settingsFeel,
      children: <Widget>[
        _Label(text: Messages.settingsHaptics),
        _Choices<bool>(
          values: const <bool>[true, false],
          selected: _current.haptics,
          labelOf: (bool on) => on ? Messages.settingsOn : Messages.settingsOff,
          keyOf: (bool on) => settingsKey('haptics-${on ? 'on' : 'off'}'),
          onSelect: (bool on) => _change(_current.copyWith(haptics: on)),
        ),
        const _Note(text: Messages.settingsHapticsNote),
      ],
    );
  }

  Widget _wallpaperSection() {
    final ThemeVariant paper = _paperTheme ?? _current.theme;
    final WallpaperTarget target = _paperTarget;
    return _Section(
      title: Messages.settingsWallpaper,
      children: <Widget>[
        _Label(text: Messages.settingsPicture),
        _Choices<ThemeVariant>(
          values: ThemeVariant.values,
          selected: paper,
          labelOf: (ThemeVariant v) => v.label,
          keyOf: (ThemeVariant v) => settingsKey('paper-${v.name}'),
          onSelect: (ThemeVariant v) => setState(() => _paperTheme = v),
        ),
        _Label(text: Messages.settingsPutOn),
        _Choices<WallpaperTarget>(
          values: WallpaperTarget.values,
          selected: target,
          labelOf: (WallpaperTarget t) => t.label,
          keyOf: (WallpaperTarget t) => settingsKey('paper-on-${t.name}'),
          onSelect: (WallpaperTarget t) => setState(() => _paperTarget = t),
        ),
        const _Note(text: Messages.settingsWallpaperHomeNote),
        const SizedBox(height: TileMetrics.margin),
        Center(
          child: _WallpaperPreview(
            key: settingsKey('paper-preview'),
            asset: wallpaperAssetOf(paper),
          ),
        ),
        const SizedBox(height: TileMetrics.margin),
        Row(
          children: <Widget>[
            Expanded(
              child: PadKey(
                key: settingsKey('set-wallpaper'),
                label: Messages.settingsSetWallpaper,
                height: 44,
                fontSize: 10,
                onTap: () => _askThen(
                  Messages.settingsWallpaperAsk(paper.label, target.phrase),
                  () => _setWallpaper(paper, target),
                  where: 'wallpaper',
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: PadKey(
                key: settingsKey('default-wallpaper'),
                label: Messages.settingsDefaultWallpaper,
                height: 44,
                fontSize: 10,
                accent: true,
                onTap: () => _askThen(
                  Messages.settingsWallpaperClearAsk(target.phrase),
                  () => _clearWallpaper(target),
                  where: 'wallpaper',
                ),
              ),
            ),
          ],
        ),
        ..._feedback('wallpaper'),
      ],
    );
  }

  Future<void> _setWallpaper(ThemeVariant paper, WallpaperTarget target) async {
    final Uint8List image;
    try {
      final ByteData data = await rootBundle.load(wallpaperAssetOf(paper));
      image = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } on Object {
      _wallpaperSays(WallpaperResult.failed, Messages.settingsWallpaperSet);
      return;
    }
    final WallpaperResult result = await widget.services.wallpaper.set(
      image,
      target,
    );
    _wallpaperSays(result, Messages.settingsWallpaperSet);
  }

  Future<void> _clearWallpaper(WallpaperTarget target) async {
    final WallpaperResult result = await widget.services.wallpaper.clear(
      target,
    );
    _wallpaperSays(result, Messages.settingsWallpaperCleared);
  }

  void _wallpaperSays(WallpaperResult result, String done) {
    if (!mounted) return;
    setState(() {
      _where = 'wallpaper';
      _message = switch (result) {
        WallpaperResult.done => done,
        WallpaperResult.refused =>
          '${Messages.failedPrefix}${Messages.settingsWallpaperRefused}',
        WallpaperResult.failed =>
          '${Messages.failedPrefix}${Messages.settingsWallpaperFailed}',
      };
    });
  }

  Widget _systemSection() {
    final String status = !_homeKnown
        ? Messages.settingsHomeChecking
        : switch (_isHome) {
            true => Messages.settingsHomeActive,
            false => Messages.settingsHomeNotSet,
            null => Messages.settingsHomeUnknown,
          };
    return _Section(
      title: Messages.settingsSystem,
      children: <Widget>[
        _Label(text: Messages.settingsHomeApp),
        Text(
          status,
          key: settingsHomeStatusKey,
          style: TextStyle(
            fontFamily: kPixelFontFamily,
            fontSize: 12,
            color: _isHome == true ? TileColors.accent : TileColors.textBright,
          ),
        ),
        const SizedBox(height: TileMetrics.gutter),
        PadKey(
          key: settingsKey('open-home'),
          label: Messages.settingsOpenHome,
          height: 44,
          fontSize: 10,
          onTap: () => widget.services.homeRole.openSettings(),
        ),
      ],
    );
  }

  /// The question waiting for YES or NO, and the last message, when they
  /// belong to section [where].
  List<Widget> _feedback(String where) {
    if (_where != where) return const <Widget>[];
    final String? ask = _ask;
    final String? message = _message;
    return <Widget>[
      if (ask != null) ...<Widget>[
        const SizedBox(height: TileMetrics.margin),
        Text(
          ask,
          key: settingsAskKey,
          style: TextStyle(
            fontFamily: kPixelFontFamily,
            fontSize: 10,
            color: TileColors.highlight,
          ),
        ),
        const SizedBox(height: TileMetrics.gutter),
        Row(
          children: <Widget>[
            Expanded(
              child: PadKey(
                key: settingsYesKey,
                label: Messages.mailYes,
                height: 44,
                fontSize: 12,
                onTap: _confirmed,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: PadKey(
                key: settingsNoKey,
                label: Messages.mailNo,
                height: 44,
                fontSize: 12,
                onTap: _dismissAsk,
              ),
            ),
          ],
        ),
      ],
      if (message != null) ...<Widget>[
        const SizedBox(height: TileMetrics.margin),
        Text(
          message,
          key: settingsMessageKey,
          style: TextStyle(
            fontFamily: kPixelFontFamily,
            fontSize: 10,
            color: TileColors.accent,
          ),
        ),
      ],
    ];
  }

  Widget _layoutSection() {
    return _Section(
      title: Messages.settingsLayout,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: PadKey(
                key: settingsKey('export'),
                label: Messages.settingsExport,
                height: 44,
                fontSize: 10,
                onTap: _export,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: PadKey(
                key: settingsKey('import'),
                label: Messages.settingsImport,
                height: 44,
                fontSize: 10,
                onTap: _import,
              ),
            ),
          ],
        ),
        const _Note(text: Messages.settingsExportNote),
        const SizedBox(height: TileMetrics.gutter),
        Row(
          children: <Widget>[
            Expanded(
              child: PadKey(
                key: settingsKey('clear-layout'),
                label: Messages.settingsClearLayout,
                height: 44,
                fontSize: 10,
                accent: true,
                onTap: () => _askThen(
                  Messages.settingsClearAsk(widget.gridState.pinned.length),
                  () => widget.gridState.replaceAll(const []),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: PadKey(
                key: settingsKey('reset-settings'),
                label: Messages.settingsResetSettings,
                height: 44,
                fontSize: 10,
                accent: true,
                onTap: () =>
                    _askThen(Messages.settingsResetAsk, widget.settings.reset),
              ),
            ),
          ],
        ),
        ..._feedback('layout'),
      ],
    );
  }
}

/// The picture, in a phone-shaped frame, as it would fill the screen.
class _WallpaperPreview extends StatelessWidget {
  const _WallpaperPreview({super.key, required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      decoration: BoxDecoration(
        border: Border.all(color: TileColors.bezel, width: TileMetrics.bevel),
      ),
      child: AspectRatio(
        aspectRatio: 9 / 20,
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          // The picture is 1290 pixels wide; the preview is 108 dp.
          cacheWidth: 216,
          errorBuilder: (BuildContext context, Object error, StackTrace? _) =>
              Center(
                child: Text(
                  Messages.settingsPictureMissing,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
        ),
      ),
    );
  }
}

/// A heading with a rule under it, and what belongs to it.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: TileMetrics.margin * 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontFamily: kPixelFontFamily,
              fontSize: 12,
              color: TileColors.textBright,
            ),
          ),
          const SizedBox(height: 4),
          Container(height: 2, color: TileColors.bezel),
          const SizedBox(height: TileMetrics.gutter),
          ...children,
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: kPixelFontFamily,
          fontSize: 8,
          color: TileColors.muted,
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: kPixelFontFamily,
          fontSize: 8,
          color: TileColors.textDim,
          height: 1.5,
        ),
      ),
    );
  }
}

/// A row of keys, one of which is chosen.
class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.keyOf,
    required this.onSelect,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final Key Function(T value) keyOf;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: <Widget>[
        for (final T value in values)
          PadKey(
            key: keyOf(value),
            label: labelOf(value),
            selected: value == selected,
            height: 44,
            fontSize: 10,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            onTap: () => onSelect(value),
          ),
      ],
    );
  }
}

/// A theme's key, drawn in that theme's own colours so it shows what it is.
class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    super.key,
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  final ThemeVariant variant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TilePalette palette = TilePalette.of(variant);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.canvas,
          border: Border.all(
            color: selected ? TileColors.highlight : palette.bezel,
            width: selected ? TileMetrics.bevel * 2 : TileMetrics.bevel,
          ),
        ),
        child: Text(
          variant.label,
          style: TextStyle(
            fontFamily: kPixelFontFamily,
            fontSize: 12,
            color: palette.textBright,
          ),
        ),
      ),
    );
  }
}
