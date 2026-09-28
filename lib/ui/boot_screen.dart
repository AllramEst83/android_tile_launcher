import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// The blinking block after the last typed character.
const Key bootCursorKey = Key('boot-cursor');

/// What the launcher shows while it loads: a C64 power-on screen. Plain (the
/// banner, the memory line, READY.) on every start but the first; with
/// [animate] the same text is typed out a character at a time, followed by a
/// `LOAD "HOME",8` and a `RUN`, with a blinking block cursor, and [onDone]
/// fires once it has finished (a tap finishes it early). With [error] it says
/// the app list could not be read instead of READY.
class BootScreen extends StatefulWidget {
  const BootScreen({
    super.key,
    this.error = false,
    this.animate = false,
    this.onDone,
  });

  final bool error;
  final bool animate;
  final VoidCallback? onDone;

  /// The lines of the first-run show; an empty one is a blank line.
  static const List<String> script = <String>[
    Messages.bootBanner,
    '',
    Messages.bootMemory,
    '',
    Messages.bootReady,
    Messages.bootLoad,
    Messages.bootSearching,
    Messages.bootLoading,
    Messages.bootReady,
    Messages.bootRun,
  ];

  /// Time for one character to appear.
  static const Duration perCharacter = Duration(milliseconds: 28);

  /// Time the finished screen (with its blinking cursor) stays up, in
  /// characters' worth of time, before [onDone].
  static const int holdCharacters = 24;

  /// How often the cursor flips.
  static const Duration blink = Duration(milliseconds: 350);

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen>
    with SingleTickerProviderStateMixin {
  late final int _total = BootScreen.script.fold<int>(
    0,
    (int sum, String line) => sum + line.length,
  );
  late final Duration _duration =
      BootScreen.perCharacter * (_total + BootScreen.holdCharacters);
  AnimationController? _controller;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    if (!widget.animate) return;
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) _finish();
      })
      ..forward();
  }

  @override
  void didUpdateWidget(BootScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The same screen can turn into the error one while the show is on; the
    // show must then stop, not finish later and report itself seen.
    if (oldWidget.animate && !widget.animate) _controller?.stop();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone?.call();
  }

  /// The script with only the first [shown] characters typed, as lines.
  List<String> _typed(int shown) {
    final List<String> lines = <String>[];
    int left = shown;
    for (final String line in BootScreen.script) {
      if (left <= 0) break;
      final int take = left < line.length ? left : line.length;
      lines.add(line.substring(0, take));
      left -= line.length;
    }
    // Before the first character there is still the cursor, on an empty line.
    if (lines.isEmpty) lines.add('');
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium;
    final AnimationController? controller = _controller;
    if (controller == null || !widget.animate) return _plain(style);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? _) {
          final Duration elapsed = _duration * controller.value;
          final int shown =
              (elapsed.inMilliseconds / BootScreen.perCharacter.inMilliseconds)
                  .floor()
                  .clamp(0, _total);
          final List<String> lines = _typed(shown);
          final bool cursorOn =
              (elapsed.inMilliseconds ~/ BootScreen.blink.inMilliseconds)
                  .isEven ||
              shown < _total;
          return Padding(
            padding: const EdgeInsets.all(TileMetrics.margin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final (int i, String line) in lines.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: TileMetrics.gutter),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          child: Text(line.isEmpty ? ' ' : line, style: style),
                        ),
                        // The block sits after the last typed character. Drawn,
                        // not a glyph: the pixel font has no block character.
                        if (i == lines.length - 1 && cursorOn)
                          Container(
                            key: bootCursorKey,
                            width: (style?.fontSize ?? 12) * 0.9,
                            height: style?.fontSize ?? 12,
                            margin: const EdgeInsets.only(left: 2),
                            color: TileColors.textBright,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _plain(TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.all(TileMetrics.margin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(Messages.bootBanner, style: style),
          const SizedBox(height: TileMetrics.gutter),
          Text(Messages.bootMemory, style: style),
          const SizedBox(height: TileMetrics.gutter * 2),
          Text(
            widget.error ? Messages.appListError : Messages.bootReady,
            style: style,
          ),
        ],
      ),
    );
  }
}
