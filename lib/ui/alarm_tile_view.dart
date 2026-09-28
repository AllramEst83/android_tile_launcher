import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// The alarm tile's content: its name, and on a larger tile the two things it
/// sets. A tap ([onTap]) opens the timer and alarm; `null` in the grid editor,
/// where a tap selects the tile. There is nothing to read from outside (the
/// clock app owns the timers and alarms), so it never changes.
class AlarmTileContentView extends StatelessWidget {
  const AlarmTileContentView({super.key, required this.ink, this.onTap});

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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(Messages.alarmTitle, style: _text(compact ? 8 : 10)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('00:00', style: _text(20)),
                ),
                if (!compact) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    '${Messages.alarmTabTimer} & ${Messages.alarmTabAlarm}',
                    style: _text(8),
                  ),
                ],
              ],
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
