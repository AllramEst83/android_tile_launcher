import 'package:android_tile_launcher/model/media_snapshot.dart';
import 'package:android_tile_launcher/services/android_media_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(AndroidMediaService.channelName);
  Uint8List? art;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          // A new list on every read, as the platform channel hands out.
          return <String, Object?>{
            'title': 'T',
            'artist': 'A',
            'isPlaying': true,
            'artwork': art == null ? null : Uint8List.fromList(art!),
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<Uint8List?> read(AndroidMediaService s) async =>
      ((await s.now()) as MediaPlaying).artwork;

  test('unchanged art comes back as the very same bytes', () async {
    art = Uint8List.fromList(<int>[1, 2, 3]);
    final AndroidMediaService service = AndroidMediaService();

    final Uint8List? first = await read(service);
    final Uint8List? second = await read(service);

    expect(identical(first, second), isTrue);
  });

  test('new art comes back as new bytes, and no art as none', () async {
    final AndroidMediaService service = AndroidMediaService();
    art = Uint8List.fromList(<int>[1, 2, 3]);
    final Uint8List? first = await read(service);

    art = Uint8List.fromList(<int>[4, 5, 6]);
    final Uint8List? second = await read(service);
    expect(second, <int>[4, 5, 6]);
    expect(identical(first, second), isFalse);

    art = null;
    expect(await read(service), isNull);
  });
}
