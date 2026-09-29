import 'package:flutter/widgets.dart';

/// A monochrome picture of flat, hard-edged blocks, drawn from a bitmap of
/// `#`/`.` rows on a 12x12 grid — no asset, no anti-aliasing (that would leave
/// hairline seams between blocks), and it takes whatever ink colour the tile
/// it sits on already uses. Shared by every small in-app icon drawn this way
/// ([WeatherIcon]'s own sky pictures, the device tile's battery/disk/memory
/// icons) rather than each keeping its own copy of the same painter.
class PixelIcon extends StatelessWidget {
  const PixelIcon({
    super.key,
    required this.rows,
    required this.size,
    required this.color,
    this.gridSize = 12,
  });

  /// The bitmap, top row first; `#` is a filled cell, anything else is empty.
  final List<String> rows;
  final double size;
  final Color color;

  /// How many cells the bitmap is wide/tall. A small icon (the device tile's,
  /// drawn well under half [WeatherIcon]'s usual size) reads better on a
  /// coarser grid than on 12 — fewer, bigger blocks rather than the same
  /// count shrunk past the point they can still be told apart.
  final int gridSize;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: PixelIconPainter(rows, color, gridSize: gridSize),
        ),
      ),
    );
  }
}

/// The [PixelIcon] painter, exposed so a widget that needs more than a fixed
/// bitmap (the battery icon's charge-level fill) can still paint in the same
/// flat, hard-edged style rather than inventing a second one.
class PixelIconPainter extends CustomPainter {
  const PixelIconPainter(this.rows, this.color, {this.gridSize = 12});

  final List<String> rows;
  final Color color;

  /// How many cells the bitmap is wide/tall; every bitmap in this app is 12,
  /// but a painter built on this one (the battery icon) may want its own.
  final int gridSize;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.shortestSide / gridSize;
    final Paint paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    for (int y = 0; y < rows.length; y++) {
      for (int x = 0; x < rows[y].length; x++) {
        if (rows[y][x] != '#') continue;
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(PixelIconPainter old) =>
      old.rows != rows || old.color != color || old.gridSize != gridSize;
}
