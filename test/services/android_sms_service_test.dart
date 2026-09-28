import 'package:android_tile_launcher/services/android_sms_service.dart';
import 'package:android_tile_launcher/services/permission_service.dart';
import 'package:android_tile_launcher/services/sms_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_permission_service.dart';

const MethodChannel _channel = MethodChannel(AndroidSmsService.channelName);

void _mockChannel(Future<Object?>? Function(MethodCall call) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => _mockChannel((call) => null));

  late FakePermissionService permissions;
  late AndroidSmsService service;
  setUp(() {
    permissions = FakePermissionService();
    service = AndroidSmsService(
      permissions: permissions,
      channel: _channel,
      timeout: const Duration(milliseconds: 50),
    );
  });

  test('asks for SMS permission, then sends the number and text', () async {
    MethodCall? seen;
    _mockChannel((call) async {
      seen = call;
      return true;
    });

    final SmsResult result = await service.send('+46701234567', 'On my way');

    expect(result, isA<SmsSent>());
    expect(permissions.requested, <AppPermission>[AppPermission.sms]);
    expect(seen?.method, 'send');
    expect(seen?.arguments, <String, Object?>{
      'number': '+46701234567',
      'text': 'On my way',
    });
  });

  test('a refusal never reaches the platform', () async {
    permissions.answer = PermissionStatus.denied;
    bool asked = false;
    _mockChannel((call) async {
      asked = true;
      return true;
    });

    final SmsResult result = await service.send('1', 'x');

    expect((result as SmsDenied).permanent, isFalse);
    expect(asked, isFalse);
  });

  test('a permanent refusal is passed on as permanent', () async {
    permissions.answer = PermissionStatus.permanentlyDenied;

    expect(((await service.send('1', 'x')) as SmsDenied).permanent, isTrue);
  });

  test('permission revoked between the two calls is a denial', () async {
    _mockChannel(
      (call) async => throw PlatformException(code: 'NO_PERMISSION'),
    );

    expect(await service.send('1', 'x'), isA<SmsDenied>());
  });

  test('says why when the network will not take it', () async {
    Future<String> reasonFor(String code) async {
      _mockChannel((call) async => throw PlatformException(code: code));
      return ((await service.send('1', 'x')) as SmsFailed).reason;
    }

    expect(await reasonFor('NO_SERVICE'), 'no network service');
    expect(await reasonFor('RADIO_OFF'), 'flight mode is on');
    expect(await reasonFor('SEND_FAILED'), 'the message could not be sent');
    expect(
      await reasonFor('NOT_CONFIRMED'),
      contains('check before resending'),
    );
  });

  test(
    'a reply that never comes is not confirmed, not a failure to send',
    () async {
      _mockChannel(
        (call) => Future<Object?>.delayed(const Duration(seconds: 5)),
      );

      final SmsResult result = await service.send('1', 'x');

      expect((result as SmsFailed).reason, contains('check before resending'));
    },
  );

  test('no handler at all is unsupported, not a crash', () async {
    _mockChannel((call) => throw MissingPluginException());

    expect(await service.send('1', 'x'), isA<SmsFailed>());
  });
}
