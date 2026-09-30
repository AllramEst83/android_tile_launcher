import 'dart:async';
import 'dart:typed_data';

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/services/attachment_download_service.dart';
import 'package:android_tile_launcher/ui/compose_sheet.dart';
import 'package:android_tile_launcher/ui/mail_sheet.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../fakes/fake_attachment_download_service.dart';
import '../fakes/fake_mail_service.dart';

// Monday 28 September 2026, half past ten.
final DateTime _now = DateTime(2026, 9, 28, 10, 30);

MailMessage _mail(
  int uid,
  String from,
  String subject, {
  bool unread = false,
  DateTime? date,
}) => MailMessage(
  uid: uid,
  from: from,
  subject: subject,
  unread: unread,
  date: date,
);

MailMessages _inbox() => MailMessages(
  <MailMessage>[
    _mail(
      12,
      'Anna Andersson',
      'Lunch on Friday?',
      unread: true,
      date: DateTime(2026, 9, 28, 9, 5),
    ),
    _mail(11, 'Bo Berg', 'Invoice 42', date: DateTime(2026, 9, 25, 14)),
  ],
  total: 40,
  unread: 1,
  validity: 77,
);

MailOpened _opened(
  int uid,
  String from,
  String subject, {
  String fromAddress = '',
  List<MailParticipant> to = const <MailParticipant>[],
  List<MailParticipant> cc = const <MailParticipant>[],
  String text = 'Hello, this is the whole message.',
  String? html,
  String? htmlWithImages,
  bool truncated = false,
  int attachments = 0,
  List<MailAttachment>? attachmentList,
  bool markedRead = true,
  DateTime? date,
}) => MailOpened(
  MailBody(
    uid: uid,
    from: from,
    fromAddress: fromAddress,
    to: to,
    cc: cc,
    subject: subject,
    text: text,
    html: html,
    htmlWithImages: htmlWithImages,
    truncated: truncated,
    attachments:
        attachmentList ??
        List<MailAttachment>.generate(
          attachments,
          (int i) => MailAttachment(
            name: 'file-${i + 1}.bin',
            sizeBytes: 1024,
            mimeType: 'application/octet-stream',
            bytes: Uint8List(0),
          ),
        ),
    markedRead: markedRead,
    date: date,
  ),
);

FakeMailService _service([MailResult? result]) =>
    FakeMailService(result ?? _inbox())
      ..saved = const MailAccountInfo(
        email: 'kay@gmail.com',
        host: 'imap.gmail.com',
      )
      ..readResults.addAll(<int, MailReadResult>{
        12: _opened(
          12,
          'Anna Andersson',
          'Lunch on Friday?',
          fromAddress: 'anna@example.com',
          text: 'Hi Kay,\n\nShall we have lunch on Friday?\n\nAnna',
          date: DateTime(2026, 9, 28, 9, 5),
        ),
        11: _opened(11, 'Bo Berg', 'Invoice 42'),
      });

/// Opens message [uid] from the list into the reader pane.
Future<void> _read(WidgetTester tester, int uid) async {
  await tester.tap(find.byKey(mailMessageKey(uid)));
  await tester.pumpAndSettle();
}

Future<void> _open(
  WidgetTester tester,
  FakeMailService mail, {
  FakeAttachmentDownloadService? attachmentDownload,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showMailSheet(
            context,
            mail: mail,
            attachmentDownload:
                attachmentDownload ?? FakeAttachmentDownloadService(),
            clock: () => _now,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'shows the account and the newest messages, read from the server',
    (WidgetTester tester) async {
      final FakeMailService mail = _service();
      await _open(tester, mail);

      expect(find.text('KAY@GMAIL.COM'), findsOneWidget);
      expect(find.text('* ANNA ANDERSSON'), findsOneWidget);
      expect(find.text('BO BERG'), findsOneWidget);
      expect(find.text('LUNCH ON FRIDAY?'), findsOneWidget);
      // Today's is a time, an earlier one a date.
      expect(find.text('09:05'), findsOneWidget);
      expect(find.text('25 SEP'), findsOneWidget);
      expect(mail.counts, <int>[20]);
      expect(mail.freshCalls, 1);
    },
  );

  testWidgets('an empty inbox says so', (WidgetTester tester) async {
    await _open(
      tester,
      _service(const MailMessages(<MailMessage>[], total: 0, unread: 0)),
    );

    expect(find.text(Messages.mailInboxEmpty), findsOneWidget);
  });

  testWidgets('a failure says why', (WidgetTester tester) async {
    await _open(tester, _service(const MailUnavailable('no connection')));

    expect(find.text('NO CONNECTION'), findsOneWidget);
  });

  testWidgets('REFRESH reads again from the server', (
    WidgetTester tester,
  ) async {
    final FakeMailService mail = _service();
    await _open(tester, mail);

    await tester.tap(find.byKey(mailRefreshKey));
    await tester.pumpAndSettle();

    expect(mail.freshCalls, 2);
  });

  group('reading a message', () {
    testWidgets('tapping a message opens it in a pane, with its whole text', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      await _open(tester, mail);

      await _read(tester, 12);

      expect(find.byKey(mailReaderKey), findsOneWidget);
      expect(find.text('ANNA ANDERSSON'), findsOneWidget);
      expect(find.text('LUNCH ON FRIDAY?'), findsOneWidget);
      expect(
        tester.widget<SelectableText>(find.byKey(mailBodyKey)).data,
        'Hi Kay,\n\nShall we have lunch on Friday?\n\nAnna',
      );
      // The list gives way to the pane.
      expect(find.byKey(mailMessageKey(11)), findsNothing);
      expect(find.byKey(mailRefreshKey), findsNothing);
      expect(find.byKey(mailForgetKey), findsNothing);
      expect(mail.reads, <(int, int?)>[(12, 77)]);
    });

    testWidgets('shows when it was sent', (WidgetTester tester) async {
      await _open(tester, _service());

      await _read(tester, 12);

      expect(find.text('MON 28 SEP 09:05'), findsOneWidget);
    });

    testWidgets('says so while it is opening', (WidgetTester tester) async {
      final FakeMailService mail = _service()..readGate = Completer<void>();
      await _open(tester, mail);

      await tester.tap(find.byKey(mailMessageKey(12)));
      await tester.pump();

      expect(find.text(Messages.mailOpening), findsOneWidget);
      expect(find.byKey(mailBodyKey), findsNothing);

      mail.readGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text(Messages.mailOpening), findsNothing);
      expect(find.byKey(mailBodyKey), findsOneWidget);
    });

    testWidgets('opening it marks it read in the list behind', (
      WidgetTester tester,
    ) async {
      await _open(tester, _service());
      expect(find.text('* ANNA ANDERSSON'), findsOneWidget);

      await _read(tester, 12);
      await tester.tap(find.byKey(mailBackKey));
      await tester.pumpAndSettle();

      expect(find.text('* ANNA ANDERSSON'), findsNothing);
      expect(find.text('ANNA ANDERSSON'), findsOneWidget);
    });

    testWidgets('BACK returns to the list', (WidgetTester tester) async {
      await _open(tester, _service());
      await _read(tester, 12);

      await tester.tap(find.byKey(mailBackKey));
      await tester.pumpAndSettle();

      expect(find.byKey(mailReaderKey), findsNothing);
      expect(find.byKey(mailMessageKey(11)), findsOneWidget);
      expect(find.byKey(mailMessageKey(12)), findsOneWidget);
    });

    testWidgets('an empty message says there is nothing to show', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      mail.readResults[11] = _opened(11, 'Bo Berg', 'Invoice 42', text: '');
      await _open(tester, mail);

      await _read(tester, 11);

      expect(find.text(Messages.mailNoText), findsOneWidget);
    });

    testWidgets('says when the text was cut, and how many attachments', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      mail.readResults[11] = _opened(
        11,
        'Bo Berg',
        'Invoice 42',
        truncated: true,
        attachments: 2,
      );
      await _open(tester, mail);

      await _read(tester, 11);

      expect(find.text(Messages.mailCutOff), findsOneWidget);
      expect(find.text(Messages.mailAttachments(2)), findsOneWidget);
    });

    testWidgets('one attachment is singular', (WidgetTester tester) async {
      final FakeMailService mail = _service();
      mail.readResults[11] = _opened(11, 'Bo', 'x', attachments: 1);
      await _open(tester, mail);

      await _read(tester, 11);

      expect(find.text('1 ATTACHMENT'), findsOneWidget);
    });

    testWidgets('a long message scrolls', (WidgetTester tester) async {
      final FakeMailService mail = _service();
      mail.readResults[11] = _opened(
        11,
        'Bo Berg',
        'Invoice 42',
        text: List<String>.generate(80, (int i) => 'Line number $i').join('\n'),
      );
      await _open(tester, mail);
      await _read(tester, 11);

      final ScrollableState scrollable = tester.state<ScrollableState>(
        // The pane's own scrolling: the selectable text has one inside too.
        find
            .descendant(
              of: find.byKey(mailReaderKey),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scrollable.position.maxScrollExtent, greaterThan(0));
      expect(scrollable.position.pixels, 0);

      await tester.drag(find.byKey(mailReaderKey), const Offset(0, -400));
      await tester.pump();

      expect(scrollable.position.pixels, greaterThan(0));
    });

    testWidgets('a message that is gone is dropped from the list', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      mail.readResults[11] = const MailReadGone();
      await _open(tester, mail);

      await _read(tester, 11);

      expect(find.byKey(mailReaderKey), findsNothing);
      expect(find.byKey(mailMessageKey(11)), findsNothing);
      expect(find.byKey(mailMessageKey(12)), findsOneWidget);
      expect(find.text(Messages.mailGone), findsOneWidget);
    });

    testWidgets('a failure to open says why, and BACK still works', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      mail.readResults[11] = const MailReadFailed(
        'this message is 30.0 MB, too big to show here',
      );
      await _open(tester, mail);

      await _read(tester, 11);

      expect(
        find.text('THIS MESSAGE IS 30.0 MB, TOO BIG TO SHOW HERE'),
        findsOneWidget,
      );
      expect(find.byKey(mailMarkKey), findsNothing);
      expect(find.byKey(mailTrashKey), findsNothing);

      await tester.tap(find.byKey(mailBackKey));
      await tester.pumpAndSettle();
      // Still unread: nothing was changed.
      expect(find.byKey(mailMessageKey(11)), findsOneWidget);
    });

    testWidgets('an account that is not set up says to set it up', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      mail.readResults[11] = const MailReadNotSetUp();
      await _open(tester, mail);

      await _read(tester, 11);

      expect(find.text(Messages.mailTapToSetUp), findsOneWidget);
    });

    testWidgets('if only the marking failed, it is shown and says so', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      mail.readResults[12] = _opened(
        12,
        'Anna Andersson',
        'Lunch on Friday?',
        markedRead: false,
      );
      await _open(tester, mail);

      await _read(tester, 12);

      expect(find.byKey(mailBodyKey), findsOneWidget);
      expect(find.text(Messages.mailNotMarked), findsOneWidget);
      // And the list still shows it unread.
      await tester.tap(find.byKey(mailBackKey));
      await tester.pumpAndSettle();
      expect(find.text('* ANNA ANDERSSON'), findsOneWidget);
    });
  });

  group('mark as read or unread', () {
    testWidgets('an opened message offers MARK AS UNREAD, beside TRASH', (
      WidgetTester tester,
    ) async {
      await _open(tester, _service());

      await _read(tester, 12);

      expect(find.text(Messages.mailMarkUnread), findsOneWidget);
      expect(find.text(Messages.mailMarkRead), findsNothing);
      expect(find.byKey(mailTrashKey), findsOneWidget);
    });

    testWidgets('with room between the two buttons, on one row', (
      WidgetTester tester,
    ) async {
      await _open(tester, _service());
      await _read(tester, 12);

      final Rect mark = tester.getRect(find.byKey(mailMarkKey));
      final Rect trash = tester.getRect(find.byKey(mailTrashKey));

      expect(mark.top, closeTo(trash.top, 1));
      expect(trash.left - mark.right, greaterThanOrEqualTo(TileMetrics.margin));
      expect(mark.left, lessThan(trash.left));
    });

    testWidgets('MARK AS UNREAD marks it unread and the button flips', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      await _open(tester, mail);
      await _read(tester, 12);

      await tester.tap(find.byKey(mailMarkKey));
      await tester.pumpAndSettle();

      expect(mail.marks, <(int, bool, int?)>[(12, false, 77)]);
      expect(find.text(Messages.mailMarkedUnread), findsOneWidget);
      expect(find.text(Messages.mailMarkRead), findsOneWidget);
      expect(find.text(Messages.mailMarkUnread), findsNothing);
    });

    testWidgets('and MARK AS READ marks it read again: it toggles', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      await _open(tester, mail);
      await _read(tester, 12);
      await tester.tap(find.byKey(mailMarkKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(mailMarkKey));
      await tester.pumpAndSettle();

      expect(mail.marks, <(int, bool, int?)>[(12, false, 77), (12, true, 77)]);
      expect(find.text(Messages.mailMarkedRead), findsOneWidget);
      expect(find.text(Messages.mailMarkUnread), findsOneWidget);
    });

    testWidgets('the list behind follows what was marked', (
      WidgetTester tester,
    ) async {
      await _open(tester, _service());
      await _read(tester, 12);
      await tester.tap(find.byKey(mailMarkKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(mailBackKey));
      await tester.pumpAndSettle();

      expect(find.text('* ANNA ANDERSSON'), findsOneWidget);
    });

    testWidgets('a failure changes nothing and says why', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service()
        ..markResult = const MailMarkFailed('imap.gmail.com did not answer');
      await _open(tester, mail);
      await _read(tester, 12);

      await tester.tap(find.byKey(mailMarkKey));
      await tester.pumpAndSettle();

      expect(
        find.text('FAILED: IMAP.GMAIL.COM DID NOT ANSWER'),
        findsOneWidget,
      );
      // Still the same wish: it is read, so it offers MARK AS UNREAD.
      expect(find.text(Messages.mailMarkUnread), findsOneWidget);
    });

    testWidgets('a message that has gone is dropped', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service()
        ..markResult = const MailMarkGone();
      await _open(tester, mail);
      await _read(tester, 12);

      await tester.tap(find.byKey(mailMarkKey));
      await tester.pumpAndSettle();

      expect(find.byKey(mailReaderKey), findsNothing);
      expect(find.byKey(mailMessageKey(12)), findsNothing);
      expect(find.text(Messages.mailGone), findsOneWidget);
    });

    testWidgets('a message that was unread and fails to mark on opening '
        'offers MARK AS READ', (WidgetTester tester) async {
      final FakeMailService mail = _service();
      mail.readResults[12] = _opened(
        12,
        'Anna Andersson',
        'Lunch on Friday?',
        markedRead: false,
      );
      await _open(tester, mail);

      await _read(tester, 12);

      expect(find.text(Messages.mailMarkRead), findsOneWidget);
    });
  });

  group('trash', () {
    testWidgets('a message offers TRASH only once it is opened', (
      WidgetTester tester,
    ) async {
      await _open(tester, _service());
      expect(find.byKey(mailTrashKey), findsNothing);

      await _read(tester, 11);

      expect(find.byKey(mailTrashKey), findsOneWidget);
    });

    testWidgets('TRASH asks first, and nothing moves until YES', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      await _open(tester, mail);
      await _read(tester, 11);

      await tester.tap(find.byKey(mailTrashKey));
      await tester.pump();

      expect(find.text(Messages.mailTrashAsk), findsOneWidget);
      expect(mail.moves, isEmpty);
    });

    testWidgets('NO backs out and moves nothing', (WidgetTester tester) async {
      final FakeMailService mail = _service();
      await _open(tester, mail);
      await _read(tester, 11);
      await tester.tap(find.byKey(mailTrashKey));
      await tester.pump();

      await tester.tap(find.byKey(mailTrashNoKey));
      await tester.pump();

      expect(find.text(Messages.mailTrashAsk), findsNothing);
      expect(find.byKey(mailTrashKey), findsOneWidget);
      expect(find.byKey(mailMarkKey), findsOneWidget);
      expect(mail.moves, isEmpty);
    });

    testWidgets(
      'YES moves that message, with the inbox validity, and returns to the list',
      (WidgetTester tester) async {
        final FakeMailService mail = _service();
        await _open(tester, mail);
        await _read(tester, 11);
        await tester.tap(find.byKey(mailTrashKey));
        await tester.pump();

        await tester.tap(find.byKey(mailTrashYesKey));
        await tester.pumpAndSettle();

        expect(mail.moves, <(int, int?)>[(11, 77)]);
        expect(find.byKey(mailReaderKey), findsNothing);
        expect(find.byKey(mailMessageKey(11)), findsNothing);
        expect(find.byKey(mailMessageKey(12)), findsOneWidget);
        expect(find.text(Messages.mailMoved), findsOneWidget);
      },
    );

    testWidgets('a message already gone is dropped and said so', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service()..moveResult = const MailGone();
      await _open(tester, mail);
      await _read(tester, 11);
      await tester.tap(find.byKey(mailTrashKey));
      await tester.pump();

      await tester.tap(find.byKey(mailTrashYesKey));
      await tester.pumpAndSettle();

      expect(find.byKey(mailMessageKey(11)), findsNothing);
      expect(find.text(Messages.mailGone), findsOneWidget);
    });

    testWidgets('a failure keeps the message open and says why', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service()
        ..moveResult = const MailMoveFailed(
          'no Trash folder on imap.gmail.com',
        );
      await _open(tester, mail);
      await _read(tester, 11);
      await tester.tap(find.byKey(mailTrashKey));
      await tester.pump();

      await tester.tap(find.byKey(mailTrashYesKey));
      await tester.pumpAndSettle();

      expect(find.byKey(mailReaderKey), findsOneWidget);
      expect(
        find.text('FAILED: NO TRASH FOLDER ON IMAP.GMAIL.COM'),
        findsOneWidget,
      );
    });
  });

  group('forget', () {
    testWidgets('FORGET asks first, and nothing is forgotten until YES', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      await _open(tester, mail);

      await tester.tap(find.byKey(mailForgetKey));
      await tester.pump();

      expect(find.text(Messages.mailForgetAsk), findsOneWidget);
      expect(mail.forgets, 0);
    });

    testWidgets('NO backs out', (WidgetTester tester) async {
      final FakeMailService mail = _service();
      await _open(tester, mail);
      await tester.tap(find.byKey(mailForgetKey));
      await tester.pump();

      await tester.tap(find.byKey(mailForgetNoKey));
      await tester.pump();

      expect(find.byKey(mailForgetKey), findsOneWidget);
      expect(mail.forgets, 0);
    });

    testWidgets('YES forgets the account and closes the sheet', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      await _open(tester, mail);
      await tester.tap(find.byKey(mailForgetKey));
      await tester.pump();

      await tester.tap(find.byKey(mailForgetYesKey));
      await tester.pumpAndSettle();

      expect(mail.forgets, 1);
      expect(mail.saved, isNull);
      expect(find.byKey(mailForgetKey), findsNothing);
    });
  });

  group('bulk delete', () {
    testWidgets('SELECT shows a checkbox on every message, none checked yet', (
      WidgetTester tester,
    ) async {
      await _open(tester, _service());

      await tester.tap(find.byKey(mailSelectKey));
      await tester.pump();

      expect(find.byKey(mailCheckboxKey(12)), findsOneWidget);
      expect(find.byKey(mailCheckboxKey(11)), findsOneWidget);
      expect(find.text(Messages.mailSelectedCount(0)), findsOneWidget);
      // Tapping a message now selects it rather than opening it.
      await tester.tap(find.byKey(mailMessageKey(12)));
      await tester.pump();
      expect(find.byKey(mailReaderKey), findsNothing);
      expect(find.text(Messages.mailSelectedCount(1)), findsOneWidget);
    });

    testWidgets('DELETE is disabled until something is selected', (
      WidgetTester tester,
    ) async {
      await _open(tester, _service());
      await tester.tap(find.byKey(mailSelectKey));
      await tester.pump();

      await tester.tap(find.byKey(mailBulkDeleteKey));
      await tester.pump();

      expect(find.text(Messages.mailBulkTrashAsk(0)), findsNothing);
    });

    testWidgets('CANCEL leaves the list untouched', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      await _open(tester, mail);
      await tester.tap(find.byKey(mailSelectKey));
      await tester.pump();
      await tester.tap(find.byKey(mailMessageKey(12)));
      await tester.pump();

      await tester.tap(find.byKey(mailCancelSelectKey));
      await tester.pump();

      expect(find.byKey(mailSelectKey), findsOneWidget);
      expect(find.byKey(mailCheckboxKey(12)), findsNothing);
      expect(mail.moves, isEmpty);
    });

    testWidgets('DELETE asks first, and nothing moves until YES', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      await _open(tester, mail);
      await tester.tap(find.byKey(mailSelectKey));
      await tester.pump();
      await tester.tap(find.byKey(mailMessageKey(12)));
      await tester.tap(find.byKey(mailMessageKey(11)));
      await tester.pump();

      await tester.tap(find.byKey(mailBulkDeleteKey));
      await tester.pump();

      expect(find.text(Messages.mailBulkTrashAsk(2)), findsOneWidget);
      expect(mail.moves, isEmpty);
    });

    testWidgets(
      'YES moves every selected message and refreshes the list from the server',
      (WidgetTester tester) async {
        final FakeMailService mail = _service();
        await _open(tester, mail);
        await tester.tap(find.byKey(mailSelectKey));
        await tester.pump();
        await tester.tap(find.byKey(mailMessageKey(12)));
        await tester.tap(find.byKey(mailMessageKey(11)));
        await tester.pump();
        await tester.tap(find.byKey(mailBulkDeleteKey));
        await tester.pump();

        await tester.tap(find.byKey(mailBulkYesKey));
        await tester.pumpAndSettle();

        expect(mail.moves, <(int, int?)>[(12, 77), (11, 77)]);
        expect(find.text(Messages.mailBulkMoved(2)), findsOneWidget);
        // "automatically refresh the email list" once it is done.
        expect(mail.freshCalls, 2);
        expect(find.byKey(mailSelectKey), findsOneWidget);
        expect(find.byKey(mailCheckboxKey(12)), findsNothing);
      },
    );

    testWidgets('NO backs out of the bulk ask and moves nothing', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      await _open(tester, mail);
      await tester.tap(find.byKey(mailSelectKey));
      await tester.pump();
      await tester.tap(find.byKey(mailMessageKey(12)));
      await tester.pump();
      await tester.tap(find.byKey(mailBulkDeleteKey));
      await tester.pump();

      await tester.tap(find.byKey(mailBulkNoKey));
      await tester.pump();

      expect(mail.moves, isEmpty);
      expect(find.text(Messages.mailSelectedCount(1)), findsOneWidget);
    });

    testWidgets('a narrow phone still fits the select and bulk-ask rows', (
      WidgetTester tester,
    ) async {
      tester.view
        ..physicalSize = const Size(360 * 3, 780 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await _open(tester, _service());

      await tester.tap(find.byKey(mailSelectKey));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(mailMessageKey(12)));
      await tester.pump();
      await tester.tap(find.byKey(mailBulkDeleteKey));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
  group('type size', () {
    testWidgets(
      'the text of a message is easy to read, well over the tiny 9 px',
      (WidgetTester tester) async {
        await _open(tester, _service());
        await _read(tester, 12);

        final SelectableText body = tester.widget<SelectableText>(
          find.byKey(mailBodyKey),
        );
        expect(body.style!.fontSize, greaterThanOrEqualTo(12));
      },
    );

    testWidgets('the buttons and the list are larger too', (
      WidgetTester tester,
    ) async {
      await _open(tester, _service());

      final Text sender = tester.widget<Text>(find.text('* ANNA ANDERSSON'));
      final Text subject = tester.widget<Text>(find.text('LUNCH ON FRIDAY?'));
      expect(sender.style!.fontSize, greaterThanOrEqualTo(13));
      expect(subject.style!.fontSize, greaterThanOrEqualTo(11));

      await _read(tester, 12);
      final Text mark = tester.widget<Text>(find.text(Messages.mailMarkUnread));
      expect(mark.style!.fontSize, greaterThanOrEqualTo(11));
    });

    testWidgets('it all still fits a narrow phone', (
      WidgetTester tester,
    ) async {
      tester.view
        ..physicalSize = const Size(360 * 3, 780 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final FakeMailService mail = _service();
      await _open(tester, mail);
      await _read(tester, 12);

      // Both action rows, at their longest.
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(mailTrashKey));
      await tester.pump();
      expect(find.text(Messages.mailTrashAsk), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(mailTrashNoKey));
      await tester.pump();

      // Four buttons now (MARK, REPLY, FORWARD, TRASH): they may wrap onto a
      // second line at this width rather than overflow, so only bounds are
      // checked, not that they all share one row.
      for (final Key key in <Key>[
        mailMarkKey,
        mailReplyKey,
        mailForwardKey,
        mailTrashKey,
      ]) {
        final Rect rect = tester.getRect(find.byKey(key));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(360));
      }
    });

    testWidgets('the list header with COMPOSE also fits a narrow phone', (
      WidgetTester tester,
    ) async {
      tester.view
        ..physicalSize = const Size(360 * 3, 780 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await _open(tester, _service());

      expect(tester.takeException(), isNull);
      expect(find.byKey(mailComposeKey), findsOneWidget);
    });
  });

  group('compose', () {
    testWidgets('COMPOSE opens a blank message', (WidgetTester tester) async {
      await _open(tester, _service());

      await tester.tap(find.byKey(mailComposeKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.mailComposeTitle), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(composeToKey)).controller?.text,
        '',
      );
    });

    testWidgets('sending closes the sheet and reaches the service', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      await _open(tester, mail);
      await tester.tap(find.byKey(mailComposeKey));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(composeToKey), 'anna@example.com');
      await tester.enterText(find.byKey(composeSubjectKey), 'Hello');
      await tester.enterText(find.byKey(composeBodyKey), 'Hi there');
      await tester.tap(find.byKey(composeSendKey));
      await tester.pumpAndSettle();

      expect(mail.sent, hasLength(1));
      final (to, cc, subject, text) = mail.sent.single;
      expect(to, <String>['anna@example.com']);
      expect(cc, isEmpty);
      expect(subject, 'Hello');
      expect(text, 'Hi there');
      expect(find.text(Messages.mailComposeTitle), findsNothing);
    });

    testWidgets('tapping the sender opens a blank message addressed to them', (
      WidgetTester tester,
    ) async {
      await _open(tester, _service());
      await _read(tester, 12);

      await tester.tap(find.byKey(mailFromComposeKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.mailComposeTitle), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(composeToKey)).controller?.text,
        'anna@example.com',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(composeSubjectKey))
            .controller
            ?.text,
        '',
      );
    });

    testWidgets('no address on the message: FROM is not tappable', (
      WidgetTester tester,
    ) async {
      await _open(tester, _service());
      await _read(tester, 11);

      expect(find.byKey(mailFromComposeKey), findsNothing);
    });

    testWidgets('REPLY opens addressed, subjected and quoted', (
      WidgetTester tester,
    ) async {
      await _open(tester, _service());
      await _read(tester, 12);

      await tester.tap(find.byKey(mailReplyKey));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byKey(composeToKey)).controller?.text,
        'anna@example.com',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(composeSubjectKey))
            .controller
            ?.text,
        'Re: Lunch on Friday?',
      );
      final TextEditingController? body = tester
          .widget<TextField>(find.byKey(composeBodyKey))
          .controller;
      expect(
        body?.text,
        contains('On MON 28 SEP 09:05, Anna Andersson wrote:'),
      );
      expect(
        body?.text,
        contains('> Hi Kay,\n> \n> Shall we have lunch on Friday?\n> \n> Anna'),
      );
      // The cursor starts above the quote, so typing lands the reply there.
      expect(body?.selection.baseOffset, 0);
    });

    testWidgets('FORWARD opens blank-addressed, subjected and quoted', (
      WidgetTester tester,
    ) async {
      await _open(tester, _service());
      await _read(tester, 12);

      await tester.tap(find.byKey(mailForwardKey));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byKey(composeToKey)).controller?.text,
        '',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(composeSubjectKey))
            .controller
            ?.text,
        'Fwd: Lunch on Friday?',
      );
      expect(
        tester.widget<TextField>(find.byKey(composeBodyKey)).controller?.text,
        contains('On MON 28 SEP 09:05, Anna Andersson wrote:'),
      );
    });
  });

  group('to/cc and reply all', () {
    testWidgets('shows To and Cc as tappable chips', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      mail.readResults[12] = _opened(
        12,
        'Anna Andersson',
        'Lunch on Friday?',
        fromAddress: 'anna@example.com',
        to: const <MailParticipant>[
          MailParticipant(address: 'kay@gmail.com', name: 'Kay'),
        ],
        cc: const <MailParticipant>[
          MailParticipant(address: 'bo@example.com', name: 'Bo Berg'),
        ],
      );
      await _open(tester, mail);
      await _read(tester, 12);

      expect(find.text('KAY'), findsOneWidget);
      expect(find.text('BO BERG'), findsOneWidget);

      await tester.tap(find.text('BO BERG'));
      await tester.pumpAndSettle();

      expect(find.text(Messages.mailComposeTitle), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(composeToKey)).controller?.text,
        'bo@example.com',
      );
    });

    testWidgets('REPLY ALL is hidden with only one recipient', (
      WidgetTester tester,
    ) async {
      await _open(tester, _service());
      await _read(tester, 12);

      expect(find.byKey(mailReplyAllKey), findsNothing);
    });

    testWidgets('REPLY ALL addresses the sender and copies the rest', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      mail.readResults[12] = _opened(
        12,
        'Anna Andersson',
        'Lunch on Friday?',
        fromAddress: 'anna@example.com',
        to: const <MailParticipant>[
          MailParticipant(address: 'kay@gmail.com', name: 'Kay'),
          MailParticipant(address: 'cesar@example.com', name: 'Cesar'),
        ],
        cc: const <MailParticipant>[
          MailParticipant(address: 'bo@example.com', name: 'Bo Berg'),
        ],
      );
      await _open(tester, mail);
      await _read(tester, 12);

      expect(find.byKey(mailReplyAllKey), findsOneWidget);
      await tester.tap(find.byKey(mailReplyAllKey));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byKey(composeToKey)).controller?.text,
        'anna@example.com',
      );
      expect(
        tester.widget<TextField>(find.byKey(composeCcKey)).controller?.text,
        'cesar@example.com, bo@example.com',
      );
    });
  });

  group('rich body', () {
    testWidgets('a message with markup renders it rich, not as raw tags', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      mail.readResults[12] = _opened(
        12,
        'Anna Andersson',
        'Lunch on Friday?',
        fromAddress: 'anna@example.com',
        text: 'Sure, see you then',
        html: '<p>Sure, <b>see you then</b></p>',
      );
      await _open(tester, mail);

      await _read(tester, 12);

      expect(find.text('Sure, see you then', findRichText: true), findsWidgets);
      expect(find.byType(SelectableText), findsNothing);
    });

    testWidgets('plain text still renders as selectable text', (
      WidgetTester tester,
    ) async {
      await _open(tester, _service());

      await _read(tester, 12);

      expect(find.byKey(mailBodyKey), findsOneWidget);
      expect(tester.widget(find.byKey(mailBodyKey)), isA<SelectableText>());
    });
  });

  group('attachments and images', () {
    testWidgets('lists each attachment with its size, and downloads it', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      final Uint8List bytes = Uint8List.fromList(List<int>.filled(2048, 1));
      mail.readResults[12] = _opened(
        12,
        'Anna Andersson',
        'Lunch on Friday?',
        attachmentList: <MailAttachment>[
          MailAttachment(
            name: 'menu.pdf',
            sizeBytes: bytes.length,
            mimeType: 'application/pdf',
            bytes: bytes,
          ),
        ],
      );
      final FakeAttachmentDownloadService downloads =
          FakeAttachmentDownloadService();
      await _open(tester, mail, attachmentDownload: downloads);
      await _read(tester, 12);

      expect(find.text('1 ATTACHMENT'), findsOneWidget);
      expect(find.text('MENU.PDF'), findsOneWidget);
      expect(find.text('2.0 KB'), findsOneWidget);

      await tester.tap(find.byKey(mailDownloadKey('menu.pdf')));
      await tester.pumpAndSettle();

      expect(downloads.saves, <(int, String, String)>[
        (2048, 'menu.pdf', 'application/pdf'),
      ]);
      expect(find.text(Messages.mailDownloaded), findsOneWidget);
    });

    testWidgets('a failed download says so', (WidgetTester tester) async {
      final FakeMailService mail = _service();
      mail.readResults[12] = _opened(
        12,
        'Anna Andersson',
        'Lunch on Friday?',
        attachmentList: <MailAttachment>[
          MailAttachment(
            name: 'menu.pdf',
            sizeBytes: 10,
            mimeType: 'application/pdf',
            bytes: Uint8List(10),
          ),
        ],
      );
      await _open(
        tester,
        mail,
        attachmentDownload: FakeAttachmentDownloadService(
          AttachmentSaveResult.failed,
        ),
      );
      await _read(tester, 12);

      await tester.tap(find.byKey(mailDownloadKey('menu.pdf')));
      await tester.pumpAndSettle();

      expect(
        find.text('${Messages.failedPrefix}${Messages.mailDownloadFailed}'),
        findsOneWidget,
      );
    });

    testWidgets('SHOW IMAGES reveals pictures, hidden until then', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      mail.readResults[12] = _opened(
        12,
        'Anna Andersson',
        'Lunch on Friday?',
        html: '<p>See the menu</p>',
        htmlWithImages:
            '<p>See the menu</p><img src="data:image/png;base64,x">',
      );
      await _open(tester, mail);
      await _read(tester, 12);

      expect(find.byKey(mailShowImagesKey), findsOneWidget);
      final HtmlWidget before = tester.widget(find.byKey(mailBodyKey));
      expect(before.html, '<p>See the menu</p>');

      await tester.tap(find.byKey(mailShowImagesKey));
      await tester.pumpAndSettle();

      expect(find.byKey(mailShowImagesKey), findsNothing);
      final HtmlWidget after = tester.widget(find.byKey(mailBodyKey));
      expect(
        after.html,
        '<p>See the menu</p><img src="data:image/png;base64,x">',
      );
    });

    testWidgets('no pictures to reveal: no SHOW IMAGES button', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      mail.readResults[12] = _opened(
        12,
        'Anna Andersson',
        'Lunch on Friday?',
        html: '<p>No pictures here</p>',
      );
      await _open(tester, mail);

      await _read(tester, 12);

      expect(find.byKey(mailShowImagesKey), findsNothing);
    });
  });

  group('prev/next', () {
    testWidgets('steps to the next and previous message in the list', (
      WidgetTester tester,
    ) async {
      await _open(tester, _service());
      await _read(tester, 12);

      await tester.tap(find.byKey(mailNextKey));
      await tester.pumpAndSettle();

      expect(find.text('BO BERG'), findsOneWidget);

      await tester.tap(find.byKey(mailPrevKey));
      await tester.pumpAndSettle();

      expect(find.text('ANNA ANDERSSON'), findsOneWidget);
    });

    testWidgets('PREV does nothing on the first message, NEXT on the last', (
      WidgetTester tester,
    ) async {
      await _open(tester, _service());
      await _read(tester, 12);

      await tester.tap(find.byKey(mailPrevKey));
      await tester.pumpAndSettle();
      expect(find.text('ANNA ANDERSSON'), findsOneWidget);

      await tester.tap(find.byKey(mailNextKey));
      await tester.pumpAndSettle();
      expect(find.text('BO BERG'), findsOneWidget);

      await tester.tap(find.byKey(mailNextKey));
      await tester.pumpAndSettle();
      expect(find.text('BO BERG'), findsOneWidget);
    });

    testWidgets('NEXT sits flush right, PREV flush left, like the row above', (
      WidgetTester tester,
    ) async {
      await _open(tester, _service());
      await _read(tester, 12);

      final double prevLeft = tester.getRect(find.byKey(mailPrevKey)).left;
      final double backLeft = tester.getRect(find.byKey(mailBackKey)).left;
      final double nextRight = tester.getRect(find.byKey(mailNextKey)).right;
      expect(prevLeft, backLeft);

      await tester.tap(find.byKey(mailBackKey));
      await tester.pumpAndSettle();
      final double refreshRight = tester
          .getRect(find.byKey(mailRefreshKey))
          .right;
      expect(nextRight, closeTo(refreshRight, 0.5));
    });
  });

  group('bulk read/unread', () {
    testWidgets('READ marks every selected message read', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      await _open(tester, mail);
      await tester.tap(find.byKey(mailSelectKey));
      await tester.pump();
      await tester.tap(find.byKey(mailMessageKey(12)));
      await tester.pump();

      await tester.tap(find.byKey(mailBulkReadKey));
      await tester.pumpAndSettle();

      expect(mail.marks, <(int, bool, int?)>[(12, true, 77)]);
      expect(find.text(Messages.mailBulkMarkedRead(1)), findsOneWidget);
      // Selection mode ends and the list still shows read, not unread, now.
      expect(find.byKey(mailSelectKey), findsOneWidget);
      expect(find.text('* ANNA ANDERSSON'), findsNothing);
    });

    testWidgets('UNREAD marks every selected message unread', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      await _open(tester, mail);
      await tester.tap(find.byKey(mailSelectKey));
      await tester.pump();
      await tester.tap(find.byKey(mailMessageKey(11)));
      await tester.pump();

      await tester.tap(find.byKey(mailBulkUnreadKey));
      await tester.pumpAndSettle();

      expect(mail.marks, <(int, bool, int?)>[(11, false, 77)]);
      expect(find.text(Messages.mailBulkMarkedUnread(1)), findsOneWidget);
      expect(find.text('* BO BERG'), findsOneWidget);
    });

    testWidgets('disabled until something is selected', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      await _open(tester, mail);
      await tester.tap(find.byKey(mailSelectKey));
      await tester.pump();

      await tester.tap(find.byKey(mailBulkReadKey));
      await tester.tap(find.byKey(mailBulkUnreadKey));
      await tester.pump();

      expect(mail.marks, isEmpty);
    });
  });
}
