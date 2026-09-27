import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/clock_tile_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the injected clock, not the real one', () {
    final source = ClockTileSource(now: () => DateTime(2026, 9, 27, 14, 32));

    final content = source.read();

    expect(content, isA<ClockContent>());
    expect((content as ClockContent).time, '14:32');
    expect(content.date, 'SUN 27 SEP');
  });

  test('a fresh read reflects a fresh now()', () {
    var current = DateTime(2026, 1, 1, 0, 0);
    final source = ClockTileSource(now: () => current);

    final first = source.read() as ClockContent;
    current = DateTime(2026, 1, 1, 0, 1);
    final second = source.read() as ClockContent;

    expect(first.time, '00:00');
    expect(second.time, '00:01');
  });
}
