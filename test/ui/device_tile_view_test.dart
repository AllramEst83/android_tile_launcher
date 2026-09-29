import 'package:android_tile_launcher/model/device_status.dart';
import 'package:android_tile_launcher/ui/device_icons.dart';
import 'package:android_tile_launcher/ui/device_tile_view.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, DeviceStatus status, {Size? size}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: tileLauncherTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: size?.width ?? 300,
              height: size?.height ?? 150,
              child: DeviceTileContentView(status: status, ink: Colors.white),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('shows battery, free storage and free memory', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const DeviceStatus(
        batteryPercent: 87,
        charging: true,
        storageFreeBytes: 42400000000,
        storageTotalBytes: 128000000000,
        memoryAvailableBytes: 2100000000,
        memoryTotalBytes: 6000000000,
      ),
    );

    expect(find.text('BATTERY  87% +'), findsOneWidget);
    expect(find.text('STORAGE  42.4 GB FREE'), findsOneWidget);
    expect(find.text('MEMORY  2.1 GB FREE'), findsOneWidget);
    expect(find.byType(BatteryIcon), findsOneWidget);
    expect(find.byType(DiskIcon), findsOneWidget);
    expect(find.byType(MemoryIcon), findsOneWidget);
  });

  testWidgets('shows dashes for what is unknown', (WidgetTester tester) async {
    await _pump(tester, const DeviceStatus());

    expect(find.text('BATTERY  --'), findsOneWidget);
    expect(find.text('STORAGE  --'), findsOneWidget);
    expect(find.text('MEMORY  --'), findsOneWidget);
  });

  testWidgets('the battery bar is filled to the charge', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const DeviceStatus(batteryPercent: 50));

    final Iterable<FractionallySizedBox> bars = tester
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox));
    expect(bars.first.widthFactor, 0.5);
  });

  testWidgets('fits a small tile without overflowing', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const DeviceStatus(
        batteryPercent: 100,
        storageFreeBytes: 123600000000,
        storageTotalBytes: 128000000000,
        memoryAvailableBytes: 2100000000,
        memoryTotalBytes: 6000000000,
      ),
      size: const Size(90, 90),
    );

    expect(tester.takeException(), isNull);
  });
}
