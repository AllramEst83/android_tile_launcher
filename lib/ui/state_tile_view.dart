import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// A device-state tile's content: its label, and its current [state]
/// (`[ON]`, `[VIBRATE]`, ...) large enough to read at a glance. [onTap]
/// changes it — `null` in the grid editor, where a tap selects the tile
/// instead (see `tileContent`'s `interactive`).
class StateTileContentView extends StatelessWidget {
  const StateTileContentView({
    super.key,
    required this.label,
    required this.state,
    required this.ink,
    this.onTap,
  });

  final String label;
  final String state;
  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Fill the tile: without this the body is only as wide as its text, and a
    // tap anywhere else on the tile (most of it, for a short state) is dead.
    final Widget body = SizedBox.expand(
      child: Padding(
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
            // `Flexible`, not a bare `FittedBox`: unwrapped, a non-flex child
            // of a `Column` gets loose (unbounded) constraints and never
            // actually shrinks, so a one-row-tall tile overflowed here
            // (Phase 35, caught by the same "every kind, every size" check
            // the clock tile's own one-row overflow prompted).
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  state,
                  style: TextStyle(
                    fontFamily: kPixelFontFamily,
                    fontSize: 28,
                    color: ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final VoidCallback? tap = onTap;
    if (tap == null) return body;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tap,
      child: body,
    );
  }
}
