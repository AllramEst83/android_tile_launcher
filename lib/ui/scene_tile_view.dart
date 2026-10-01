import 'dart:async';

import 'package:android_tile_launcher/model/scene_animation.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Key so tests can find the art.
const Key sceneTileArtKey = ValueKey<String>('scene-tile-art');

/// The Scene tile's content: [animation]'s frames (see
/// `model/scene_animation.dart`), looping on their own timer. Unlike every
/// other live tile this is handed its content directly rather than reading
/// it from a `TileSource` via `TilePoller` — there is no platform to read,
/// `animation` comes from `LauncherSettings.sceneAnimation`, and the
/// dispatcher already rebuilds this on a change the same way the calc,
/// files and QR scanner tiles rebuild on a tap (see the architecture doc's
/// decisions log).
class SceneTileContentView extends StatefulWidget {
  const SceneTileContentView({
    super.key,
    required this.animation,
    required this.ink,
    this.onTap,
  });

  final SceneAnimation animation;
  final Color ink;
  final VoidCallback? onTap;

  @override
  State<SceneTileContentView> createState() => _SceneTileContentViewState();
}

class _SceneTileContentViewState extends State<SceneTileContentView>
    with WidgetsBindingObserver {
  int _frame = 0;
  Timer? _timer;

  static const Duration _frameDuration = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_frameDuration, (_) => setState(() => _frame++));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<List<String>> frames = framesOf(widget.animation);
    final List<String> lines = frames[_frame % frames.length];
    final Widget art = Padding(
      padding: const EdgeInsets.all(TileMetrics.gutter / 2),
      child: FittedBox(
        key: sceneTileArtKey,
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final String line in lines)
              Text(
                line,
                style: TextStyle(
                  fontFamily: kPixelFontFamily,
                  fontSize: 10,
                  height: 1.2,
                  color: widget.ink,
                ),
              ),
          ],
        ),
      ),
    );
    final VoidCallback? onTap = widget.onTap;
    if (onTap == null) return art;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: art,
    );
  }
}
