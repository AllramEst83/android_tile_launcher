import 'package:android_tile_launcher/services/android_home_role_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _channel = MethodChannel(
  AndroidHomeRoleService.channelName,
);

void _mockChannel(Future<Object?>? Function(MethodCall call) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => _mockChannel((call) => null));

  final AndroidHomeRoleService service = AndroidHomeRoleService(
    channel: _channel,
    timeout: const Duration(milliseconds: 50),
  );

  group('isDefault', () {
    test('says what the platform says', () async {
      _mockChannel((call) async => call.method == 'isDefault');
      expect(await service.isDefault(), isTrue);

      _mockChannel((call) async => false);
      expect(await service.isDefault(), isFalse);
    });

    test('an error, a missing handler or silence is unknown', () async {
      _mockChannel((call) async => throw PlatformException(code: 'X'));
      expect(await service.isDefault(), isNull);

      _mockChannel((call) => throw MissingPluginException());
      expect(await service.isDefault(), isNull);

      _mockChannel(
        (call) => Future<Object?>.delayed(const Duration(seconds: 5)),
      );
      expect(await service.isDefault(), isNull);
    });
  });

  group('openSettings', () {
    test('true once the chooser opened', () async {
      String? asked;
      _mockChannel((call) async {
        asked = call.method;
        return true;
      });

      expect(await service.openSettings(), isTrue);
      expect(asked, 'openSettings');
    });

    test('false when it could not be opened, whatever went wrong', () async {
      _mockChannel((call) async => false);
      expect(await service.openSettings(), isFalse);

      _mockChannel((call) async => throw PlatformException(code: 'X'));
      expect(await service.openSettings(), isFalse);

      _mockChannel((call) => throw MissingPluginException());
      expect(await service.openSettings(), isFalse);

      _mockChannel(
        (call) => Future<Object?>.delayed(const Duration(seconds: 5)),
      );
      expect(await service.openSettings(), isFalse);
    });
  });
}
