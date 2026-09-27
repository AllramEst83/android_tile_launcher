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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TileMetrics.gutter / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FittedBox(
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
          const SizedBox(height: 4),
          Text(
            content.date,
            style: TextStyle(
              fontFamily: kPixelFontFamily,
              fontSize: 10,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}
