import 'package:android_tile_launcher/services/android_phone_service.dart';
import 'package:android_tile_launcher/services/permission_service.dart';
import 'package:android_tile_launcher/services/phone_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_permission_service.dart';

const MethodChannel _channel = MethodChannel(AndroidPhoneService.channelName);

void _mockChannel(Future<Object?>? Function(MethodCall call) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => _mockChannel((call) => null));

  late FakePermissionService permissions;
  late AndroidPhoneService service;
  setUp(() {
    permissions = FakePermissionService();
    service = AndroidPhoneService(
      permissions: permissions,
      channel: _channel,
      timeout: const Duration(milliseconds: 50),
    );
  });

  test('with permission, it places the call', () async {
    final List<MethodCall> seen = <MethodCall>[];
    _mockChannel((call) async {
      seen.add(call);
      return true;
    });

    final CallResult result = await service.call('+46701234567');

    expect(result, isA<CallPlaced>());
    expect(permissions.requested, <AppPermission>[AppPermission.phone]);
    expect(seen.map((c) => c.method), <String>['call']);
    expect(seen.single.arguments, <String, Object?>{'number': '+46701234567'});
  });

  test('refused, the dialer opens with the number instead', () async {
    permissions.answer = PermissionStatus.denied;
    final List<String> methods = <String>[];
    _mockChannel((call) async {
      methods.add(call.method);
      return true;
    });

    expect(await service.call('0701234567'), isA<DialerOpened>());
    expect(methods, <String>['dial']);
  });

  test(
    'a number apps may not call directly falls back to the dialer',
    () async {
      final List<String> methods = <String>[];
      _mockChannel((call) async {
        methods.add(call.method);
        if (call.method == 'call') {
          throw PlatformException(code: 'NO_PERMISSION');
        }
        return true;
      });

      expect(await service.call('112'), isA<DialerOpened>());
      expect(methods, <String>['call', 'dial']);
    },
  );

  test('any other error placing the call is a failure, not a redial', () async {
    final List<String> methods = <String>[];
    _mockChannel((call) async {
      methods.add(call.method);
      throw PlatformException(code: 'UNAVAILABLE');
    });

    expect(await service.call('0701234567'), isA<CallFailed>());
    expect(methods, <String>['call']);
  });

  test('no dialer either is a failure', () async {
    permissions.answer = PermissionStatus.denied;
    _mockChannel((call) async => throw PlatformException(code: 'UNAVAILABLE'));

    expect(await service.call('0701234567'), isA<CallFailed>());
  });

  test('no handler at all is unsupported, not a crash', () async {
    _mockChannel((call) => throw MissingPluginException());

    expect(await service.call('0701234567'), isA<CallFailed>());
  });

  test('a reply that never comes gives up', () async {
    _mockChannel((call) => Future<Object?>.delayed(const Duration(seconds: 5)));

    expect(await service.call('0701234567'), isA<CallFailed>());
  });
}
