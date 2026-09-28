import 'package:android_tile_launcher/model/device_status.dart';
import 'package:android_tile_launcher/services/android_device_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _channel = MethodChannel(
  AndroidDeviceRepository.channelName,
);

/// Stands in for the Kotlin side; the real platform is never touched in tests.
void _mockChannel(Future<Object?>? Function(MethodCall call) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => _mockChannel((call) async => null));

  const AndroidDeviceRepository repository = AndroidDeviceRepository(
    channel: _channel,
  );

  test("maps the platform's map to a DeviceStatus", () async {
    MethodCall? received;
    _mockChannel((call) async {
      received = call;
      return {
        'batteryPercent': 87,
        'charging': true,
        'storageFreeBytes': 42400000000,
        'storageTotalBytes': 128000000000,
      };
    });

    final status = await repository.status();

    expect(received?.method, 'status');
    expect(
      status,
      const DeviceStatus(
        batteryPercent: 87,
        charging: true,
        storageFreeBytes: 42400000000,
        storageTotalBytes: 128000000000,
      ),
    );
  });

  test('leaves what the platform could not read as null', () async {
    _mockChannel((call) async => {'batteryPercent': null, 'charging': false});

    expect(await repository.status(), const DeviceStatus());
  });

  test('ignores values of the wrong type', () async {
    _mockChannel(
      (call) async => {'batteryPercent': 'lots', 'storageFreeBytes': 1.5},
    );

    expect(await repository.status(), const DeviceStatus());
  });

  test(
    'returns an empty status instead of throwing on platform errors',
    () async {
      _mockChannel((call) async => throw PlatformException(code: 'BOOM'));

      expect(await repository.status(), const DeviceStatus());
    },
  );

  test('returns an empty status when nothing answers the channel', () async {
    _mockChannel((call) async => null);

    expect(await repository.status(), const DeviceStatus());
  });
}
