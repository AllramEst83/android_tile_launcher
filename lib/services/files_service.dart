import 'package:android_tile_launcher/model/file_entry.dart';

/// What listing a folder came back with.
sealed class FilesResult {
  const FilesResult();
}

/// [entries] is everything directly inside the folder asked for (not
/// recursive) — folders first, then files, each already sorted biggest
/// first within its own group.
class FilesListed extends FilesResult {
  const FilesListed(this.entries);

  final List<FileEntry> entries;
}

/// No folder has been picked yet (or it's since been revoked, e.g. from
/// Android's own storage settings) — [FilesService.pickFolder] is how the
/// user gives access.
class FilesNoFolder extends FilesResult {
  const FilesNoFolder();
}

/// The folder — or the path asked for inside it — could not be read;
/// [reason] is short.
class FilesUnavailable extends FilesResult {
  const FilesUnavailable(this.reason);

  final String reason;
}

/// What asking the user to pick a folder came back with.
sealed class PickFolderResult {
  const PickFolderResult();
}

class FolderPicked extends PickFolderResult {
  const FolderPicked();
}

/// The user backed out of the system picker without choosing anything —
/// nothing changed, not a failure.
class FolderPickCancelled extends PickFolderResult {
  const FolderPickCancelled();
}

class FolderPickFailed extends PickFolderResult {
  const FolderPickFailed(this.reason);

  final String reason;
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

/// A lightweight disk-usage utility: the user picks one folder (Android's own
/// folder picker, not a broad "all files" permission) and this browses and
/// deletes inside it. Never throws: every failure is a typed result the sheet
/// can word.
abstract interface class FilesService {
  /// Whether a folder has already been picked and access to it still holds.
  Future<bool> hasFolder();

  /// Opens Android's own folder picker. Only ever called from a tap: the
  /// system UI it opens must never appear on its own.
  Future<PickFolderResult> pickFolder();

  /// Gives up access to the picked folder, so [hasFolder] is false again and
  /// the sheet can offer to pick a different one.
  Future<void> forgetFolder();

  /// The entries directly inside [path] (`""` for the picked folder's own
  /// root), slash-separated and relative to it.
  Future<FilesResult> list(String path);

  /// Deletes the file or folder (and everything under it) at [path].
  Future<DeleteResult> delete(String path);
}
