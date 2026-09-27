import 'package:android_tile_launcher/model/clock_format.dart';
import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/tile_source.dart';

/// The clock tile's content. Pure and synchronous — no platform channel, no
/// async — so [now] defaults to the real clock but is easy to fake in tests.
class ClockTileSource implements TileSource {
  const ClockTileSource({this.now = DateTime.now});

  final DateTime Function() now;

  @override
  TileContent read() {
    final DateTime t = now();
    return ClockContent(time: formatClockTime(t), date: formatClockDate(t));
  }
}
