import 'package:android_tile_launcher/model/file_entry.dart';
import 'package:android_tile_launcher/services/files_service.dart';
import 'package:android_tile_launcher/services/local_store.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
import 'package:saf_util/saf_util.dart';
import 'package:saf_util/saf_util_platform_interface.dart' show SafDocumentFile;

/// [FilesService] on `package:saf_util` (Android's Storage Access Framework:
/// the user picks one folder through the system's own picker, this app never
/// gets broader access than that) and a [LocalStore] for the one thing SAF
/// itself doesn't remember across launches — *which* folder was picked. The
/// only file that knows about the package.
class AndroidFilesService implements FilesService {
  // Not `this._store`: that would make the parameter name the private
  // `_store`, which a caller in another file could not pass by name.
  AndroidFilesService({required LocalStore store, SafUtil? saf})
    // ignore: prefer_initializing_formals
    : _store = store,
      _saf = saf ?? SafUtil();

  static const String storeKey = 'filesRootUri';

  final LocalStore _store;
  final SafUtil _saf;

  Future<String?> _rootUri() async {
    final Object? saved;
    try {
      saved = await _store.read(storeKey);
    } on LocalStoreException {
      return null;
    }
    return saved is String ? saved : null;
  }

  @override
  Future<bool> hasFolder() async {
    final String? uri = await _rootUri();
    if (uri == null) return false;
    try {
      return await _saf.hasPersistedPermission(uri);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<PickFolderResult> pickFolder() async {
    final SafDocumentFile? picked;
    try {
      picked = await _saf.pickDirectory(
        writePermission: true,
        persistablePermission: true,
      );
    } catch (error) {
      return FolderPickFailed(_reason(error));
    }
    if (picked == null) return const FolderPickCancelled();
    try {
      await _store.write(storeKey, picked.uri);
    } on LocalStoreException {
      // The folder is still picked and usable this run; only remembering it
      // for next time failed.
    }
    return const FolderPicked();
  }

  @override
  Future<void> forgetFolder() async {
    final String? uri = await _rootUri();
    if (uri != null) {
      try {
        await _saf.releasePersistedPermission(uri, write: true);
      } catch (_) {
        // Nothing sensible to do with a failure to give up access; forgetting
        // it locally below still stops this app offering to browse it.
      }
    }
    try {
      await _store.delete(storeKey);
    } on LocalStoreException {
      // Best effort; the next `hasFolder` may still say yes if this failed.
    }
  }

  @override
  Future<FilesResult> list(String path) async {
    final String? root = await _rootUri();
    if (root == null) return const FilesNoFolder();
    try {
      final String? targetUri = await _resolve(root, path);
      if (targetUri == null) {
        return const FilesUnavailable('that folder is gone');
      }
      final List<SafDocumentFile> children = await _saf.list(targetUri);
      final List<FileEntry> entries = <FileEntry>[
        for (final SafDocumentFile child in children)
          FileEntry(
            name: child.name,
            path: path.isEmpty ? child.name : '$path/${child.name}',
            isDirectory: child.isDir,
            sizeBytes: child.isDir || child.length < 0 ? 0 : child.length,
          ),
      ];
      return FilesListed(_sorted(entries));
    } catch (error) {
      return FilesUnavailable(_reason(error));
    }
  }

  @override
  Future<DeleteResult> delete(String path) async {
    final String? root = await _rootUri();
    if (root == null) return const DeleteFailed('no folder picked');
    try {
      final SafDocumentFile? target = await _saf.child(root, path.split('/'));
      if (target == null) return const DeleteFailed('already gone');
      await _saf.delete(target.uri, target.isDir);
      return const DeleteSucceeded();
    } catch (error) {
      return DeleteFailed(_reason(error));
    }
  }

  /// The document at [path] (`""` is the picked folder's own root) under
  /// [root], resolved through `saf_util`'s own `child` rather than walking
  /// each segment by hand.
  Future<String?> _resolve(String root, String path) async {
    if (path.isEmpty) return root;
    final SafDocumentFile? child = await _saf.child(root, path.split('/'));
    return child?.uri;
  }

  /// Folders before files (browsing a tree reads better than a flat list
  /// sorted purely by size), biggest first within each — the size a reader
  /// most wants "what's taking up space" to answer.
  static List<FileEntry> _sorted(List<FileEntry> entries) {
    final List<FileEntry> sorted = List<FileEntry>.of(entries)
      ..sort((FileEntry a, FileEntry b) {
        if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
        return b.sizeBytes.compareTo(a.sizeBytes);
      });
    return sorted;
  }

  static String _reason(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
