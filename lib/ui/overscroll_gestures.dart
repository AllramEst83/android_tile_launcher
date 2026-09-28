import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Turns a long drag past the end of a scrollable into an action: past the top
/// is [onPullDown], past the bottom is [onPushUp]. Each drag fires at most
/// once, when it has gone [threshold] logical pixels beyond the edge, with a
/// short tick so the finger knows it registered.
///
/// Only a finger that began at the edge counts: the tail of a fling that runs
/// into the edge does not, and neither does a long swipe that scrolls the
/// content all the way up and carries on, or every quick trip back to the top
/// would pull the shade down. Notifications are
/// never consumed, so scrolling (and a [RefreshIndicator] above) behave as
/// they would without this.
class OverscrollGestures extends StatefulWidget {
  const OverscrollGestures({
    super.key,
    required this.child,
    this.onPullDown,
    this.onPushUp,
    this.threshold = defaultThreshold,
  });

  static const double defaultThreshold = 72;

  final Widget child;
  final VoidCallback? onPullDown;
  final VoidCallback? onPushUp;
  final double threshold;

  @override
  State<OverscrollGestures> createState() => _OverscrollGesturesState();
}

class _OverscrollGesturesState extends State<OverscrollGestures> {
  double _pulled = 0;
  bool _fired = false;
  bool _startedAtTop = false;
  bool _startedAtBottom = false;

  bool _onNotification(ScrollNotification notification) {
    // The scrollable's own axis only: a horizontal one nested inside is not a
    // swipe up or down.
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is ScrollStartNotification) {
      _pulled = 0;
      _fired = false;
      _startedAtTop = notification.metrics.extentBefore <= 0;
      _startedAtBottom = notification.metrics.extentAfter <= 0;
    } else if (notification is ScrollEndNotification) {
      _pulled = 0;
      _fired = false;
      _startedAtTop = false;
      _startedAtBottom = false;
    } else if (notification is OverscrollNotification &&
        notification.dragDetails != null &&
        !_fired) {
      _pulled += notification.overscroll;
      if (_pulled <= -widget.threshold && _startedAtTop) {
        _fire(widget.onPullDown);
      } else if (_pulled >= widget.threshold && _startedAtBottom) {
        _fire(widget.onPushUp);
      }
    } else if (notification is ScrollUpdateNotification) {
      // Back inside the content: the drag is not an overscroll any more.
      _pulled = 0;
    }
    return false;
  }

  void _fire(VoidCallback? action) {
    if (action == null) return;
    _fired = true;
    HapticFeedback.selectionClick();
    action();
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: _onNotification,
        child: widget.child,
      );
}
