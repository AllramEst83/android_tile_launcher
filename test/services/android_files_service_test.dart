import 'dart:io';

import 'package:android_tile_launcher/services/android_files_service.dart';
import 'package:android_tile_launcher/services/files_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _channel = MethodChannel(AndroidFilesService.channelName);

/// Stands in for the Kotlin side; the real platform is never touched in
/// tests.
void _mockChannel(Future<Object?>? Function(MethodCall call) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => _mockChannel((call) async => null));

  final AndroidFilesService service = AndroidFilesService(channel: _channel);

  group('roots', () {
    test('one entry per storage directory, named in order', () async {
      _mockChannel(
        (call) async => <String>['/storage/emulated/0', '/storage/AAAA-1111'],
      );

      final result = await service.roots();

      expect(result, isA<FilesListed>());
      final entries = (result as FilesListed).entries;
      expect(entries.map((e) => e.name), <String>[
        'INTERNAL STORAGE',
        'SD CARD',
      ]);
      expect(entries.map((e) => e.path), <String>[
        '/storage/emulated/0',
        '/storage/AAAA-1111',
      ]);
      expect(entries.every((e) => e.isDirectory), isTrue);
    });

    test('a third volume is numbered', () async {
      _mockChannel((call) async => <String>['/a', '/b', '/c']);

      final entries = ((await service.roots()) as FilesListed).entries;

      expect(entries.map((e) => e.name), <String>[
        'INTERNAL STORAGE',
        'SD CARD',
        'SD CARD 2',
      ]);
    });

    test('none found is worded, not an empty silent list', () async {
      _mockChannel((call) async => <String>[]);

      expect(await service.roots(), isA<FilesUnavailable>());
    });

    test('a platform error is worded', () async {
      _mockChannel(
        (call) async => throw PlatformException(
          code: 'BOOM',
          message: 'could not read volumes',
        ),
      );

      final result = await service.roots();

      expect(result, isA<FilesUnavailable>());
      expect((result as FilesUnavailable).reason, 'could not read volumes');
    });

    test('no handler at all is unsupported, not a crash', () async {
      _mockChannel((call) async => null);
      // No handler registered at all is the `MissingPluginException` case;
      // simulate it by removing the mock entirely.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);

      expect(await service.roots(), isA<FilesUnavailable>());
    });
  });

  group('hasAccess / requestAccess', () {
    test('reflects the injected check', () async {
      final service = AndroidFilesService(hasAccessCheck: () async => true);
      expect(await service.hasAccess(), isTrue);
    });

    test('a failing check is not granted', () async {
      final service = AndroidFilesService(
        hasAccessCheck: () async => throw Exception('boom'),
      );
      expect(await service.hasAccess(), isFalse);
    });

    test('requestAccess grants when the check says so', () async {
      final service = AndroidFilesService(requestAccessCheck: () async => true);
      expect(await service.requestAccess(), isA<AccessGranted>());
    });

    test('backing out (or a failure) is denied, not thrown', () async {
      final granted = AndroidFilesService(
        requestAccessCheck: () async => false,
      );
      expect(await granted.requestAccess(), isA<AccessDenied>());

      final failing = AndroidFilesService(
        requestAccessCheck: () async => throw Exception('boom'),
      );
      expect(await failing.requestAccess(), isA<AccessDenied>());
    });
  });

  group('list and delete (against a real temp directory)', () {
    late Directory root;
    late AndroidFilesService service;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('files_service_test_');
      service = AndroidFilesService(hasAccessCheck: () async => true);
    });

    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    test('no access: not even a real path is read', () async {
      final noAccess = AndroidFilesService(hasAccessCheck: () async => false);

      expect(await noAccess.list(root.path), isA<FilesNoAccess>());
    });

    test('folders before files, biggest first within each', () async {
      await File('${root.path}/small.txt').writeAsString('0123456789');
      await Directory('${root.path}/Photos').create();
      await File('${root.path}/big.bin').writeAsBytes(List.filled(9000, 0));

      final result = await service.list(root.path);

      expect(result, isA<FilesListed>());
      final entries = (result as FilesListed).entries;
      expect(entries.map((e) => e.name), <String>[
        'Photos',
        'big.bin',
        'small.txt',
      ]);
      expect(entries[0].isDirectory, isTrue);
      expect(entries[0].sizeBytes, 0);
      expect(entries[1].sizeBytes, 9000);
      expect(entries[2].sizeBytes, 10);
    });

    test('a path is the real filesystem path, not a synthetic one', () async {
      await File('${root.path}/a.txt').writeAsString('x');

      final entries = ((await service.list(root.path)) as FilesListed).entries;

      // `Platform.pathSeparator`, not a literal `/`: `Directory.list()`
      // joins with whatever the host actually uses, `\` on this Windows dev
      // machine's own test run, not the `/` Android alone ever uses.
      expect(entries.single.path, '${root.path}${Platform.pathSeparator}a.txt');
    });

    test('a folder that no longer exists is worded', () async {
      final result = await service.list('${root.path}/does-not-exist');

      expect(result, isA<FilesUnavailable>());
    });

    test('delete removes a file', () async {
      final file = File('${root.path}/a.txt')..writeAsStringSync('x');

      final result = await service.delete(file.path);

      expect(result, isA<DeleteSucceeded>());
      expect(await file.exists(), isFalse);
    });

    test('delete removes a folder and everything in it', () async {
      final dir = Directory('${root.path}/Photos')..createSync();
      File('${dir.path}/a.jpg').writeAsStringSync('x');

      final result = await service.delete(dir.path);

      expect(result, isA<DeleteSucceeded>());
      expect(await dir.exists(), isFalse);
    });

    test('deleting something already gone says so, not thrown', () async {
      final result = await service.delete('${root.path}/never-existed.txt');

      expect(result, isA<DeleteFailed>());
    });
  });
}
