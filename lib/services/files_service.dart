import 'package:android_tile_launcher/model/file_entry.dart';

/// What listing a folder (or the top-level list of storage roots) came back
/// with.
sealed class FilesResult {
  const FilesResult();
}

/// [entries] is everything directly inside the folder asked for (not
/// recursive) — folders first, then files, each already sorted biggest
/// first within its own group; or, from [FilesService.roots], one entry per
/// storage volume in whatever order the platform reports them.
class FilesListed extends FilesResult {
  const FilesListed(this.entries);

  final List<FileEntry> entries;
}

/// File access has not been granted yet (or was since revoked from
/// Android's own Settings) — [FilesService.requestAccess] is how the user
/// gives it.
class FilesNoAccess extends FilesResult {
  const FilesNoAccess();
}

/// The folder — or the path asked for inside it — could not be read;
/// [reason] is short.
class FilesUnavailable extends FilesResult {
  const FilesUnavailable(this.reason);

  final String reason;
}

/// What asking Android for file access came back with.
sealed class AccessResult {
  const AccessResult();
}

class AccessGranted extends AccessResult {
  const AccessGranted();
}

/// The user backed out of Android's own settings screen without turning it
/// on, or turned it off again — not necessarily a failure, just not granted.
class AccessDenied extends AccessResult {
  const AccessDenied();
}

/// Whether deleting one entry worked.
sealed class DeleteResult {
  const DeleteResult();
}

class DeleteSucceeded extends DeleteResult {
  const DeleteSucceeded();
}

class DeleteFailed extends DeleteResult {
  const DeleteFailed(this.reason);

  final String reason;
}

/// A disk-usage utility in the shape Android's own Files app is: one
/// permission ("all files access"), granted once from Android's own Settings
/// screen, then every storage volume on the phone (internal, an SD card, …)
/// is browsable and deletable as an ordinary file tree — not just one folder
/// picked through a document tree, the way this used to work. Never throws:
/// every failure is a typed result the sheet can word.
abstract interface class FilesService {
  /// Whether file access has already been granted.
  Future<bool> hasAccess();

  /// Opens Android's own "all files access" settings screen. Only ever
  /// called from a tap: the system UI it opens must never appear on its own.
  Future<AccessResult> requestAccess();

  /// One entry per storage volume on the phone (`INTERNAL STORAGE`, an SD
  /// card if there is one, …) — the file tree's own roots.
  Future<FilesResult> roots();

  /// The entries directly inside the folder at [path] (an absolute path, as
  /// [roots] or a previous [list] gave it).
  Future<FilesResult> list(String path);

  /// Deletes the file or folder (and everything under it) at [path].
  Future<DeleteResult> delete(String path);
}
