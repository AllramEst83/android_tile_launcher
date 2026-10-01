/// One file or folder inside the folder the user picked for the file
/// explorer. All times are local; a folder's own `sizeBytes` is `0` — this is
/// a lightweight utility, so it shows what fills the folders it opens rather
/// than a deep, recursive total of everything under them.
class FileEntry {
  const FileEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.sizeBytes,
    this.modified,
    this.itemCount,
  });

  final String name;

  /// Slash-separated, relative to the picked folder's own root (`""`); how
  /// [FilesService.list] and [FilesService.delete] name an entry.
  final String path;
  final bool isDirectory;
  final int sizeBytes;

  /// When it was last changed, local time; `null` only if the platform could
  /// not be asked (an unreadable entry, or a synthetic one like a storage
  /// root) — never left out just because this is a folder, unlike
  /// [sizeBytes].
  final DateTime? modified;

  /// How many entries are directly inside it; `null` for a file (meaningless)
  /// or a folder that could not be counted. Stands in for [sizeBytes], which
  /// a folder never gets a real value for.
  final int? itemCount;

  @override
  bool operator ==(Object other) =>
      other is FileEntry &&
      other.name == name &&
      other.path == path &&
      other.isDirectory == isDirectory &&
      other.sizeBytes == sizeBytes &&
      other.modified == modified &&
      other.itemCount == itemCount;

  @override
  int get hashCode =>
      Object.hash(name, path, isDirectory, sizeBytes, modified, itemCount);

  @override
  String toString() =>
      'FileEntry($path, ${isDirectory ? 'dir' : '$sizeBytes bytes'}, '
      'modified: $modified, itemCount: $itemCount)';
}
