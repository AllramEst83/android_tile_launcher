import 'package:android_tile_launcher/ui/press_listener.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// A key in the launcher's own look, for the bar along the top of home: a fill
/// a shade off the screen colour, a lit bevel top and left and a thicker
/// shaded one bottom and right, like a tile, and the label in the bright ink.
/// It sinks while pressed, exactly as a tile does (see [PressListener]).
///
/// Sized by its parent: [height] tall, as wide as it is given. A `null`
/// [onTap] greys it.
class BevelKey extends StatelessWidget {
  const BevelKey({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 44,
    this.fontSize = 10,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;

  /// A key's bevel: a little finer than a tile's, which it sits above.
  static const double lit = 2;
  static const double shaded = 4;

  /// How long the bevel takes to flip.
  static const Duration pressDuration = Duration(milliseconds: 60);

  @override
  Widget build(BuildContext context) {
    final Color fill = Color.lerp(TileColors.canvas, TileColors.text, 0.22)!;
    final Color light = Color.lerp(fill, TileColors.textBright, 0.35)!;
    final Color dark = Color.lerp(fill, const Color(0xFF000000), 0.35)!;
    final Color ink = onTap == null
        ? TileColors.textDim
        : TileColors.textBright;
    return PressListener(
      hasTap: onTap != null,
      builder: (BuildContext context, bool pressed) {
        final Color topLeft = pressed ? dark : light;
        final Color bottomRight = pressed ? light : dark;
        final double topLeftWidth = pressed ? shaded : lit;
        final double bottomRightWidth = pressed ? lit : shaded;
        return InkWell(
          onTap: onTap,
          // The press is drawn by the bevel, and ticked by PressListener.
          enableFeedback: false,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: pressDuration,
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              border: Border(
                top: BorderSide(color: topLeft, width: topLeftWidth),
                left: BorderSide(color: topLeft, width: topLeftWidth),
                right: BorderSide(color: bottomRight, width: bottomRightWidth),
                bottom: BorderSide(color: bottomRight, width: bottomRightWidth),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: kPixelFontFamily,
                fontSize: fontSize,
                color: ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}
