import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/bluetooth_status.dart';
import 'package:android_tile_launcher/ui/bluetooth_tile_view.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PairedDevice _device(String name, {bool connected = true}) =>
    PairedDevice(name: name, address: name, connected: connected);

Future<void> _pump(
  WidgetTester tester,
  BluetoothStatus status, {
  double width = 300,
  double height = 150,
  VoidCallback? onTap,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Material(
        child: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: BluetoothTileContentView(
              status: status,
              ink: TileColors.textBright,
              onTap: onTap,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('off shows the short off state', (WidgetTester tester) async {
    await _pump(tester, const BluetoothOff());

    expect(find.text(Messages.bluetoothTitle), findsOneWidget);
    expect(find.text(Messages.bluetoothOff), findsOneWidget);
  });

  testWidgets('on with nothing connected says so, not a device count of zero', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const BluetoothOn(<PairedDevice>[]));

    expect(find.text(Messages.bluetoothNoneConnected), findsOneWidget);
  });

  testWidgets('on with only disconnected devices is the same as none', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      BluetoothOn(<PairedDevice>[_device('Speaker', connected: false)]),
    );

    expect(find.text(Messages.bluetoothNoneConnected), findsOneWidget);
    expect(find.text('SPEAKER'), findsNothing);
  });

  testWidgets('lists connected devices by name, wide enough to show them', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      BluetoothOn(<PairedDevice>[
        _device('Car Kit'),
        _device('Headphones'),
        _device('Watch', connected: false),
      ]),
    );

    expect(find.text('CAR KIT'), findsOneWidget);
    expect(find.text('HEADPHONES'), findsOneWidget);
    expect(find.text('WATCH'), findsNothing);
    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('a short tile shows as many names as fit and counts the rest', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      BluetoothOn(<PairedDevice>[
        _device('One'),
        _device('Two'),
        _device('Three'),
        _device('Four'),
        _device('Five'),
      ]),
      height: 40,
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('+'), findsOneWidget);
  });

  testWidgets('a narrow tile shows a count, not names', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      BluetoothOn(<PairedDevice>[_device('Car Kit'), _device('Headphones')]),
      width: 80,
    );

    expect(find.byKey(bluetoothTileCountKey), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('CAR KIT'), findsNothing);
  });

  testWidgets('tapping the tile calls onTap', (WidgetTester tester) async {
    var tapped = false;
    await _pump(
      tester,
      BluetoothOn(<PairedDevice>[_device('Car Kit')]),
      onTap: () => tapped = true,
    );

    await tester.tap(find.byType(BluetoothTileContentView));

    expect(tapped, isTrue);
  });

  testWidgets('the smallest tile size does not overflow', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      BluetoothOn(<PairedDevice>[_device('Car Kit')]),
      width: 72,
      height: 72,
    );

    expect(tester.takeException(), isNull);
  });
}
