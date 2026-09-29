import 'package:android_tile_launcher/model/file_entry.dart';
import 'package:android_tile_launcher/services/files_service.dart';

/// Answers with whatever the test sets, and remembers what was asked for.
class FakeFilesService implements FilesService {
  bool access = false;
  AccessResult accessResult = const AccessGranted();
  FilesResult rootsResult = const FilesListed(<FileEntry>[]);
  Map<String, FilesResult> resultsByPath = <String, FilesResult>{};
  DeleteResult deleteResult = const DeleteSucceeded();

  int requestCalls = 0;
  final List<String> deletedPaths = <String>[];

  @override
  Future<bool> hasAccess() async => access;

  @override
  Future<AccessResult> requestAccess() async {
    requestCalls++;
    if (accessResult is AccessGranted) access = true;
    return accessResult;
  }

  @override
  Future<FilesResult> roots() async => rootsResult;

  @override
  Future<FilesResult> list(String path) async =>
      resultsByPath[path] ?? const FilesUnavailable('not set up in test');

  @override
  Future<DeleteResult> delete(String path) async {
    deletedPaths.add(path);
    return deleteResult;
  }
}
