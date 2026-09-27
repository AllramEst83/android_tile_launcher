import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/tile_source.dart';
import 'package:android_tile_launcher/ui/tile_poller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts up on every read, encoded into [ClockContent.time] so the test
/// doesn't need a `TileContent` subtype of its own — `TileContent` is sealed
/// to the model, on purpose.
class _CountingSource implements TileSource {
  int calls = 0;

  @override
  TileContent read() => ClockContent(time: '${calls++}', date: '');
}

Future<void> _pump(WidgetTester tester, TileSource source, Duration interval) =>
    tester.pumpWidget(
      MaterialApp(
        home: TilePoller(
          source: source,
          interval: interval,
          builder: (context, content) => Text((content as ClockContent).time),
        ),
      ),
    );

void main() {
  testWidgets('shows the source\'s first read immediately', (
    WidgetTester tester,
  ) async {
    final source = _CountingSource();

    await _pump(tester, source, const Duration(seconds: 1));

    expect(find.text('0'), findsOneWidget);
    expect(source.calls, 1);
  });

  testWidgets('re-reads on every interval tick', (WidgetTester tester) async {
    final source = _CountingSource();
    await _pump(tester, source, const Duration(seconds: 1));

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('stops polling while backgrounded, refreshes on resume', (
    WidgetTester tester,
  ) async {
    final source = _CountingSource();
    await _pump(tester, source, const Duration(seconds: 1));
    expect(source.calls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 5));
    expect(source.calls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(source.calls, 2);
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });
}
