import 'package:android_tile_launcher/model/device_format.dart';
import 'package:android_tile_launcher/model/device_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceStatus', () {
    test('battery fraction is percent / 100, or null when unknown', () {
      expect(const DeviceStatus(batteryPercent: 87).batteryFraction, 0.87);
      expect(const DeviceStatus().batteryFraction, isNull);
    });

    test('battery fraction is clamped to 0..1', () {
      expect(const DeviceStatus(batteryPercent: 140).batteryFraction, 1);
      expect(const DeviceStatus(batteryPercent: -5).batteryFraction, 0);
    });

    test('storage free fraction is free / total', () {
      const status = DeviceStatus(storageFreeBytes: 25, storageTotalBytes: 100);
      expect(status.storageFreeFraction, 0.25);
    });

    test('storage free fraction is null when either side is unknown or 0', () {
      expect(
        const DeviceStatus(storageFreeBytes: 5).storageFreeFraction,
        isNull,
      );
      expect(
        const DeviceStatus(
          storageFreeBytes: 0,
          storageTotalBytes: 0,
        ).storageFreeFraction,
        isNull,
      );
    });

    test('equal statuses are equal', () {
      expect(
        const DeviceStatus(batteryPercent: 5, charging: true),
        const DeviceStatus(batteryPercent: 5, charging: true),
      );
      expect(
        const DeviceStatus(batteryPercent: 5),
        isNot(const DeviceStatus(batteryPercent: 6)),
      );
    });
  });

  group('formatBattery', () {
    test('shows the percent', () {
      expect(formatBattery(const DeviceStatus(batteryPercent: 87)), '87%');
    });

    test('marks charging', () {
      expect(
        formatBattery(const DeviceStatus(batteryPercent: 87, charging: true)),
        '87% +',
      );
    });

    test('shows dashes when unknown', () {
      expect(formatBattery(const DeviceStatus()), '--');
    });
  });

  group('formatStorageFree', () {
    String free(int bytes) =>
        formatStorageFree(DeviceStatus(storageFreeBytes: bytes));

    test('gigabytes with one decimal under 100', () {
      expect(free(42400000000), '42.4 GB FREE');
    });

    test('gigabytes with no decimal from 100 up', () {
      expect(free(123600000000), '124 GB FREE');
    });

    test('megabytes below a gigabyte', () {
      expect(free(812000000), '812 MB FREE');
    });

    test('shows dashes when unknown', () {
      expect(formatStorageFree(const DeviceStatus()), '--');
    });
  });
}
