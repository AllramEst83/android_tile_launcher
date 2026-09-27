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
}
