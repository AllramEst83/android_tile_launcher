import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/bluetooth_status.dart';
import 'package:android_tile_launcher/ui/bluetooth_sheet.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_bluetooth_service.dart';

Future<void> _open(WidgetTester tester, FakeBluetoothService bluetooth) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showBluetoothSheet(context, bluetooth: bluetooth),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no radio at all says so', (WidgetTester tester) async {
    final bluetooth = FakeBluetoothService()
      ..statusResult = const BluetoothUnsupported();

    await _open(tester, bluetooth);

    expect(find.text(Messages.bluetoothUnsupportedBody), findsOneWidget);
  });

  testWidgets('a real platform error says its own reason, not "no radio"', (
    WidgetTester tester,
  ) async {
    final bluetooth = FakeBluetoothService()
      ..statusResult = const BluetoothUnavailable('boom');

    await _open(tester, bluetooth);

    expect(find.text('BOOM'), findsOneWidget);
    expect(find.text(Messages.bluetoothUnsupportedBody), findsNothing);
  });

  group('needs permission', () {
    testWidgets('offers to allow it, and asks when tapped', (
      WidgetTester tester,
    ) async {
      final bluetooth = FakeBluetoothService()
        ..statusResult = const BluetoothNeedsPermission(permanent: false);

      await _open(tester, bluetooth);
      expect(find.byKey(bluetoothAllowKey), findsOneWidget);

      await tester.tap(find.byKey(bluetoothAllowKey));
      await tester.pumpAndSettle();

      expect(bluetooth.allowCalls, 1);
    });

    testWidgets('a permanent denial points at Android settings instead', (
      WidgetTester tester,
    ) async {
      final bluetooth = FakeBluetoothService()
        ..statusResult = const BluetoothNeedsPermission(permanent: true);

      await _open(tester, bluetooth);

      expect(find.text(Messages.bluetoothAllowInSettings), findsOneWidget);
      expect(find.byKey(bluetoothAllowKey), findsNothing);
    });
  });

  testWidgets('off offers the toggle panel, not a device list', (
    WidgetTester tester,
  ) async {
    final bluetooth = FakeBluetoothService()
      ..statusResult = const BluetoothOff();

    await _open(tester, bluetooth);
    expect(find.text(Messages.bluetoothOffBody), findsOneWidget);

    await tester.tap(find.byKey(bluetoothToggleKey));
    await tester.pumpAndSettle();

    expect(bluetooth.openPanelCalls, 1);
  });

  group('on', () {
    testWidgets('no paired devices says so', (WidgetTester tester) async {
      final bluetooth = FakeBluetoothService()
        ..statusResult = const BluetoothOn(<PairedDevice>[]);

      await _open(tester, bluetooth);

      expect(find.text(Messages.bluetoothNoDevices), findsOneWidget);
    });

    testWidgets('lists paired devices with their connection state', (
      WidgetTester tester,
    ) async {
      final bluetooth = FakeBluetoothService()
        ..statusResult = const BluetoothOn(<PairedDevice>[
          PairedDevice(name: 'Speaker', address: 'AA:BB', connected: true),
          PairedDevice(name: 'Watch', address: 'CC:DD', connected: false),
        ]);

      await _open(tester, bluetooth);

      expect(find.text('SPEAKER'), findsOneWidget);
      expect(find.text('WATCH'), findsOneWidget);
      expect(find.text(Messages.bluetoothConnected), findsOneWidget);
      expect(find.text(Messages.bluetoothNotConnected), findsOneWidget);
    });

    testWidgets('MANAGE DEVICES and a device row both open settings', (
      WidgetTester tester,
    ) async {
      final bluetooth = FakeBluetoothService()
        ..statusResult = const BluetoothOn(<PairedDevice>[
          PairedDevice(name: 'Speaker', address: 'AA:BB', connected: true),
        ]);

      await _open(tester, bluetooth);

      await tester.tap(find.byKey(bluetoothDeviceKey('AA:BB')));
      await tester.pumpAndSettle();
      expect(bluetooth.openSettingsCalls, 1);

      await tester.tap(find.byKey(bluetoothManageKey));
      await tester.pumpAndSettle();
      expect(bluetooth.openSettingsCalls, 2);
    });

    testWidgets('TURN ON / OFF opens the toggle panel', (
      WidgetTester tester,
    ) async {
      final bluetooth = FakeBluetoothService()
        ..statusResult = const BluetoothOn(<PairedDevice>[]);

      await _open(tester, bluetooth);

      await tester.tap(find.byKey(bluetoothToggleKey));
      await tester.pumpAndSettle();

      expect(bluetooth.openPanelCalls, 1);
    });
  });

  testWidgets('the close key closes the sheet', (WidgetTester tester) async {
    final bluetooth = FakeBluetoothService();
    await _open(tester, bluetooth);

    await tester.tap(find.byKey(bluetoothCloseKey));
    await tester.pumpAndSettle();

    expect(find.text(Messages.bluetoothTitle), findsNothing);
  });
}
