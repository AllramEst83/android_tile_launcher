import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// The clock tile's content: time large, date small — the oversized-numeral
/// style live tiles get. Purely a view; [content] already comes formatted
/// from `ClockTileSource`.
class ClockTileContentView extends StatelessWidget {
  const ClockTileContentView({
    super.key,
    required this.content,
    required this.ink,
  });

  final ClockContent content;
  final Color ink;

  static const double _gap = 4;

  // A readable floor for the big time digits: below this, dropping the date
  // first (rather than shrinking the time to match) keeps the one line that
  // actually matters legible.
  static const double _minTimeRoom = 24;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TileMetrics.gutter / 2),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // The date is a nice-to-have second line, dropped below whatever
          // room a one-row-tall tile leaves for the time — the same
          // room-then-decide pattern the mail/weather/agenda tiles already
          // use for their own optional lines — and the time itself is
          // `Flexible` around its `FittedBox`, so on a tile short enough that
          // even the time alone wouldn't otherwise fit, it shrinks instead of
          // ever overflowing.
          final TextScaler scaler = MediaQuery.textScalerOf(context);
          final double dateLine = scaler.scale(10) * 1.45;
          final bool showDate =
              constraints.maxHeight - dateLine - _gap >= _minTimeRoom;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    content.time,
                    style: TextStyle(
                      fontFamily: kPixelFontFamily,
                      fontSize: 32,
                      color: ink,
                    ),
                  ),
                ),
              ),
              if (showDate) ...<Widget>[
                const SizedBox(height: _gap),
                Text(
                  content.date,
                  style: TextStyle(
                    fontFamily: kPixelFontFamily,
                    fontSize: 10,
                    // An explicit line height, matching what `dateLine`
                    // above assumes: left to the font's own metrics, this
                    // pixel font renders taller than that estimate, which is
                    // what actually overflowed before this was pinned down.
                    height: 1.45,
                    color: ink,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
