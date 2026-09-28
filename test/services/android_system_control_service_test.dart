import 'package:android_tile_launcher/model/sound_mode.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/services/android_system_control_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _channel = MethodChannel(
  AndroidSystemControlService.channelName,
);

/// Stands in for the Kotlin side; the real platform is never touched in tests.
void _mockChannel(Future<Object?>? Function(MethodCall call) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => _mockChannel((call) async => null));

  const AndroidSystemControlService service = AndroidSystemControlService(
    channel: _channel,
  );

  test('isOn sends the kind name and returns the platform result', () async {
    MethodCall? received;
    _mockChannel((call) async {
      received = call;
      return true;
    });

    final on = await service.isOn(TileKind.flashlight);

    expect(on, isTrue);
    expect(received?.method, 'isOn');
    expect(received?.arguments, {'kind': 'flashlight'});
  });

  test('isOn returns false instead of throwing on platform errors', () async {
    _mockChannel((call) async => throw PlatformException(code: 'BOOM'));

    expect(await service.isOn(TileKind.doNotDisturb), isFalse);
  });

  test('setOn sends the kind name and the requested state', () async {
    MethodCall? received;
    _mockChannel((call) async {
      received = call;
      return null;
    });

    await service.setOn(TileKind.doNotDisturb, true);

    expect(received?.method, 'setOn');
    expect(received?.arguments, {'kind': 'doNotDisturb', 'on': true});
  });

  test('setOn does not throw on platform errors', () async {
    _mockChannel((call) async => throw PlatformException(code: 'BOOM'));

    await expectLater(service.setOn(TileKind.flashlight, false), completes);
  });

  test('soundMode maps the platform\'s name to a SoundMode', () async {
    MethodCall? received;
    _mockChannel((call) async {
      received = call;
      return 'vibrate';
    });

    expect(await service.soundMode(), SoundMode.vibrate);
    expect(received?.method, 'getSoundMode');
  });

  test(
    'soundMode falls back to normal on garbage or platform errors',
    () async {
      _mockChannel((call) async => 'loud');
      expect(await service.soundMode(), SoundMode.normal);

      _mockChannel((call) async => throw PlatformException(code: 'BOOM'));
      expect(await service.soundMode(), SoundMode.normal);
    },
  );

  test('setSoundMode sends the mode name', () async {
    MethodCall? received;
    _mockChannel((call) async {
      received = call;
      return null;
    });

    await service.setSoundMode(SoundMode.silent);

    expect(received?.method, 'setSoundMode');
    expect(received?.arguments, {'mode': 'silent'});
  });

  test('setSoundMode does not throw on platform errors', () async {
    _mockChannel((call) async => throw PlatformException(code: 'BOOM'));

    await expectLater(service.setSoundMode(SoundMode.normal), completes);
  });
}
