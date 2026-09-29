import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// The small extra touches on a tile, drawn over it and never taking a touch:
/// faint CRT scanlines across the whole face, a hard-edged shine along the lit
/// top and left edges, and a dithered strip of shade along the dark bottom and
/// right ones, the way a C64 picture faked a soft shadow with a checkerboard.
/// All flat, square-edged shapes in one or two alphas of white and black:
/// nothing blurred, no gradient.
///
/// [sunk] is a pressed tile: the light and dark sides swap, so the shine goes
/// and the shade moves to the top and left. [outlined] is a tile selected in
/// the grid editor (a plain outline, no bevel): scanlines only.
class TileGloss extends StatelessWidget {
  const TileGloss({super.key, this.sunk = false, this.outlined = false});

  final bool sunk;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: TileGlossPainter(sunk: sunk, outlined: outlined),
          ),
        ),
      ),
    );
  }
}

class TileGlossPainter extends CustomPainter {
  const TileGlossPainter({required this.sunk, required this.outlined});

  final bool sunk;
  final bool outlined;

  // Phase 38 ("lean further into the C64 look"): sharper, closer-set
  // scanlines, a more pronounced shine, and the dithered shade nudged up to
  // match it — bolder throughout, not just the one line the user named.

  /// A scanline every this many pixels, one pixel thick.
  static const double scanlineEvery = 3;
  static const double scanlineAlpha = 0.09;

  /// The shine: how far in from the bevel, how thick, and its longest run.
  static const double shineInset = 1;
  static const double shineThickness = 3;
  static const double shineLength = 44;
  static const double shineAlpha = 0.42;

  /// The dithered shade: a strip this deep of squares this big.
  static const double ditherDepth = 4;
  static const double ditherCell = 2;
  static const double ditherAlpha = 0.24;

  /// The plain outline of a selected tile (matches `TileView`).
  static const double outline = TileMetrics.bevel * 2;

  @override
  void paint(Canvas canvas, Size size) {
    const double light = TileMetrics.tileBevelLight;
    const double dark = TileMetrics.tileBevelDark;
    final double topLeft = outlined ? outline : (sunk ? dark : light);
    final double bottomRight = outlined ? outline : (sunk ? light : dark);
    final Rect inner = Rect.fromLTRB(
      topLeft,
      topLeft,
      size.width - bottomRight,
      size.height - bottomRight,
    );
    if (inner.width <= 0 || inner.height <= 0) return;
    canvas.save();
    canvas.clipRect(inner);

    final Paint black = Paint()..color = const Color(0xFF000000);
    final Paint white = Paint()..color = const Color(0xFFFFFFFF);

    // Scanlines.
    black.color = black.color.withValues(alpha: scanlineAlpha);
    for (double y = inner.top; y < inner.bottom; y += scanlineEvery) {
      canvas.drawRect(Rect.fromLTWH(inner.left, y, inner.width, 1), black);
    }

    if (!outlined) {
      if (!sunk) {
        // An L of light just inside the lit edges.
        white.color = white.color.withValues(alpha: shineAlpha);
        final double across = _shine(inner.width);
        final double down = _shine(inner.height);
        final double x = inner.left + shineInset;
        final double y = inner.top + shineInset;
        canvas.drawRect(Rect.fromLTWH(x, y, across, shineThickness), white);
        canvas.drawRect(Rect.fromLTWH(x, y, shineThickness, down), white);
      }
      // A checkerboard of shade just inside the dark edges: bottom and right,
      // or top and left when pressed.
      black.color = black.color.withValues(alpha: ditherAlpha);
      if (sunk) {
        _dither(
          canvas,
          black,
          Rect.fromLTWH(inner.left, inner.top, inner.width, ditherDepth),
        );
        _dither(
          canvas,
          black,
          Rect.fromLTWH(inner.left, inner.top, ditherDepth, inner.height),
        );
      } else {
        _dither(
          canvas,
          black,
          Rect.fromLTWH(
            inner.left,
            inner.bottom - ditherDepth,
            inner.width,
            ditherDepth,
          ),
        );
        _dither(
          canvas,
          black,
          Rect.fromLTWH(
            inner.right - ditherDepth,
            inner.top,
            ditherDepth,
            inner.height,
          ),
        );
      }
    }
    canvas.restore();
  }

  double _shine(double extent) =>
      (extent * 0.45).clamp(0, shineLength).toDouble();

  void _dither(Canvas canvas, Paint paint, Rect strip) {
    // Squares on a grid anchored to the strip's own corner, on the checker
    // pattern (every other square, offset on alternate rows).
    final int cols = (strip.width / ditherCell).ceil();
    final int rows = (strip.height / ditherCell).ceil();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if ((r + c).isOdd) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            strip.left + c * ditherCell,
            strip.top + r * ditherCell,
            ditherCell,
            ditherCell,
          ).intersect(strip),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(TileGlossPainter old) =>
      old.sunk != sunk || old.outlined != outlined;
}
