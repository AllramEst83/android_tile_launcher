import 'dart:async';

import 'package:android_tile_launcher/ui/haptics.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Tells its [builder] whether to *look* pressed, for anything that sinks like
/// a key when touched (a tile, a header key), and gives a tap its tick.
///
/// A touch is not a press until it proves it is one. The look comes on only
/// once the finger has rested for [showAfter] without moving [visualSlop], so a
/// finger that lands and goes on to scroll never sinks anything. A quick tap
/// that is over before then still sinks for a moment when it lets go
/// ([flashFor]), so it is seen to register. The finger is read from the raw
/// pointer, not the tap recogniser, so a child that takes the tap itself (a
/// toggle) still sinks; [builder] is given `pressed` only for the look, never
/// for deciding what a tap does.
///
/// A release is a tap, and ticks (`Haptic.tap`, unless haptics are off in
/// settings), when the finger stayed within touch slop and was not held long
/// enough to be a long-press, and [hasTap] is true.
class PressListener extends StatefulWidget {
  const PressListener({super.key, required this.builder, this.hasTap = true});

  final Widget Function(BuildContext context, bool pressed) builder;

  /// Whether a tap here does anything, and so deserves its tick.
  final bool hasTap;

  /// How long a finger rests before the look comes on.
  static const Duration showAfter = Duration(milliseconds: 90);

  /// How far a finger may move and still look pressed: well under touch slop,
  /// so a scroll that has only just begun lets go at once.
  static const double visualSlop = 8;

  /// How long a tap that never showed its press shows it on release.
  static const Duration flashFor = Duration(milliseconds: 90);

  @override
  State<PressListener> createState() => _PressListenerState();
}

class _PressListenerState extends State<PressListener> {
  bool _pressed = false;
  bool _moved = false;
  bool _longHeld = false;
  Offset _down = Offset.zero;
  Timer? _showTimer;
  Timer? _longTimer;
  Timer? _flashTimer;

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    _showTimer?.cancel();
    _longTimer?.cancel();
    _flashTimer?.cancel();
  }

  void _setPressed(bool pressed) {
    // A dragged tile is taken out of the tree while its pointer is still
    // down, so a later event can arrive after dispose.
    if (!mounted || _pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  void _onDown(PointerDownEvent event) {
    _cancelTimers();
    _down = event.position;
    _moved = false;
    _longHeld = false;
    _showTimer = Timer(PressListener.showAfter, () => _setPressed(true));
    _longTimer = Timer(kLongPressTimeout, () => _longHeld = true);
  }

  void _onMove(PointerMoveEvent event) {
    final double away = (event.position - _down).distance;
    if (away > PressListener.visualSlop) {
      _showTimer?.cancel();
      _setPressed(false);
    }
    if (away > kTouchSlop) _moved = true;
  }

  void _onUp(PointerUpEvent event) {
    final bool tapped = widget.hasTap && !_moved && !_longHeld;
    final bool showing = _pressed;
    _cancelTimers();
    if (tapped && mounted) haptic(context, Haptic.tap);
    if (tapped && !showing) {
      // Over before it looked pressed: show it now, briefly.
      _setPressed(true);
      _flashTimer = Timer(PressListener.flashFor, () => _setPressed(false));
    } else {
      _setPressed(false);
    }
  }

  void _onCancel(PointerCancelEvent event) {
    _cancelTimers();
    _setPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onUp,
      onPointerCancel: _onCancel,
      child: widget.builder(context, _pressed),
    );
  }
}
