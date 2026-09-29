import 'package:android_tile_launcher/model/bluetooth_status.dart';
import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/bluetooth_tile_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_bluetooth_service.dart';

void main() {
  test('reads the adapter status fresh every time', () async {
    final service = FakeBluetoothService();
    final source = BluetoothTileSource(service: service);

    service.statusResult = const BluetoothOff();
    final BluetoothTileContent off =
        await source.read() as BluetoothTileContent;
    expect(off.status, isA<BluetoothOff>());

    const devices = <PairedDevice>[
      PairedDevice(name: 'Speaker', address: 'AA:BB', connected: true),
    ];
    service.statusResult = const BluetoothOn(devices);
    final BluetoothTileContent on = await source.read() as BluetoothTileContent;
    expect((on.status as BluetoothOn).devices, devices);
  });
}
