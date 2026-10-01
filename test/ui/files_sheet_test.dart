import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/file_entry.dart';
import 'package:android_tile_launcher/model/file_filter.dart';
import 'package:android_tile_launcher/services/files_service.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/ui/files_filter_sheet.dart';
import 'package:android_tile_launcher/ui/files_sheet.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_files_service.dart';
import '../fakes/in_memory_local_store.dart';

Future<SettingsState> _open(
  WidgetTester tester,
  FakeFilesService service, {
  SettingsState? settings,
}) async {
  // A phone-tall viewport: the FILTER pane's text field, TYPE chips,
  // OLDER/NEWER toggle, unit chips and APPLY/CLEAR row do not all fit the
  // default 800x600 test surface, so a tap on a button near its bottom
  // misses (off the root render tree entirely) without this.
  tester.view
    ..physicalSize = const Size(400, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final SettingsState state =
      settings ?? SettingsState(store: InMemoryLocalStore());
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () =>
              showFilesSheet(context, service: service, settings: state),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return state;
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
    DateTime d(int day) => DateTime(2026, 9, day);

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
      ..resultsByPath['/storage/emulated/0'] = FilesListed(<FileEntry>[
        FileEntry(
          name: 'Photos',
          path: '/storage/emulated/0/Photos',
          isDirectory: true,
          sizeBytes: 0,
          modified: d(10),
          itemCount: 1,
        ),
        FileEntry(
          name: 'report.pdf',
          path: '/storage/emulated/0/report.pdf',
          isDirectory: false,
          sizeBytes: 42000,
          modified: d(20),
        ),
      ])
      ..resultsByPath['/storage/emulated/0/Photos'] = FilesListed(<FileEntry>[
        FileEntry(
          name: 'a.jpg',
          path: '/storage/emulated/0/Photos/a.jpg',
          isDirectory: false,
          sizeBytes: 5000,
          modified: d(10),
        ),
      ]);

    testWidgets('lists the storage volumes at the top', (
      WidgetTester tester,
    ) async {
      await _open(tester, withEntries());

      expect(find.text('INTERNAL STORAGE'), findsOneWidget);
      expect(find.text('SD CARD'), findsOneWidget);
      expect(find.byKey(filesCrumbKey(null)), findsNothing);
    });

    testWidgets(
      'opening a volume browses into it, and the breadcrumb returns',
      (WidgetTester tester) async {
        await _open(tester, withEntries());

        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
        await tester.pumpAndSettle();

        expect(find.text('PHOTOS'), findsOneWidget);
        expect(find.text('REPORT.PDF'), findsOneWidget);
        expect(find.text('42 KB'), findsOneWidget);
        expect(find.byKey(filesCrumbKey(null)), findsOneWidget);

        await tester.tap(find.byKey(filesCrumbKey(null)));
        await tester.pumpAndSettle();

        expect(find.text('INTERNAL STORAGE'), findsOneWidget);
        expect(find.byKey(filesCrumbKey(null)), findsNothing);
      },
    );

    testWidgets(
      'descending two levels and tapping the root crumb jumps straight back',
      (WidgetTester tester) async {
        await _open(tester, withEntries());

        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0/Photos')));
        await tester.pumpAndSettle();

        expect(find.text('A.JPG'), findsOneWidget);
        expect(
          find.byKey(filesCrumbKey('/storage/emulated/0')),
          findsOneWidget,
        );

        // One tap on the root crumb, not two BACKs.
        await tester.tap(find.byKey(filesCrumbKey(null)));
        await tester.pumpAndSettle();

        expect(find.text('INTERNAL STORAGE'), findsOneWidget);
        expect(find.byKey(filesCrumbKey(null)), findsNothing);
      },
    );

    testWidgets(
      'descending two levels and tapping the middle crumb goes up one',
      (WidgetTester tester) async {
        await _open(tester, withEntries());

        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0/Photos')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(filesCrumbKey('/storage/emulated/0')));
        await tester.pumpAndSettle();

        expect(find.text('PHOTOS'), findsOneWidget);
        expect(find.text('A.JPG'), findsNothing);
      },
    );

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
      service.resultsByPath['/storage/emulated/0'] = FilesListed(<FileEntry>[
        FileEntry(
          name: 'Photos',
          path: '/storage/emulated/0/Photos',
          isDirectory: true,
          sizeBytes: 0,
          modified: d(10),
        ),
      ]);

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

    group('sorting', () {
      testWidgets('defaults to MODIFIED, newest first', (
        WidgetTester tester,
      ) async {
        await _open(tester, withEntries());
        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
        await tester.pumpAndSettle();

        // report.pdf (day 20) is newer than Photos (day 10).
        final double reportTop = tester
            .getTopLeft(
              find.byKey(filesRowKey('/storage/emulated/0/report.pdf')),
            )
            .dy;
        final double photosTop = tester
            .getTopLeft(find.byKey(filesRowKey('/storage/emulated/0/Photos')))
            .dy;
        expect(reportTop, lessThan(photosTop));
      });

      testWidgets('tapping NAME sorts alphabetically, A-Z', (
        WidgetTester tester,
      ) async {
        await _open(tester, withEntries());
        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(filesSortHeaderKey(FileSortKey.name)));
        await tester.pumpAndSettle();

        final double photosTop = tester
            .getTopLeft(find.byKey(filesRowKey('/storage/emulated/0/Photos')))
            .dy;
        final double reportTop = tester
            .getTopLeft(
              find.byKey(filesRowKey('/storage/emulated/0/report.pdf')),
            )
            .dy;
        // 'Photos' < 'report.pdf' case-insensitively.
        expect(photosTop, lessThan(reportTop));
      });

      testWidgets('tapping the same header again flips the direction', (
        WidgetTester tester,
      ) async {
        await _open(tester, withEntries());
        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(filesSortHeaderKey(FileSortKey.name)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(filesSortHeaderKey(FileSortKey.name)));
        await tester.pumpAndSettle();

        final double photosTop = tester
            .getTopLeft(find.byKey(filesRowKey('/storage/emulated/0/Photos')))
            .dy;
        final double reportTop = tester
            .getTopLeft(
              find.byKey(filesRowKey('/storage/emulated/0/report.pdf')),
            )
            .dy;
        expect(reportTop, lessThan(photosTop));
      });

      testWidgets('the chosen sort is remembered in settings', (
        WidgetTester tester,
      ) async {
        final SettingsState settings = SettingsState(
          store: InMemoryLocalStore(),
        );
        await _open(tester, withEntries(), settings: settings);
        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(filesSortHeaderKey(FileSortKey.name)));
        await tester.pumpAndSettle();

        expect(settings.settings.fileSortKey, FileSortKey.name);
        expect(settings.settings.fileSortAscending, isTrue);
      });
    });

    group('search and filter', () {
      testWidgets('typing in SEARCH narrows the list by name', (
        WidgetTester tester,
      ) async {
        await _open(tester, withEntries());
        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(filesSearchKey), 'report');
        await tester.pumpAndSettle();

        expect(find.text('REPORT.PDF'), findsOneWidget);
        expect(find.text('PHOTOS'), findsNothing);
      });

      testWidgets('no matches says so, distinct from an empty folder', (
        WidgetTester tester,
      ) async {
        await _open(tester, withEntries());
        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(filesSearchKey), 'zzz');
        await tester.pumpAndSettle();

        expect(find.text(Messages.filesNoMatches), findsOneWidget);
      });

      testWidgets('FILTER applies a type filter and shows a removable chip', (
        WidgetTester tester,
      ) async {
        await _open(tester, withEntries());
        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(filesFilterKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(filesFilterTypeKey(FileTypeGroup.images)));
        await tester.tap(find.byKey(filesFilterApplyKey));
        await tester.pumpAndSettle();

        // report.pdf is not an image; Photos is a folder, hidden by a type
        // filter.
        expect(find.text('REPORT.PDF'), findsNothing);
        expect(find.text('PHOTOS'), findsNothing);
        expect(find.byKey(filesFilterChipKey('type')), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byKey(filesFilterChipKey('type')),
            matching: find.text('X'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('REPORT.PDF'), findsOneWidget);
        expect(find.text('PHOTOS'), findsOneWidget);
      });

      testWidgets('the X on the filter pane changes nothing', (
        WidgetTester tester,
      ) async {
        await _open(tester, withEntries());
        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(filesFilterKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(filesFilterTextKey), 'whatever');
        await tester.tap(find.byKey(filesFilterCloseKey));
        await tester.pumpAndSettle();

        expect(find.text('REPORT.PDF'), findsOneWidget);
        expect(find.text('PHOTOS'), findsOneWidget);
      });

      testWidgets('an older-than MODIFIED filter chips with its amount/unit', (
        WidgetTester tester,
      ) async {
        await _open(tester, withEntries());
        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(filesFilterKey));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(filesFilterDirectionKey(FileAgeDirection.older)),
        );
        await tester.enterText(find.byKey(filesFilterOlderThanAmountKey), '3');
        await tester.tap(find.byKey(filesFilterApplyKey));
        await tester.pumpAndSettle();

        expect(
          find.text(Messages.filesFilterAgeChip(true, 3, 'DAYS')),
          findsOneWidget,
        );
      });

      testWidgets('CLEAR ALL removes every filter', (
        WidgetTester tester,
      ) async {
        await _open(tester, withEntries());
        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(filesSearchKey), 'report');
        await tester.pumpAndSettle();
        expect(find.text('PHOTOS'), findsNothing);

        await tester.tap(find.byKey(filesFilterKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(filesFilterClearKey));
        await tester.pumpAndSettle();

        expect(find.text('REPORT.PDF'), findsOneWidget);
        expect(find.text('PHOTOS'), findsOneWidget);
      });

      testWidgets('reopening the pane shows the filter already applied', (
        WidgetTester tester,
      ) async {
        await _open(tester, withEntries());
        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(filesSearchKey), 'report');
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(filesFilterKey));
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<TextField>(find.byKey(filesFilterTextKey))
              .controller!
              .text,
          'report',
        );
      });
    });

    group('bulk select', () {
      testWidgets('SELECT then SELECT ALL then DELETE removes every entry', (
        WidgetTester tester,
      ) async {
        final service = withEntries();
        await _open(tester, service);
        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(filesSelectKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(filesSelectAllKey));
        await tester.pumpAndSettle();

        expect(find.text('2 SELECTED'), findsOneWidget);

        await tester.tap(find.byKey(filesBulkDeleteKey));
        await tester.pumpAndSettle();
        service.resultsByPath['/storage/emulated/0'] = const FilesListed(
          <FileEntry>[],
        );
        await tester.tap(find.byKey(filesBulkYesKey));
        await tester.pumpAndSettle();

        expect(
          service.deletedPaths,
          containsAll(<String>[
            '/storage/emulated/0/Photos',
            '/storage/emulated/0/report.pdf',
          ]),
        );
        expect(find.text('REPORT.PDF'), findsNothing);
      });

      testWidgets('tapping one entry toggles it, not opens it', (
        WidgetTester tester,
      ) async {
        await _open(tester, withEntries());
        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(filesSelectKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0/Photos')));
        await tester.pumpAndSettle();

        // Still at the same level: the tap toggled selection, not navigation.
        expect(find.text('1 SELECTED'), findsOneWidget);
        expect(find.text('PHOTOS'), findsOneWidget);
      });

      testWidgets('CANCEL leaves everything as it was', (
        WidgetTester tester,
      ) async {
        final service = withEntries();
        await _open(tester, service);
        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(filesSelectKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(filesRowKey('/storage/emulated/0/Photos')));
        await tester.tap(find.byKey(filesCancelSelectKey));
        await tester.pumpAndSettle();

        expect(service.deletedPaths, isEmpty);
        expect(find.text('REPORT.PDF'), findsOneWidget);
      });
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
