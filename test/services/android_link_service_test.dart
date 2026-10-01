import 'package:android_tile_launcher/services/android_link_service.dart';
import 'package:android_tile_launcher/services/link_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _channel = MethodChannel(AndroidLinkService.channelName);

void _mockChannel(Future<Object?>? Function(MethodCall call) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => _mockChannel((call) => null));

  final AndroidLinkService service = AndroidLinkService(
    channel: _channel,
    timeout: const Duration(milliseconds: 50),
  );

  test('opens the url, with nothing else', () async {
    MethodCall? seen;
    _mockChannel((call) async {
      seen = call;
      return true;
    });

    expect(await service.open('https://example.com'), isA<LinkOpened>());
    expect(seen?.method, 'open');
    expect(seen?.arguments, <String, Object?>{'url': 'https://example.com'});
  });

  test('nothing to open it with is a failure', () async {
    _mockChannel((call) async => false);

    expect(await service.open('https://example.com'), isA<LinkFailed>());
  });

  test('a platform error is a failure', () async {
    _mockChannel((call) async => throw PlatformException(code: 'UNAVAILABLE'));

    expect(await service.open('https://example.com'), isA<LinkFailed>());
  });

  test('no handler at all is unsupported, not a crash', () async {
    _mockChannel((call) => throw MissingPluginException());

    expect(await service.open('https://example.com'), isA<LinkFailed>());
  });

  test('a reply that never comes gives up', () async {
    _mockChannel((call) => Future<Object?>.delayed(const Duration(seconds: 5)));

    expect(await service.open('https://example.com'), isA<LinkFailed>());
  });
}
