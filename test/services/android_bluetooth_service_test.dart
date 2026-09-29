import 'package:android_tile_launcher/model/bluetooth_status.dart';
import 'package:android_tile_launcher/services/android_bluetooth_service.dart';
import 'package:android_tile_launcher/services/permission_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_permission_service.dart';

const MethodChannel _channel = MethodChannel(
  AndroidBluetoothService.channelName,
);

/// Stands in for the Kotlin side; the real platform is never touched in
/// tests.
void _mockChannel(Future<Object?>? Function(MethodCall call) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => _mockChannel((call) async => null));

  group('status', () {
    test('no adapter at all is unsupported', () async {
      _mockChannel((call) async => <String, Object?>{'supported': false});
      final service = AndroidBluetoothService(
        permissions: FakePermissionService(),
      );

      expect(await service.status(), isA<BluetoothUnsupported>());
    });

    test('missing access asks to allow, not yet permanently', () async {
      _mockChannel(
        (call) async => <String, Object?>{
          'supported': true,
          'hasAccess': false,
        },
      );
      final service = AndroidBluetoothService(
        permissions: FakePermissionService(),
      );

      final result = await service.status();
      expect(result, isA<BluetoothNeedsPermission>());
      expect((result as BluetoothNeedsPermission).permanent, isFalse);
    });

    test('access granted but the adapter is off', () async {
      _mockChannel(
        (call) async => <String, Object?>{
          'supported': true,
          'hasAccess': true,
          'enabled': false,
        },
      );
      final service = AndroidBluetoothService(
        permissions: FakePermissionService(),
      );

      expect(await service.status(), isA<BluetoothOff>());
    });

    test('on, with its paired devices', () async {
      _mockChannel(
        (call) async => <String, Object?>{
          'supported': true,
          'hasAccess': true,
          'enabled': true,
          'devices': <Map<String, Object?>>[
            <String, Object?>{
              'name': 'Speaker',
              'address': 'AA:BB',
              'connected': true,
            },
            <String, Object?>{
              'name': 'Watch',
              'address': 'CC:DD',
              'connected': false,
            },
          ],
        },
      );
      final service = AndroidBluetoothService(
        permissions: FakePermissionService(),
      );

      final result = await service.status();
      expect(result, isA<BluetoothOn>());
      final devices = (result as BluetoothOn).devices;
      expect(devices, <PairedDevice>[
        const PairedDevice(name: 'Speaker', address: 'AA:BB', connected: true),
        const PairedDevice(name: 'Watch', address: 'CC:DD', connected: false),
      ]);
    });

    test('a permission denial earlier is remembered as permanent', () async {
      final permissions = FakePermissionService(
        PermissionStatus.permanentlyDenied,
      );
      final service = AndroidBluetoothService(permissions: permissions);
      _mockChannel(
        (call) async => <String, Object?>{
          'supported': true,
          'hasAccess': false,
        },
      );

      await service.allow();
      final result = await service.status();

      expect(result, isA<BluetoothNeedsPermission>());
      expect((result as BluetoothNeedsPermission).permanent, isTrue);
    });

    test('access regained clears an earlier permanent denial', () async {
      final permissions = FakePermissionService(
        PermissionStatus.permanentlyDenied,
      );
      final service = AndroidBluetoothService(permissions: permissions);
      await service.allow();

      _mockChannel(
        (call) async => <String, Object?>{
          'supported': true,
          'hasAccess': true,
          'enabled': false,
        },
      );
      expect(await service.status(), isA<BluetoothOff>());

      _mockChannel(
        (call) async => <String, Object?>{
          'supported': true,
          'hasAccess': false,
        },
      );
      final result = await service.status();
      expect((result as BluetoothNeedsPermission).permanent, isFalse);
    });

    test('a platform error is unsupported, not thrown', () async {
      _mockChannel((call) async => throw PlatformException(code: 'BOOM'));
      final service = AndroidBluetoothService(
        permissions: FakePermissionService(),
      );

      expect(await service.status(), isA<BluetoothUnsupported>());
    });

    test('no handler at all is unsupported, not a crash', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);
      final service = AndroidBluetoothService(
        permissions: FakePermissionService(),
      );

      expect(await service.status(), isA<BluetoothUnsupported>());
    });
  });

  group('allow', () {
    test('asks the permission service for bluetooth', () async {
      final permissions = FakePermissionService();
      final service = AndroidBluetoothService(permissions: permissions);

      await service.allow();

      expect(permissions.requested, <AppPermission>[AppPermission.bluetooth]);
    });
  });

  group('openPanel / openSettings', () {
    test('each reaches the channel without throwing', () async {
      final calls = <String>[];
      _mockChannel((call) async {
        calls.add(call.method);
        return null;
      });
      final service = AndroidBluetoothService(
        permissions: FakePermissionService(),
      );

      await service.openPanel();
      await service.openSettings();

      expect(calls, <String>['openPanel', 'openSettings']);
    });

    test('a platform error is swallowed', () async {
      _mockChannel((call) async => throw PlatformException(code: 'BOOM'));
      final service = AndroidBluetoothService(
        permissions: FakePermissionService(),
      );

      await service.openPanel();
      await service.openSettings();
    });
  });
}
