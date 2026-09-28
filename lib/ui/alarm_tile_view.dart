import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/clock_format.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// The alarm tile's content: its name, the next alarm due (or a dash if none
/// is set — never a time that looks real but isn't), and on a larger tile the
/// two things a tap opens. A tap ([onTap]) opens the timer and alarm; `null`
/// in the grid editor, where a tap selects the tile.
class AlarmTileContentView extends StatelessWidget {
  const AlarmTileContentView({
    super.key,
    required this.ink,
    this.next,
    this.onTap,
  });

  final Color ink;

  /// The next alarm due, or `null` when none is set.
  final DateTime? next;
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
                  child: Text(
                    next == null ? Messages.alarmNone : formatClockTime(next!),
                    style: _text(20),
                  ),
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
