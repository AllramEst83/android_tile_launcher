import 'package:android_tile_launcher/ui/device_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget icon) => tester.pumpWidget(
  MaterialApp(
    home: Center(child: SizedBox(width: 24, height: 24, child: icon)),
  ),
);

void main() {
  group('BatteryIcon', () {
    for (final fraction in <double?>[null, 0, 0.25, 0.5, 1]) {
      testWidgets('draws with no exception at fraction $fraction', (
        WidgetTester tester,
      ) async {
        await _pump(
          tester,
          BatteryIcon(fraction: fraction, size: 24, color: Colors.white),
        );

        expect(find.byType(BatteryIcon), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a fraction outside 0..1 is clamped, not thrown', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const BatteryIcon(fraction: 4, size: 24, color: Colors.white),
      );

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('DiskIcon draws with no exception', (WidgetTester tester) async {
    await _pump(tester, const DiskIcon(size: 24, color: Colors.white));

    expect(find.byType(DiskIcon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MemoryIcon draws with no exception', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const MemoryIcon(size: 24, color: Colors.white));

    expect(find.byType(MemoryIcon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
