import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/ui/file_icons.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// The files tile's content: its name, a folder picture, and on a larger tile
/// what it's for. A tap ([onTap]) opens the file explorer; `null` in the grid
/// editor, where a tap selects the tile. There is nothing to read from the
/// outside world, so it never changes.
class FilesTileContentView extends StatelessWidget {
  const FilesTileContentView({super.key, required this.ink, this.onTap});

  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget body = SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.gutter / 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool compact = constraints.maxWidth < 120;
            // `compact` alone decided the *content* (whether the subtitle
            // fits the idea of the tile at all) but says nothing about
            // *height* — a wide-but-one-row `flat` tile is `!compact` yet
            // has no more vertical room than a small one, so it kept the
            // subtitle and overflowed. The `FittedBox` is the actual safety
            // net: it shrinks the whole stack to whatever room there really
            // is, on any tile shape, rather than assuming width implies
            // height the way the small/flat overflow elsewhere in this app
            // already showed it doesn't.
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(Messages.filesTitle, style: _text(compact ? 8 : 10)),
                  const SizedBox(height: 4),
                  FolderIcon(size: compact ? 22 : 32, color: ink),
                  if (!compact) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(Messages.filesSubtitle, style: _text(8)),
                  ],
                ],
              ),
            );
          },
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

  TextStyle _text(double size) =>
      TextStyle(fontFamily: kPixelFontFamily, fontSize: size, color: ink);
}
