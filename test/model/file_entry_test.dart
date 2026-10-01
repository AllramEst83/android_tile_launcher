import 'package:android_tile_launcher/model/file_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('equality and hashCode cover every field', () {
    final DateTime modified = DateTime(2026, 9, 20);
    const FileEntry a = FileEntry(
      name: 'a.txt',
      path: '/a.txt',
      isDirectory: false,
      sizeBytes: 10,
    );
    final FileEntry b = FileEntry(
      name: 'a.txt',
      path: '/a.txt',
      isDirectory: false,
      sizeBytes: 10,
      modified: modified,
    );

    expect(a, isNot(b));
    expect(
      FileEntry(
        name: 'a.txt',
        path: '/a.txt',
        isDirectory: false,
        sizeBytes: 10,
        modified: modified,
      ),
      b,
    );
    expect(
      FileEntry(
            name: 'a.txt',
            path: '/a.txt',
            isDirectory: false,
            sizeBytes: 10,
            modified: modified,
          ).hashCode ==
          b.hashCode,
      isTrue,
    );
  });

  test('modified and itemCount default to null', () {
    const FileEntry entry = FileEntry(
      name: 'a.txt',
      path: '/a.txt',
      isDirectory: false,
      sizeBytes: 10,
    );

    expect(entry.modified, isNull);
    expect(entry.itemCount, isNull);
  });
}
