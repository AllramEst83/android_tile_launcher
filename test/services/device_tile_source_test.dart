import 'package:android_tile_launcher/model/device_status.dart';
import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/device_tile_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_device_repository.dart';

void main() {
  test('reads the repository fresh every time', () async {
    final repository = FakeDeviceRepository(
      const DeviceStatus(batteryPercent: 80),
    );
    final source = DeviceTileSource(repository: repository);

    expect(
      await source.read(),
      const DeviceContent(status: DeviceStatus(batteryPercent: 80)),
    );

    repository.current = const DeviceStatus(batteryPercent: 79);

    expect(
      await source.read(),
      const DeviceContent(status: DeviceStatus(batteryPercent: 79)),
    );
    expect(repository.calls, 2);
  });
}
