import 'package:android_tile_launcher/model/wallpaper.dart';
import 'package:android_tile_launcher/services/android_wallpaper_service.dart';
import 'package:android_tile_launcher/services/wallpaper_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _channel = MethodChannel(
  AndroidWallpaperService.channelName,
);

void _mockChannel(Future<Object?>? Function(MethodCall call) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => _mockChannel((call) => null));

  final AndroidWallpaperService service = AndroidWallpaperService(
    channel: _channel,
    timeout: const Duration(milliseconds: 50),
  );
  final Uint8List image = Uint8List.fromList(<int>[1, 2, 3]);

  group('set', () {
    test('sends the picture and where it goes', () async {
      MethodCall? seen;
      _mockChannel((call) async {
        seen = call;
        return 'done';
      });

      final WallpaperResult result = await service.set(
        image,
        WallpaperTarget.both,
      );

      expect(result, WallpaperResult.done);
      expect(seen!.method, 'set');
      final Map<Object?, Object?> args =
          seen!.arguments as Map<Object?, Object?>;
      expect(args['target'], 'both');
      expect(args['image'], image);
    });

    test('each target is named as the Kotlin side expects', () async {
      final List<Object?> targets = <Object?>[];
      _mockChannel((call) async {
        targets.add((call.arguments as Map<Object?, Object?>)['target']);
        return 'done';
      });

      for (final WallpaperTarget target in WallpaperTarget.values) {
        await service.set(image, target);
      }

      expect(targets, <Object?>['lock', 'home', 'both']);
    });

    test('the phone can refuse, or fail', () async {
      _mockChannel((call) async => 'refused');
      expect(
        await service.set(image, WallpaperTarget.lock),
        WallpaperResult.refused,
      );

      _mockChannel((call) async => 'failed');
      expect(
        await service.set(image, WallpaperTarget.lock),
        WallpaperResult.failed,
      );
    });

    test(
      'an error, a missing handler, silence or nonsense is a failure',
      () async {
        _mockChannel((call) async => throw PlatformException(code: 'X'));
        expect(
          await service.set(image, WallpaperTarget.lock),
          WallpaperResult.failed,
        );

        _mockChannel((call) => throw MissingPluginException());
        expect(
          await service.set(image, WallpaperTarget.lock),
          WallpaperResult.failed,
        );

        _mockChannel(
          (call) => Future<Object?>.delayed(const Duration(seconds: 5)),
        );
        expect(
          await service.set(image, WallpaperTarget.lock),
          WallpaperResult.failed,
        );

        _mockChannel((call) async => 'maybe');
        expect(
          await service.set(image, WallpaperTarget.lock),
          WallpaperResult.failed,
        );
      },
    );
  });

  group('clear', () {
    test('asks for the default back on a target', () async {
      MethodCall? seen;
      _mockChannel((call) async {
        seen = call;
        return 'done';
      });

      final WallpaperResult result = await service.clear(WallpaperTarget.home);

      expect(result, WallpaperResult.done);
      expect(seen!.method, 'clear');
      expect((seen!.arguments as Map<Object?, Object?>)['target'], 'home');
    });

    test('never throws', () async {
      _mockChannel((call) async => throw PlatformException(code: 'X'));

      expect(await service.clear(WallpaperTarget.lock), WallpaperResult.failed);
    });
  });
}
