import 'package:android_tile_launcher/model/file_entry.dart';

/// A broad category a file's name sorts into by its extension, for the FILTER
/// pane's TYPE chips — a tap, not a typed extension, so [other] is whatever
/// extension does not match one of the rest (or has none at all) rather than
/// its own list.
enum FileTypeGroup {
  images('IMAGES'),
  videos('VIDEOS'),
  audio('AUDIO'),
  documents('DOCUMENTS'),
  archives('ARCHIVES'),
  apks('APKS'),
  other('OTHER');

  const FileTypeGroup(this.label);

  final String label;
}

const Map<FileTypeGroup, Set<String>> _extensionsByGroup =
    <FileTypeGroup, Set<String>>{
      FileTypeGroup.images: <String>{
        'jpg',
        'jpeg',
        'png',
        'gif',
        'bmp',
        'webp',
        'heic',
        'heif',
        'svg',
      },
      FileTypeGroup.videos: <String>{
        'mp4',
        'mkv',
        'mov',
        'avi',
        'webm',
        '3gp',
        'm4v',
      },
      FileTypeGroup.audio: <String>{
        'mp3',
        'wav',
        'ogg',
        'm4a',
        'flac',
        'aac',
        'opus',
      },
      FileTypeGroup.documents: <String>{
        'pdf',
        'doc',
        'docx',
        'txt',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'odt',
        'rtf',
        'csv',
      },
      FileTypeGroup.archives: <String>{'zip', 'rar', '7z', 'tar', 'gz', 'bz2'},
      FileTypeGroup.apks: <String>{'apk'},
    };

/// The lower-cased extension in [name], without its dot; empty if there is
/// none.
String _extensionOf(String name) {
  final int dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return '';
  return name.substring(dot + 1).toLowerCase();
}

/// Whether [name] belongs to [group] — every other group by its own known
/// extensions, [FileTypeGroup.other] by matching none of them.
bool fileMatchesTypeGroup(String name, FileTypeGroup group) {
  final String extension = _extensionOf(name);
  if (group == FileTypeGroup.other) {
    return !_extensionsByGroup.values.any((Set<String> set) {
      return set.contains(extension);
    });
  }
  return _extensionsByGroup[group]?.contains(extension) ?? false;
}

/// A unit a MODIFIED cutoff counts in, the same shape mail's own age filter
/// uses.
enum FileAgeUnit {
  days('DAYS'),
  weeks('WEEKS'),
  months('MONTHS'),
  years('YEARS');

  const FileAgeUnit(this.label);

  final String label;
}

/// Which side of the cutoff an age filter keeps.
enum FileAgeDirection { older, newer }

/// How far back or forward a MODIFIED cutoff reaches, and which side of it
/// keeps.
class FileAgeFilter {
  const FileAgeFilter(this.amount, this.unit, this.direction);

  final int amount;
  final FileAgeUnit unit;
  final FileAgeDirection direction;

  /// The cutoff date, given [now]: with [FileAgeDirection.older] an entry
  /// modified before this passes; with [FileAgeDirection.newer] one modified
  /// at or after it does.
  DateTime cutoff(DateTime now) => switch (unit) {
    FileAgeUnit.days => now.subtract(Duration(days: amount)),
    FileAgeUnit.weeks => now.subtract(Duration(days: amount * 7)),
    FileAgeUnit.months => DateTime(now.year, now.month - amount, now.day),
    FileAgeUnit.years => DateTime(now.year - amount, now.month, now.day),
  };

  @override
  bool operator ==(Object other) =>
      other is FileAgeFilter &&
      other.amount == amount &&
      other.unit == unit &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(amount, unit, direction);

  @override
  String toString() => 'FileAgeFilter($amount ${unit.label} ${direction.name})';
}

/// A filter over a folder's entries: free text (matches the name), a
/// [FileTypeGroup] (files only — a folder never matches a type filter), and/or
/// a MODIFIED cutoff. Every field that is set narrows the results further
/// (AND); [isEmpty] means no filtering.
class FileFilter {
  const FileFilter({this.text = '', this.type, this.age});

  final String text;
  final FileTypeGroup? type;
  final FileAgeFilter? age;

  bool get isEmpty => text.isEmpty && type == null && age == null;

  FileFilter withoutText() => FileFilter(type: type, age: age);
  FileFilter withoutType() => FileFilter(text: text, age: age);
  FileFilter withoutAge() => FileFilter(text: text, type: type);

  @override
  bool operator ==(Object other) =>
      other is FileFilter &&
      other.text == text &&
      other.type == type &&
      other.age == age;

  @override
  int get hashCode => Object.hash(text, type, age);

  @override
  String toString() => 'FileFilter(text: $text, type: $type, age: $age)';
}

/// [entries] narrowed by [filter], given [now] for its age cutoff (if any).
/// An empty filter returns [entries] unchanged.
List<FileEntry> applyFileFilter(
  List<FileEntry> entries,
  FileFilter filter, {
  required DateTime now,
}) {
  if (filter.isEmpty) return entries;
  return <FileEntry>[
    for (final FileEntry entry in entries)
      if (_matches(entry, filter, now)) entry,
  ];
}

bool _matches(FileEntry entry, FileFilter filter, DateTime now) {
  if (filter.text.isNotEmpty &&
      !entry.name.toLowerCase().contains(filter.text.toLowerCase())) {
    return false;
  }
  final FileTypeGroup? type = filter.type;
  if (type != null) {
    if (entry.isDirectory) return false;
    if (!fileMatchesTypeGroup(entry.name, type)) return false;
  }
  final FileAgeFilter? age = filter.age;
  if (age != null) {
    final DateTime? modified = entry.modified;
    if (modified == null) return false;
    final DateTime cutoff = age.cutoff(now);
    final bool passes = age.direction == FileAgeDirection.older
        ? modified.isBefore(cutoff)
        : !modified.isBefore(cutoff);
    if (!passes) return false;
  }
  return true;
}

/// Which column a folder's listing is sorted by.
enum FileSortKey {
  name('NAME'),
  modified('MODIFIED'),
  size('SIZE');

  const FileSortKey(this.label);

  final String label;
}

/// [entries] sorted by [key], folders and files mixed together (a "what
/// changed recently" browsing order by default, not the old folders-first
/// disk-usage order) — reversed when [ascending] is false. An entry with no
/// [FileEntry.modified] (sorting by [FileSortKey.modified] only) always sorts
/// as the oldest, whichever direction is chosen.
List<FileEntry> sortFiles(
  List<FileEntry> entries, {
  required FileSortKey key,
  required bool ascending,
}) {
  final List<FileEntry> sorted = List<FileEntry>.of(entries)
    ..sort((FileEntry a, FileEntry b) {
      final int cmp = switch (key) {
        FileSortKey.name => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ),
        FileSortKey.modified => _compareModified(a.modified, b.modified),
        FileSortKey.size => a.sizeBytes.compareTo(b.sizeBytes),
      };
      return ascending ? cmp : -cmp;
    });
  return sorted;
}

int _compareModified(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return -1;
  if (b == null) return 1;
  return a.compareTo(b);
}
