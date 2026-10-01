import 'package:android_tile_launcher/model/scene_animation.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Key so tests can find the art.
const Key sceneTileArtKey = ValueKey<String>('scene-tile-art');

/// The Scene tile's content: [animation]'s art (see
/// `model/scene_animation.dart`), continuously and smoothly animated with
/// `flutter_animate` — an eased, forever-repeating tween per moving piece
/// (a flicker, a sway, a breath) — rather than a hand-ticked sequence of
/// discrete frames. Stateless: every effect manages its own ticker, paused
/// automatically whenever the engine isn't producing frames (backgrounded,
/// same as any other Flutter animation), so there is nothing here to start,
/// stop or dispose.
class SceneTileContentView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final Widget art = Padding(
      padding: const EdgeInsets.all(TileMetrics.gutter / 2),
      child: FittedBox(
        key: sceneTileArtKey,
        fit: BoxFit.scaleDown,
        child: switch (animation) {
          SceneAnimation.rocket => _Rocket(ink: ink),
          SceneAnimation.palmTree => _PalmTree(ink: ink),
          SceneAnimation.flower => _Flower(ink: ink),
        },
      ),
    );
    final VoidCallback? tap = onTap;
    if (tap == null) return art;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tap,
      child: art,
    );
  }
}

TextStyle _artStyle(Color ink) => TextStyle(
  fontFamily: kPixelFontFamily,
  fontSize: 10,
  height: 1.2,
  color: ink,
);

Text _art(String text, Color ink) =>
    Text(text, textAlign: TextAlign.center, style: _artStyle(ink));

/// A rocket on the pad: a static hull bobbing gently as a whole, its own
/// engine flame flickering independently underneath, and a couple of stars
/// twinkling out of phase with each other above it.
class _Rocket extends StatelessWidget {
  const _Rocket({required this.ink});

  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _art('*', ink)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fade(
                  begin: 0.15,
                  end: 1,
                  duration: 900.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(width: 18),
            _art('*', ink)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fade(
                  begin: 1,
                  end: 0.15,
                  duration: 1300.ms,
                  curve: Curves.easeInOut,
                ),
          ],
        ),
        Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _art(rocketHull.join('\n'), ink),
                _art(rocketFlame, ink)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(
                      begin: 0.8,
                      end: 1.25,
                      duration: 320.ms,
                      curve: Curves.easeInOut,
                    )
                    .fade(
                      begin: 0.7,
                      end: 1,
                      duration: 320.ms,
                      curve: Curves.easeInOut,
                    ),
              ],
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: -2,
              end: 2,
              duration: 1600.ms,
              curve: Curves.easeInOut,
            ),
      ],
    );
  }
}

/// A palm tree whose fronds and trunk sway together from the base, over a
/// shoreline drifting gently side to side underneath.
class _PalmTree extends StatelessWidget {
  const _PalmTree({required this.ink});

  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _art(palmTree.join('\n'), ink)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .rotate(
              begin: -0.02,
              end: 0.02,
              alignment: Alignment.bottomCenter,
              duration: 2200.ms,
              curve: Curves.easeInOut,
            ),
        _art(palmWaves, ink)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveX(
              begin: -3,
              end: 3,
              duration: 1800.ms,
              curve: Curves.easeInOut,
            ),
      ],
    );
  }
}

/// A flower whose head and stem sway together from the base, its bloom also
/// breathing (scaling) a little faster and independently of that sway.
class _Flower extends StatelessWidget {
  const _Flower({required this.ink});

  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _art(flowerHead, ink)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(
                      begin: 0.9,
                      end: 1.12,
                      duration: 850.ms,
                      curve: Curves.easeInOut,
                    ),
                _art(flowerStem.join('\n'), ink),
              ],
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .rotate(
              begin: -0.035,
              end: 0.035,
              alignment: Alignment.bottomCenter,
              duration: 1400.ms,
              curve: Curves.easeInOut,
            ),
        _art(flowerGround, ink),
      ],
    );
  }
}
