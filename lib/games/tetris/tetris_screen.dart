import 'dart:async';

import 'package:android_tile_launcher/games/tetris/tetris_game.dart';
import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/tetris_board.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keys so tests can find the parts.
const Key tetrisCloseKey = ValueKey<String>('tetris-close');
const Key tetrisPauseKey = ValueKey<String>('tetris-pause');
const Key tetrisPausedKey = ValueKey<String>('tetris-paused');
const Key tetrisScoreKey = ValueKey<String>('tetris-score');
const Key tetrisLinesKey = ValueKey<String>('tetris-lines');
const Key tetrisLevelKey = ValueKey<String>('tetris-level');
const Key tetrisNextKey = ValueKey<String>('tetris-next');
const Key tetrisGameOverKey = ValueKey<String>('tetris-game-over');
const Key tetrisRestartKey = ValueKey<String>('tetris-restart');
const Key tetrisLeftKey = ValueKey<String>('tetris-left');
const Key tetrisRightKey = ValueKey<String>('tetris-right');
const Key tetrisRotateKey = ValueKey<String>('tetris-rotate');
const Key tetrisSoftDropKey = ValueKey<String>('tetris-soft-drop');
const Key tetrisHardDropKey = ValueKey<String>('tetris-hard-drop');

/// A swipe (in any direction) has to cover at least this many logical pixels
/// before it counts as a move/drop rather than noise from an otherwise
/// stationary finger.
const double _swipeThreshold = 24;

/// Opens Tetris fullscreen, like `showTextTv` does for Text TV: the system
/// bars are hidden while it's open (restored on the way out, whichever way —
/// the close button or the system back gesture), closing back to the
/// launcher rather than to another app.
Future<void> showTetris(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (BuildContext context) => const TetrisScreen(),
    ),
  );
}

class TetrisScreen extends StatefulWidget {
  const TetrisScreen({super.key});

  @override
  State<TetrisScreen> createState() => _TetrisScreenState();
}

class _TetrisScreenState extends State<TetrisScreen> {
  late TetrisGame _game;
  Offset? _dragStart;

  // No lifecycle handling of our own: FlameGame already pauses/resumes its
  // own game loop on backgrounding (`pauseWhenBackgrounded`, on by default),
  // via its own WidgetsBindingObserver — and it only reacts to a definite
  // `paused`/`resumed`, never to `inactive`. A duplicate observer here once
  // set `paused = true` on `inactive` too, which switching to immersive
  // mode (just below) can itself trigger as a transient blip on some Android
  // versions — freezing the game before the player ever saw it move.
  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
    _game = TetrisGame();
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    _game.hud.dispose();
    super.dispose();
  }

  void _restart() => setState(() => _game = TetrisGame());

  void _onPanStart(DragStartDetails details) =>
      _dragStart = details.globalPosition;

  void _onPanEnd(DragEndDetails details) {
    final Offset? start = _dragStart;
    _dragStart = null;
    if (start == null) return;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final Offset? start = _dragStart;
    if (start == null) return;
    final Offset delta = details.globalPosition - start;
    if (delta.dx.abs() > _swipeThreshold && delta.dx.abs() > delta.dy.abs()) {
      delta.dx > 0 ? _game.moveRight() : _game.moveLeft();
      _dragStart = details.globalPosition;
    } else if (delta.dy > _swipeThreshold) {
      _game.softDrop();
      _dragStart = details.globalPosition;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TileColors.canvas,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _HudRow(
              game: _game,
              onClose: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _game.rotate,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      // Not Flame's default (a repaint boundary of its own):
                      // rendering here is driven entirely by our own manual
                      // Canvas drawing inside a game loop, not Flutter
                      // widget rebuilds, and an extra boundary between the
                      // two has been known to go stale on some Android
                      // renderers — simplest to let it repaint with its
                      // ancestors instead.
                      child: GameWidget(game: _game, addRepaintBoundary: false),
                    ),
                    ValueListenableBuilder<TetrisHudState>(
                      valueListenable: _game.hud,
                      builder: (BuildContext context, TetrisHudState hud, _) {
                        if (hud.gameOver) {
                          return _GameOverOverlay(
                            score: hud.score,
                            onRestart: _restart,
                          );
                        }
                        if (hud.paused) return const _PausedOverlay();
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
            _Controls(game: _game),
          ],
        ),
      ),
    );
  }
}

class _HudRow extends StatelessWidget {
  const _HudRow({required this.game, required this.onClose});

  final TetrisGame game;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      fontFamily: kPixelFontFamily,
      fontSize: 10,
      color: TileColors.textBright,
    );
    return Padding(
      padding: const EdgeInsets.all(TileMetrics.margin),
      child: ValueListenableBuilder<TetrisHudState>(
        valueListenable: game.hud,
        builder: (BuildContext context, TetrisHudState hud, _) => Row(
          children: <Widget>[
            SizedBox(
              width: 40,
              child: PadKey(
                key: tetrisCloseKey,
                label: 'X',
                height: 32,
                fontSize: 12,
                onTap: onClose,
              ),
            ),
            const SizedBox(width: TileMetrics.gutter),
            SizedBox(
              width: 56,
              child: PadKey(
                key: tetrisPauseKey,
                label: hud.paused
                    ? Messages.tetrisResume
                    : Messages.tetrisPause,
                height: 32,
                fontSize: 10,
                onTap: hud.gameOver ? null : game.togglePause,
              ),
            ),
            const SizedBox(width: TileMetrics.margin),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    key: tetrisScoreKey,
                    '${Messages.tetrisScore} ${hud.score}',
                    style: style,
                  ),
                  Text(
                    key: tetrisLevelKey,
                    '${Messages.tetrisLevel} ${hud.level}',
                    style: style,
                  ),
                  Text(
                    key: tetrisLinesKey,
                    '${Messages.tetrisLines} ${hud.lines}',
                    style: style,
                  ),
                  _NextPreview(type: hud.next),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextPreview extends StatelessWidget {
  const _NextPreview({required this.type});

  final TetrominoType type;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: tetrisNextKey,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          Messages.tetrisNext,
          style: TextStyle(
            fontFamily: kPixelFontFamily,
            fontSize: 10,
            color: TileColors.textBright,
          ),
        ),
        const SizedBox(width: 6),
        // A fixed black backdrop, like the board's own: the J piece's blue
        // would otherwise vanish against the C64 theme's own (also blue)
        // chrome.
        Container(
          width: 18,
          height: 18,
          color: C64.black,
          padding: const EdgeInsets.all(2),
          child: ColoredBox(color: tetrominoColour(type).fill),
        ),
      ],
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.score, required this.onRestart});

  final int score;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      key: tetrisGameOverKey,
      child: ColoredBox(
        color: TileColors.canvas.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                Messages.tetrisGameOver,
                style: TextStyle(
                  fontFamily: kPixelFontFamily,
                  fontSize: 18,
                  color: TileColors.danger,
                ),
              ),
              const SizedBox(height: TileMetrics.margin),
              Text(
                '${Messages.tetrisScore} $score',
                style: TextStyle(
                  fontFamily: kPixelFontFamily,
                  fontSize: 12,
                  color: TileColors.textBright,
                ),
              ),
              const SizedBox(height: TileMetrics.margin),
              SizedBox(
                width: 160,
                child: PadKey(
                  key: tetrisRestartKey,
                  label: Messages.tetrisRestart,
                  onTap: onRestart,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PausedOverlay extends StatelessWidget {
  const _PausedOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      key: tetrisPausedKey,
      child: ColoredBox(
        color: TileColors.canvas.withValues(alpha: 0.85),
        child: Center(
          child: Text(
            Messages.tetrisPaused,
            style: TextStyle(
              fontFamily: kPixelFontFamily,
              fontSize: 18,
              color: TileColors.textBright,
            ),
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.game});

  final TetrisGame game;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TileMetrics.margin),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PadRow(
            keys: <(Widget, int)>[
              (
                _RepeatingButton(
                  buttonKey: tetrisLeftKey,
                  label: Messages.tetrisLeft,
                  onPress: game.moveLeft,
                ),
                1,
              ),
              (
                PadKey(
                  key: tetrisRotateKey,
                  label: Messages.tetrisRotate,
                  onTap: game.rotate,
                ),
                1,
              ),
              (
                _RepeatingButton(
                  buttonKey: tetrisRightKey,
                  label: Messages.tetrisRight,
                  onPress: game.moveRight,
                ),
                1,
              ),
            ],
          ),
          PadRow(
            keys: <(Widget, int)>[
              (
                _RepeatingButton(
                  buttonKey: tetrisSoftDropKey,
                  label: Messages.tetrisDrop,
                  onPress: game.softDrop,
                ),
                1,
              ),
              (
                PadKey(
                  key: tetrisHardDropKey,
                  label: Messages.tetrisHardDrop,
                  accent: true,
                  onTap: game.hardDrop,
                ),
                1,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A [PadKey] that fires [onPress] once immediately, then repeatedly while
/// held — for LEFT/RIGHT/soft-drop, which read naturally as "keep doing this
/// while I hold it" rather than a single tap-to-nudge.
class _RepeatingButton extends StatefulWidget {
  const _RepeatingButton({
    required this.buttonKey,
    required this.label,
    required this.onPress,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback onPress;

  @override
  State<_RepeatingButton> createState() => _RepeatingButtonState();
}

class _RepeatingButtonState extends State<_RepeatingButton> {
  Timer? _timer;

  void _start() {
    widget.onPress();
    _timer = Timer.periodic(
      const Duration(milliseconds: 120),
      (_) => widget.onPress(),
    );
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _start(),
      onPointerUp: (_) => _stop(),
      onPointerCancel: (_) => _stop(),
      child: PadKey(key: widget.buttonKey, label: widget.label, onTap: () {}),
    );
  }
}
