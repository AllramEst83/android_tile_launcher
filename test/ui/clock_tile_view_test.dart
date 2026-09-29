import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/ui/clock_tile_view.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the time and the date', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: tileLauncherTheme(),
        home: Scaffold(
          body: ClockTileContentView(
            content: const ClockContent(time: '14:32', date: 'SUN 27 SEP'),
            ink: Colors.white,
          ),
        ),
      ),
    );

    expect(find.text('14:32'), findsOneWidget);
    expect(find.text('SUN 27 SEP'), findsOneWidget);
  });

  testWidgets(
    'a one-row-tall tile (the real height small/flat/size3x1/size4x1 render '
    'at) no longer overflows',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: tileLauncherTheme(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 88,
                height: 72,
                child: ClockTileContentView(
                  content: const ClockContent(
                    time: '14:32',
                    date: 'SUN 27 SEP',
                  ),
                  ink: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );

      // There is room for both at this real, once-overflowing height (the
      // time simply renders a little smaller, `FittedBox`'s own doing) —
      // dropping the date is a defensive floor for a shorter box than the
      // grid ever actually produces, covered by the next test.
      expect(tester.takeException(), isNull);
      expect(find.text('14:32'), findsOneWidget);
      expect(find.text('SUN 27 SEP'), findsOneWidget);
    },
  );

  testWidgets('a box shorter than any real tile drops the date, not crash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: tileLauncherTheme(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 88,
              height: 30,
              child: ClockTileContentView(
                content: const ClockContent(time: '14:32', date: 'SUN 27 SEP'),
                ink: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('14:32'), findsOneWidget);
    expect(find.text('SUN 27 SEP'), findsNothing);
  });

  testWidgets('a taller tile keeps both the time and the date', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: tileLauncherTheme(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 88,
              height: 140,
              child: ClockTileContentView(
                content: const ClockContent(time: '14:32', date: 'SUN 27 SEP'),
                ink: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('14:32'), findsOneWidget);
    expect(find.text('SUN 27 SEP'), findsOneWidget);
  });

  testWidgets('a one-row-tall tile at EXTRA LARGE still does not overflow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: tileLauncherTheme(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 88,
                height: 64,
                child: ClockTileContentView(
                  content: const ClockContent(
                    time: '14:32',
                    date: 'SUN 27 SEP',
                  ),
                  ink: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
