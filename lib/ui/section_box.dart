import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// A bordered group, boxed like a tile so its members read as one unit and
/// the gap to the next group reads as a real gap, not just more text — the
/// same bevel this app already draws around every tile, reused here instead
/// of a plain rule under a heading. Introduced for the settings screen
/// (Phase 34) and shared with the help screen (Phase 40) rather than each
/// keeping its own copy of the same look.
class SectionBox extends StatelessWidget {
  const SectionBox({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: TileMetrics.margin * 2),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: TileColors.bezel, width: TileMetrics.bevel),
        ),
        padding: const EdgeInsets.all(TileMetrics.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(width: 4, height: 14, color: TileColors.accent),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: kPixelFontFamily,
                    fontSize: 12,
                    letterSpacing: 1,
                    color: TileColors.textBright,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TileMetrics.gutter),
            ...children,
          ],
        ),
      ),
    );
  }
}
