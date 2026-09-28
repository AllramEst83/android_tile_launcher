import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/ui/mail_sheet.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

FakeMailService _service([MailResult? result]) =>
    FakeMailService(result ?? _inbox())
      ..saved = const MailAccountInfo(
        email: 'kay@gmail.com',
        host: 'imap.gmail.com',
      );

Future<void> _open(WidgetTester tester, FakeMailService mail) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () =>
              showMailSheet(context, mail: mail, clock: () => _now),
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

  group('trash', () {
    testWidgets('a message offers TRASH only once tapped', (
      WidgetTester tester,
    ) async {
      await _open(tester, _service());
      expect(find.byKey(mailTrashKey), findsNothing);

      await tester.tap(find.byKey(mailMessageKey(11)));
      await tester.pump();

      expect(find.byKey(mailTrashKey), findsOneWidget);
    });

    testWidgets('TRASH asks first, and nothing moves until YES', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service();
      await _open(tester, mail);
      await tester.tap(find.byKey(mailMessageKey(11)));
      await tester.pump();

      await tester.tap(find.byKey(mailTrashKey));
      await tester.pump();

      expect(find.text(Messages.mailTrashAsk), findsOneWidget);
      expect(mail.moves, isEmpty);
    });

    testWidgets('NO backs out and moves nothing', (WidgetTester tester) async {
      final FakeMailService mail = _service();
      await _open(tester, mail);
      await tester.tap(find.byKey(mailMessageKey(11)));
      await tester.pump();
      await tester.tap(find.byKey(mailTrashKey));
      await tester.pump();

      await tester.tap(find.byKey(mailTrashNoKey));
      await tester.pump();

      expect(find.text(Messages.mailTrashAsk), findsNothing);
      expect(find.byKey(mailTrashKey), findsOneWidget);
      expect(mail.moves, isEmpty);
    });

    testWidgets(
      'YES moves that message, with the inbox validity, and drops it',
      (WidgetTester tester) async {
        final FakeMailService mail = _service();
        await _open(tester, mail);
        await tester.tap(find.byKey(mailMessageKey(11)));
        await tester.pump();
        await tester.tap(find.byKey(mailTrashKey));
        await tester.pump();

        await tester.tap(find.byKey(mailTrashYesKey));
        await tester.pumpAndSettle();

        expect(mail.moves, <(int, int?)>[(11, 77)]);
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
      await tester.tap(find.byKey(mailMessageKey(11)));
      await tester.pump();
      await tester.tap(find.byKey(mailTrashKey));
      await tester.pump();

      await tester.tap(find.byKey(mailTrashYesKey));
      await tester.pumpAndSettle();

      expect(find.byKey(mailMessageKey(11)), findsNothing);
      expect(find.text(Messages.mailGone), findsOneWidget);
    });

    testWidgets('a failure keeps the message and says why', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = _service()
        ..moveResult = const MailMoveFailed(
          'no Trash folder on imap.gmail.com',
        );
      await _open(tester, mail);
      await tester.tap(find.byKey(mailMessageKey(11)));
      await tester.pump();
      await tester.tap(find.byKey(mailTrashKey));
      await tester.pump();

      await tester.tap(find.byKey(mailTrashYesKey));
      await tester.pumpAndSettle();

      expect(find.byKey(mailMessageKey(11)), findsOneWidget);
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
}
