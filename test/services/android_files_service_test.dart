import 'package:android_tile_launcher/services/android_files_service.dart';
import 'package:android_tile_launcher/services/files_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saf_util/saf_util.dart';
import 'package:saf_util/saf_util_platform_interface.dart' show SafDocumentFile;

import '../fakes/in_memory_local_store.dart';

SafDocumentFile _doc({
  required String uri,
  required String name,
  bool isDir = false,
  int length = -1,
}) => SafDocumentFile(
  uri: uri,
  name: name,
  isDir: isDir,
  length: length,
  lastModified: 0,
);

/// Stands in for `package:saf_util`'s platform channel; the real Storage
/// Access Framework is never touched in tests.
class _FakeSafUtil extends SafUtil {
  SafDocumentFile? pickResult;
  Object? pickError;
  bool persisted = false;
  Map<String, List<SafDocumentFile>> childrenByUri =
      <String, List<SafDocumentFile>>{};
  Object? listError;
  Object? deleteError;

  String? releasedUri;
  final List<String> deletedUris = <String>[];

  @override
  Future<SafDocumentFile?> pickDirectory({
    String? initialUri,
    bool? writePermission,
    bool? persistablePermission,
  }) async {
    final Object? error = pickError;
    if (error != null) throw error;
    return pickResult;
  }

  @override
  Future<bool> hasPersistedPermission(
    String uri, {
    bool checkRead = true,
    bool checkWrite = false,
  }) async => persisted;

  @override
  Future<void> releasePersistedPermission(
    String uri, {
    bool read = true,
    bool write = false,
  }) async {
    releasedUri = uri;
  }

  @override
  Future<List<SafDocumentFile>> list(String uri) async {
    final Object? error = listError;
    if (error != null) throw error;
    return childrenByUri[uri] ?? const <SafDocumentFile>[];
  }

  @override
  Future<SafDocumentFile?> child(String uri, List<String> names) async {
    SafDocumentFile? current = _doc(uri: uri, name: '', isDir: true);
    for (final String name in names) {
      final List<SafDocumentFile> siblings =
          childrenByUri[current!.uri] ?? const <SafDocumentFile>[];
      current = siblings
          .where((SafDocumentFile d) => d.name == name)
          .firstOrNull;
      if (current == null) return null;
    }
    return current;
  }

  @override
  Future<void> delete(String uri, bool isDir) async {
    final Object? error = deleteError;
    if (error != null) throw error;
    deletedUris.add(uri);
  }
}

void main() {
  late _FakeSafUtil saf;
  late InMemoryLocalStore store;
  late AndroidFilesService service;

  setUp(() {
    saf = _FakeSafUtil();
    store = InMemoryLocalStore();
    service = AndroidFilesService(store: store, saf: saf);
  });

  group('hasFolder', () {
    test('false with nothing picked yet', () async {
      expect(await service.hasFolder(), isFalse);
    });

    test('true once picked and the permission still holds', () async {
      saf.pickResult = _doc(uri: 'tree://root', name: 'Downloads', isDir: true);
      await service.pickFolder();
      saf.persisted = true;

      expect(await service.hasFolder(), isTrue);
    });

    test('false if the permission was revoked elsewhere', () async {
      saf.pickResult = _doc(uri: 'tree://root', name: 'Downloads', isDir: true);
      await service.pickFolder();
      saf.persisted = false;

      expect(await service.hasFolder(), isFalse);
    });
  });

  group('pickFolder', () {
    test('remembers the picked folder', () async {
      saf.pickResult = _doc(uri: 'tree://root', name: 'Downloads', isDir: true);

      final result = await service.pickFolder();

      expect(result, isA<FolderPicked>());
      expect(await store.read(AndroidFilesService.storeKey), 'tree://root');
    });

    test('backing out of the picker is cancelled, not a failure', () async {
      saf.pickResult = null;

      expect(await service.pickFolder(), isA<FolderPickCancelled>());
    });

    test('a platform failure is worded', () async {
      saf.pickError = Exception('boom');

      final result = await service.pickFolder();

      expect(result, isA<FolderPickFailed>());
      expect((result as FolderPickFailed).reason, 'boom');
    });
  });

  group('forgetFolder', () {
    test('releases the permission and clears the saved folder', () async {
      saf.pickResult = _doc(uri: 'tree://root', name: 'Downloads', isDir: true);
      await service.pickFolder();

      await service.forgetFolder();

      expect(saf.releasedUri, 'tree://root');
      expect(await service.hasFolder(), isFalse);
    });
  });

  group('list', () {
    test('no folder picked', () async {
      expect(await service.list(''), isA<FilesNoFolder>());
    });

    test('folders before files, biggest first within each', () async {
      saf.pickResult = _doc(uri: 'tree://root', name: 'Downloads', isDir: true);
      await service.pickFolder();
      saf.childrenByUri['tree://root'] = <SafDocumentFile>[
        _doc(uri: 'tree://root/small.txt', name: 'small.txt', length: 10),
        _doc(uri: 'tree://root/photos', name: 'Photos', isDir: true),
        _doc(uri: 'tree://root/big.zip', name: 'big.zip', length: 9000),
      ];

      final result = await service.list('');

      expect(result, isA<FilesListed>());
      final entries = (result as FilesListed).entries;
      expect(entries.map((e) => e.name), <String>[
        'Photos',
        'big.zip',
        'small.txt',
      ]);
      expect(entries[0].isDirectory, isTrue);
      expect(entries[0].sizeBytes, 0);
      expect(entries[0].path, 'Photos');
    });

    test('a subfolder is resolved through child(), not by hand', () async {
      saf.pickResult = _doc(uri: 'tree://root', name: 'Downloads', isDir: true);
      await service.pickFolder();
      saf.childrenByUri['tree://root'] = <SafDocumentFile>[
        _doc(uri: 'tree://root/photos', name: 'photos', isDir: true),
      ];
      saf.childrenByUri['tree://root/photos'] = <SafDocumentFile>[
        _doc(uri: 'tree://root/photos/a.jpg', name: 'a.jpg', length: 5),
      ];

      final result = await service.list('photos');

      expect(result, isA<FilesListed>());
      final entries = (result as FilesListed).entries;
      expect(entries.single.name, 'a.jpg');
      expect(entries.single.path, 'photos/a.jpg');
    });

    test('a read failure is worded', () async {
      saf.pickResult = _doc(uri: 'tree://root', name: 'Downloads', isDir: true);
      await service.pickFolder();
      saf.listError = Exception('gone');

      final result = await service.list('');

      expect(result, isA<FilesUnavailable>());
      expect((result as FilesUnavailable).reason, 'gone');
    });
  });

  group('delete', () {
    test('no folder picked', () async {
      expect(await service.delete('a.txt'), isA<DeleteFailed>());
    });

    test('deletes the resolved document', () async {
      saf.pickResult = _doc(uri: 'tree://root', name: 'Downloads', isDir: true);
      await service.pickFolder();
      saf.childrenByUri['tree://root'] = <SafDocumentFile>[
        _doc(uri: 'tree://root/a.txt', name: 'a.txt', length: 5),
      ];

      final result = await service.delete('a.txt');

      expect(result, isA<DeleteSucceeded>());
      expect(saf.deletedUris, <String>['tree://root/a.txt']);
    });

    test('a delete failure is worded', () async {
      saf.pickResult = _doc(uri: 'tree://root', name: 'Downloads', isDir: true);
      await service.pickFolder();
      saf.childrenByUri['tree://root'] = <SafDocumentFile>[
        _doc(uri: 'tree://root/a.txt', name: 'a.txt', length: 5),
      ];
      saf.deleteError = Exception('read-only');

      final result = await service.delete('a.txt');

      expect(result, isA<DeleteFailed>());
      expect((result as DeleteFailed).reason, 'read-only');
    });
  });
}
