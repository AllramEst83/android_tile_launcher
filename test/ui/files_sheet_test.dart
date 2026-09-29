import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/file_entry.dart';
import 'package:android_tile_launcher/services/files_service.dart';
import 'package:android_tile_launcher/ui/files_sheet.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_files_service.dart';

Future<void> _open(WidgetTester tester, FakeFilesService service) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showFilesSheet(context, service: service),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('with no access yet', () {
    testWidgets('offers to allow it', (WidgetTester tester) async {
      await _open(tester, FakeFilesService());

      expect(find.text(Messages.filesTapToAllow), findsOneWidget);
    });

    testWidgets('granting it shows the storage volumes', (
      WidgetTester tester,
    ) async {
      final service = FakeFilesService()
        ..accessResult = const AccessGranted()
        ..rootsResult = const FilesListed(<FileEntry>[
          FileEntry(
            name: 'INTERNAL STORAGE',
            path: '/storage/emulated/0',
            isDirectory: true,
            sizeBytes: 0,
          ),
        ]);
      await _open(tester, service);

      await tester.tap(find.byKey(filesAllowKey));
      await tester.pumpAndSettle();

      expect(service.requestCalls, 1);
      expect(find.text('INTERNAL STORAGE'), findsOneWidget);
      // The top level itself is not something to delete.
      expect(find.byKey(filesDeleteKey('/storage/emulated/0')), findsNothing);
    });

    testWidgets('backing out of settings changes nothing', (
      WidgetTester tester,
    ) async {
      final service = FakeFilesService()..accessResult = const AccessDenied();
      await _open(tester, service);

      await tester.tap(find.byKey(filesAllowKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.filesTapToAllow), findsOneWidget);
    });
  });

  group('with access granted', () {
    FakeFilesService withEntries() => FakeFilesService()
      ..access = true
      ..rootsResult = const FilesListed(<FileEntry>[
        FileEntry(
          name: 'INTERNAL STORAGE',
          path: '/storage/emulated/0',
          isDirectory: true,
          sizeBytes: 0,
        ),
        FileEntry(
          name: 'SD CARD',
          path: '/storage/AAAA-1111',
          isDirectory: true,
          sizeBytes: 0,
        ),
      ])
      ..resultsByPath['/storage/emulated/0'] = const FilesListed(<FileEntry>[
        FileEntry(
          name: 'Photos',
          path: '/storage/emulated/0/Photos',
          isDirectory: true,
          sizeBytes: 0,
        ),
        FileEntry(
          name: 'report.pdf',
          path: '/storage/emulated/0/report.pdf',
          isDirectory: false,
          sizeBytes: 42000,
        ),
      ])
      ..resultsByPath['/storage/emulated/0/Photos'] = const FilesListed(
        <FileEntry>[
          FileEntry(
            name: 'a.jpg',
            path: '/storage/emulated/0/Photos/a.jpg',
            isDirectory: false,
            sizeBytes: 5000,
          ),
        ],
      );

    testWidgets('lists the storage volumes at the top', (
      WidgetTester tester,
    ) async {
      await _open(tester, withEntries());

      expect(find.text('INTERNAL STORAGE'), findsOneWidget);
      expect(find.text('SD CARD'), findsOneWidget);
      expect(find.byKey(filesBackKey), findsNothing);
    });

    testWidgets('opening a volume browses into it, and BACK returns', (
      WidgetTester tester,
    ) async {
      await _open(tester, withEntries());

      await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
      await tester.pumpAndSettle();

      expect(find.text('PHOTOS'), findsOneWidget);
      expect(find.text('REPORT.PDF'), findsOneWidget);
      expect(find.text('42 KB'), findsOneWidget);
      expect(find.byKey(filesBackKey), findsOneWidget);

      await tester.tap(find.byKey(filesBackKey));
      await tester.pumpAndSettle();

      expect(find.text('INTERNAL STORAGE'), findsOneWidget);
      expect(find.byKey(filesBackKey), findsNothing);
    });

    testWidgets('descending two levels and BACK twice returns to the top', (
      WidgetTester tester,
    ) async {
      await _open(tester, withEntries());

      await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(filesRowKey('/storage/emulated/0/Photos')));
      await tester.pumpAndSettle();

      expect(find.text('A.JPG'), findsOneWidget);

      await tester.tap(find.byKey(filesBackKey));
      await tester.pumpAndSettle();
      expect(find.text('PHOTOS'), findsOneWidget);

      await tester.tap(find.byKey(filesBackKey));
      await tester.pumpAndSettle();
      expect(find.text('INTERNAL STORAGE'), findsOneWidget);
      expect(find.byKey(filesBackKey), findsNothing);
    });

    testWidgets('deleting asks first, and NO keeps it', (
      WidgetTester tester,
    ) async {
      final service = withEntries();
      await _open(tester, service);
      await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(filesDeleteKey('/storage/emulated/0/report.pdf')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(filesAskKey), findsOneWidget);

      await tester.tap(find.byKey(filesNoKey));
      await tester.pumpAndSettle();

      expect(service.deletedPaths, isEmpty);
      expect(find.text('REPORT.PDF'), findsOneWidget);
    });

    testWidgets('YES deletes it and the list re-reads', (
      WidgetTester tester,
    ) async {
      final service = withEntries();
      await _open(tester, service);
      await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(filesDeleteKey('/storage/emulated/0/report.pdf')),
      );
      await tester.pumpAndSettle();
      // The list re-reads after a delete; make the second read reflect it.
      service.resultsByPath['/storage/emulated/0'] = const FilesListed(
        <FileEntry>[
          FileEntry(
            name: 'Photos',
            path: '/storage/emulated/0/Photos',
            isDirectory: true,
            sizeBytes: 0,
          ),
        ],
      );

      await tester.tap(find.byKey(filesYesKey));
      await tester.pumpAndSettle();

      expect(service.deletedPaths, <String>['/storage/emulated/0/report.pdf']);
      expect(find.text('REPORT.PDF'), findsNothing);
    });

    testWidgets('a delete failure is said, without losing the list', (
      WidgetTester tester,
    ) async {
      final service = withEntries()
        ..deleteResult = const DeleteFailed('locked');
      await _open(tester, service);
      await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(filesDeleteKey('/storage/emulated/0/report.pdf')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(filesYesKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.filesDeleteFailed), findsOneWidget);
    });

    testWidgets(
      'a name too long for the row is shortened in the middle, not the end '
      '— the extension stays readable',
      (WidgetTester tester) async {
        final String longName = '${'x' * 60}.mp4';
        final service = FakeFilesService()
          ..access = true
          ..rootsResult = FilesListed(<FileEntry>[
            FileEntry(
              name: 'INTERNAL STORAGE',
              path: '/root',
              isDirectory: true,
              sizeBytes: 0,
            ),
          ])
          ..resultsByPath['/root'] = FilesListed(<FileEntry>[
            FileEntry(
              name: longName,
              path: '/root/$longName',
              isDirectory: false,
              sizeBytes: 1000,
            ),
          ]);
        await _open(tester, service);
        await tester.tap(find.byKey(filesRowKey('/root')));
        await tester.pumpAndSettle();

        expect(find.text(longName.toUpperCase()), findsNothing);
        final Text shown = tester.widget<Text>(
          find.descendant(
            of: find.byKey(filesRowKey('/root/$longName')),
            matching: find.textContaining('.MP4'),
          ),
        );
        final String data = shown.data!;
        expect(data, contains('...'));
        expect(data, endsWith('.MP4'));
        expect(data.length, lessThan(longName.length));
      },
    );

    testWidgets('an empty folder says so', (WidgetTester tester) async {
      final service = FakeFilesService()
        ..access = true
        ..rootsResult = FilesListed(<FileEntry>[
          const FileEntry(
            name: 'INTERNAL STORAGE',
            path: '/root',
            isDirectory: true,
            sizeBytes: 0,
          ),
        ])
        ..resultsByPath['/root'] = const FilesListed(<FileEntry>[]);
      await _open(tester, service);

      await tester.tap(find.byKey(filesRowKey('/root')));
      await tester.pumpAndSettle();

      expect(find.text(Messages.filesEmpty), findsOneWidget);
    });

    testWidgets('a read failure is said', (WidgetTester tester) async {
      final service = FakeFilesService()
        ..access = true
        ..rootsResult = FilesListed(<FileEntry>[
          const FileEntry(
            name: 'INTERNAL STORAGE',
            path: '/root',
            isDirectory: true,
            sizeBytes: 0,
          ),
        ])
        ..resultsByPath['/root'] = const FilesUnavailable(
          'that folder is gone',
        );
      await _open(tester, service);

      await tester.tap(find.byKey(filesRowKey('/root')));
      await tester.pumpAndSettle();

      expect(find.text('THAT FOLDER IS GONE'), findsOneWidget);
    });

    testWidgets('no storage found is said', (WidgetTester tester) async {
      final service = FakeFilesService()
        ..access = true
        ..rootsResult = const FilesUnavailable('no storage found');
      await _open(tester, service);

      expect(find.text('NO STORAGE FOUND'), findsOneWidget);
    });
  });

  group('closing', () {
    testWidgets('X closes the sheet', (WidgetTester tester) async {
      await _open(tester, FakeFilesService());
      expect(find.text(Messages.filesTitle), findsOneWidget);

      await tester.tap(find.byKey(filesCloseKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.filesTitle), findsNothing);
    });
  });
}
