import 'package:android_tile_launcher/services/files_service.dart';

/// Answers with whatever the test sets, and remembers what was asked for.
class FakeFilesService implements FilesService {
  bool folder = false;
  PickFolderResult pickResult = const FolderPicked();
  Map<String, FilesResult> resultsByPath = <String, FilesResult>{};
  DeleteResult deleteResult = const DeleteSucceeded();

  int pickCalls = 0;
  int forgetCalls = 0;
  final List<String> deletedPaths = <String>[];

  @override
  Future<bool> hasFolder() async => folder;

  @override
  Future<PickFolderResult> pickFolder() async {
    pickCalls++;
    if (pickResult is FolderPicked) folder = true;
    return pickResult;
  }

  @override
  Future<void> forgetFolder() async {
    forgetCalls++;
    folder = false;
  }

  @override
  Future<FilesResult> list(String path) async =>
      resultsByPath[path] ?? const FilesUnavailable('not set up in test');

  @override
  Future<DeleteResult> delete(String path) async {
    deletedPaths.add(path);
    return deleteResult;
  }
}
