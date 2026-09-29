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
  });

  final String name;

  /// Slash-separated, relative to the picked folder's own root (`""`); how
  /// [FilesService.list] and [FilesService.delete] name an entry.
  final String path;
  final bool isDirectory;
  final int sizeBytes;

  @override
  bool operator ==(Object other) =>
      other is FileEntry &&
      other.name == name &&
      other.path == path &&
      other.isDirectory == isDirectory &&
      other.sizeBytes == sizeBytes;

  @override
  int get hashCode => Object.hash(name, path, isDirectory, sizeBytes);

  @override
  String toString() =>
      'FileEntry($path, ${isDirectory ? 'dir' : '$sizeBytes bytes'})';
}
