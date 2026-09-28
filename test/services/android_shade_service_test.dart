import 'package:android_tile_launcher/services/android_shade_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _channel = MethodChannel(AndroidShadeService.channelName);

void _mockChannel(Future<Object?>? Function(MethodCall call) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => _mockChannel((call) => null));

  final AndroidShadeService service = AndroidShadeService(
    channel: _channel,
    timeout: const Duration(milliseconds: 50),
  );

  test('each panel is its own call', () async {
    final List<String> asked = <String>[];
    _mockChannel((call) async {
      asked.add(call.method);
      return true;
    });

    expect(await service.expandNotifications(), isTrue);
    expect(await service.expandQuickSettings(), isTrue);
    expect(asked, <String>['expandNotifications', 'expandQuickSettings']);
  });

  test('false when the phone refuses, whatever went wrong', () async {
    _mockChannel((call) async => false);
    expect(await service.expandNotifications(), isFalse);

    _mockChannel((call) async => throw PlatformException(code: 'X'));
    expect(await service.expandQuickSettings(), isFalse);

    _mockChannel((call) => throw MissingPluginException());
    expect(await service.expandNotifications(), isFalse);

    _mockChannel((call) => Future<Object?>.delayed(const Duration(seconds: 5)));
    expect(await service.expandQuickSettings(), isFalse);
  });
}
