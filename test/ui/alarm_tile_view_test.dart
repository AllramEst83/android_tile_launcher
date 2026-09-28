import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/clock_format.dart';
import 'package:android_tile_launcher/ui/alarm_tile_view.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  DateTime? next,
  double width = 200,
  VoidCallback? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: Scaffold(
      body: SizedBox(
        width: width,
        height: 120,
        child: AlarmTileContentView(
          next: next,
          ink: Colors.white,
          onTap: onTap,
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('shows the next alarm due, not a fixed time', (
    WidgetTester tester,
  ) async {
    final due = DateTime(2026, 9, 28, 7, 30);
    await _pump(tester, next: due);

    expect(find.text(formatClockTime(due)), findsOneWidget);
    expect(find.text('00:00'), findsNothing);
  });

  testWidgets('shows a dash, not a fake time, when none is set', (
    WidgetTester tester,
  ) async {
    await _pump(tester, next: null);

    expect(find.text(Messages.alarmNone), findsOneWidget);
    expect(find.text('00:00'), findsNothing);
  });

  testWidgets('a compact tile drops the subtitle but still shows the time', (
    WidgetTester tester,
  ) async {
    final due = DateTime(2026, 9, 28, 7, 30);
    await _pump(tester, next: due, width: 80);

    expect(find.text(formatClockTime(due)), findsOneWidget);
    expect(find.textContaining(Messages.alarmTabTimer), findsNothing);
  });

  testWidgets('tapping calls onTap when given', (WidgetTester tester) async {
    var tapped = false;
    await _pump(tester, onTap: () => tapped = true);

    await tester.tap(find.byType(AlarmTileContentView));

    expect(tapped, isTrue);
  });
}
