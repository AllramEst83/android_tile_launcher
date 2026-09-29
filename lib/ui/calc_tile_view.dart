import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// The calc tile's content: its name, and on a larger tile the two things it
/// does. A tap ([onTap]) opens the calculator and converter; `null` in the
/// grid editor, where a tap selects the tile. There is nothing to read from the
/// outside world, so it never changes.
class CalcTileContentView extends StatelessWidget {
  const CalcTileContentView({super.key, required this.ink, this.onTap});

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
            // `compact` alone decides the *content* (whether the third line
            // fits the idea of the tile at all), not the *height* — a
            // wide-but-one-row tile is `!compact` yet has no more vertical
            // room than a small one, so the outer `FittedBox` (not just the
            // operators' own) is the actual safety net: it shrinks the whole
            // stack to whatever room there really is, the same fix already
            // applied to the files/alarm/Text TV/device/weather/agenda/mail
            // tiles for the same reason.
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(Messages.calcTitle, style: _text(compact ? 8 : 10)),
                  const SizedBox(height: 4),
                  // The four operators, as the keys of the thing this opens.
                  Text(compact ? '+-*/' : '+ - * /', style: _text(20)),
                  if (!compact) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      '${Messages.calcTabCalc} & ${Messages.calcTabConvert}',
                      style: _text(8),
                    ),
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
