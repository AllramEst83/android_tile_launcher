import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// A toggle tile's content: its label, and `[ON]`/`[OFF]` large enough to
/// read at a glance. [onToggle] flips it on tap — `null` in the grid editor,
/// where a tap selects the tile instead (see `tileContent`'s `interactive`).
class ToggleTileContentView extends StatelessWidget {
  const ToggleTileContentView({
    super.key,
    required this.label,
    required this.on,
    required this.ink,
    this.onToggle,
  });

  final String label;
  final bool on;
  final Color ink;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final Widget body = Padding(
      padding: const EdgeInsets.all(TileMetrics.gutter / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontFamily: kPixelFontFamily,
              fontSize: 10,
              color: ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              on ? '[ON]' : '[OFF]',
              style: TextStyle(
                fontFamily: kPixelFontFamily,
                fontSize: 28,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
    final VoidCallback? tap = onToggle;
    if (tap == null) return body;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tap,
      child: body,
    );
  }
}
