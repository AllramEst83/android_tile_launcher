import 'package:android_tile_launcher/model/file_entry.dart';
import 'package:android_tile_launcher/model/file_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileTypeGroup', () {
    test('matches by extension, case-insensitively', () {
      expect(fileMatchesTypeGroup('a.JPG', FileTypeGroup.images), isTrue);
      expect(fileMatchesTypeGroup('a.jpg', FileTypeGroup.images), isTrue);
      expect(fileMatchesTypeGroup('a.mp4', FileTypeGroup.images), isFalse);
    });

    test('other is whatever matches no defined group', () {
      expect(fileMatchesTypeGroup('a.xyz', FileTypeGroup.other), isTrue);
      expect(fileMatchesTypeGroup('noext', FileTypeGroup.other), isTrue);
      expect(fileMatchesTypeGroup('a.jpg', FileTypeGroup.other), isFalse);
    });

    test('a trailing dot with nothing after it has no extension', () {
      expect(fileMatchesTypeGroup('a.', FileTypeGroup.other), isTrue);
    });

    test('every group has a distinct label', () {
      final labels = FileTypeGroup.values.map((g) => g.label).toSet();
      expect(labels, hasLength(FileTypeGroup.values.length));
    });
  });

  group('FileAgeFilter', () {
    final DateTime now = DateTime(2026, 9, 27);

    test('days/weeks/months/years subtract from now', () {
      expect(
        const FileAgeFilter(
          3,
          FileAgeUnit.days,
          FileAgeDirection.older,
        ).cutoff(now),
        DateTime(2026, 9, 24),
      );
      expect(
        const FileAgeFilter(
          2,
          FileAgeUnit.weeks,
          FileAgeDirection.older,
        ).cutoff(now),
        DateTime(2026, 9, 13),
      );
      expect(
        const FileAgeFilter(
          1,
          FileAgeUnit.months,
          FileAgeDirection.older,
        ).cutoff(now),
        DateTime(2026, 8, 27),
      );
      expect(
        const FileAgeFilter(
          1,
          FileAgeUnit.years,
          FileAgeDirection.older,
        ).cutoff(now),
        DateTime(2025, 9, 27),
      );
    });

    test('equality is by value', () {
      expect(
        const FileAgeFilter(1, FileAgeUnit.days, FileAgeDirection.older),
        const FileAgeFilter(1, FileAgeUnit.days, FileAgeDirection.older),
      );
      expect(
        const FileAgeFilter(1, FileAgeUnit.days, FileAgeDirection.older),
        isNot(const FileAgeFilter(2, FileAgeUnit.days, FileAgeDirection.older)),
      );
    });
  });

  group('FileFilter', () {
    test('isEmpty is true only with nothing set', () {
      expect(const FileFilter().isEmpty, isTrue);
      expect(const FileFilter(text: 'a').isEmpty, isFalse);
      expect(const FileFilter(type: FileTypeGroup.images).isEmpty, isFalse);
      expect(
        FileFilter(
          age: const FileAgeFilter(1, FileAgeUnit.days, FileAgeDirection.older),
        ).isEmpty,
        isFalse,
      );
    });

    test('withoutX clears only that field', () {
      final filter = FileFilter(
        text: 'a',
        type: FileTypeGroup.images,
        age: const FileAgeFilter(1, FileAgeUnit.days, FileAgeDirection.older),
      );

      expect(filter.withoutText().text, '');
      expect(filter.withoutText().type, FileTypeGroup.images);
      expect(filter.withoutType().type, isNull);
      expect(filter.withoutType().text, 'a');
      expect(filter.withoutAge().age, isNull);
      expect(filter.withoutAge().text, 'a');
    });
  });

  group('applyFileFilter', () {
    final DateTime now = DateTime(2026, 9, 27);
    const FileEntry folder = FileEntry(
      name: 'Photos',
      path: '/Photos',
      isDirectory: true,
      sizeBytes: 0,
    );
    final FileEntry oldImage = FileEntry(
      name: 'old.jpg',
      path: '/old.jpg',
      isDirectory: false,
      sizeBytes: 100,
      modified: DateTime(2026, 1, 1),
    );
    final FileEntry newDoc = FileEntry(
      name: 'new.pdf',
      path: '/new.pdf',
      isDirectory: false,
      sizeBytes: 200,
      modified: DateTime(2026, 9, 26),
    );
    final List<FileEntry> entries = <FileEntry>[folder, oldImage, newDoc];

    test('an empty filter changes nothing', () {
      expect(applyFileFilter(entries, const FileFilter(), now: now), entries);
    });

    test('text matches the name, case-insensitively, anywhere in it', () {
      expect(
        applyFileFilter(entries, const FileFilter(text: 'PHO'), now: now),
        <FileEntry>[folder],
      );
    });

    test('a type filter excludes folders entirely', () {
      final result = applyFileFilter(
        entries,
        const FileFilter(type: FileTypeGroup.images),
        now: now,
      );

      expect(result, <FileEntry>[oldImage]);
    });

    test('an age filter keeps only entries with a known modified date', () {
      const FileEntry noDate = FileEntry(
        name: 'mystery.txt',
        path: '/mystery.txt',
        isDirectory: false,
        sizeBytes: 5,
      );
      final result = applyFileFilter(
        <FileEntry>[oldImage, noDate],
        FileFilter(
          age: const FileAgeFilter(
            1,
            FileAgeUnit.months,
            FileAgeDirection.older,
          ),
        ),
        now: now,
      );

      expect(result, <FileEntry>[oldImage]);
    });

    test('OLDER THAN and NEWER THAN pick opposite sides of the cutoff', () {
      final older = applyFileFilter(
        <FileEntry>[oldImage, newDoc],
        FileFilter(
          age: const FileAgeFilter(
            1,
            FileAgeUnit.months,
            FileAgeDirection.older,
          ),
        ),
        now: now,
      );
      final newer = applyFileFilter(
        <FileEntry>[oldImage, newDoc],
        FileFilter(
          age: const FileAgeFilter(
            1,
            FileAgeUnit.months,
            FileAgeDirection.newer,
          ),
        ),
        now: now,
      );

      expect(older, <FileEntry>[oldImage]);
      expect(newer, <FileEntry>[newDoc]);
    });

    test('every set field narrows further (AND)', () {
      final result = applyFileFilter(
        entries,
        const FileFilter(text: 'old', type: FileTypeGroup.documents),
        now: now,
      );

      expect(result, isEmpty);
    });
  });

  group('sortFiles', () {
    final FileEntry a = FileEntry(
      name: 'b.txt',
      path: '/b.txt',
      isDirectory: false,
      sizeBytes: 300,
      modified: DateTime(2026, 9, 10),
    );
    final FileEntry b = FileEntry(
      name: 'a.txt',
      path: '/a.txt',
      isDirectory: false,
      sizeBytes: 100,
      modified: DateTime(2026, 9, 20),
    );
    const FileEntry noDate = FileEntry(
      name: 'c.txt',
      path: '/c.txt',
      isDirectory: false,
      sizeBytes: 200,
    );

    test('by name, ascending is A-Z', () {
      final sorted = sortFiles(
        <FileEntry>[a, b],
        key: FileSortKey.name,
        ascending: true,
      );

      expect(sorted, <FileEntry>[b, a]);
    });

    test('by modified, descending (default) is newest first', () {
      final sorted = sortFiles(
        <FileEntry>[a, b],
        key: FileSortKey.modified,
        ascending: false,
      );

      expect(sorted, <FileEntry>[b, a]);
    });

    test('by size, ascending is smallest first', () {
      final sorted = sortFiles(
        <FileEntry>[a, b],
        key: FileSortKey.size,
        ascending: true,
      );

      expect(sorted, <FileEntry>[b, a]);
    });

    test('an unknown modified date always sorts as the oldest', () {
      final ascending = sortFiles(
        <FileEntry>[a, noDate],
        key: FileSortKey.modified,
        ascending: true,
      );
      final descending = sortFiles(
        <FileEntry>[a, noDate],
        key: FileSortKey.modified,
        ascending: false,
      );

      expect(ascending.first, noDate);
      expect(descending.last, noDate);
    });

    test('every sort key has its own label', () {
      final labels = FileSortKey.values.map((k) => k.label).toSet();
      expect(labels, hasLength(FileSortKey.values.length));
    });
  });
}
