import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/ui/mail_tile_view.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MailMessage _mail(
  int uid,
  String from,
  String subject, {
  bool unread = false,
}) => MailMessage(uid: uid, from: from, subject: subject, unread: unread);

final MailMessages _inbox = MailMessages(
  <MailMessage>[
    _mail(5, 'Anna Andersson', 'Lunch on Friday?', unread: true),
    _mail(4, 'Bo Berg', 'Invoice 42', unread: true),
    _mail(3, 'Cecilia', 'Re: plans'),
  ],
  total: 120,
  unread: 7,
);

Future<void> _pump(
  WidgetTester tester,
  MailResult result, {
  Size size = const Size(185, 185),
  VoidCallback? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: MailTileContentView(
            result: result,
            ink: Colors.white,
            onTap: onTap,
          ),
        ),
      ),
    ),
  ),
);

void main() {
  group('with an inbox', () {
    testWidgets('small: the unread count as a big number', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _inbox, size: const Size(90, 90));

      expect(find.text('7'), findsOneWidget);
      expect(find.text(Messages.mailUnread), findsOneWidget);
      expect(find.text('ANNA ANDERSSON'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('medium: the count and the newest message', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _inbox);

      expect(find.text('7'), findsOneWidget);
      expect(find.text('ANNA ANDERSSON'), findsOneWidget);
      expect(find.text('LUNCH ON FRIDAY?'), findsOneWidget);
      // Only the newest.
      expect(find.text('BO BERG'), findsNothing);
    });

    testWidgets('wide: a line for each of the newest, unread ones marked', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _inbox, size: const Size(380, 185));

      expect(find.text('7'), findsOneWidget);
      expect(find.byKey(mailRowKey(0)), findsOneWidget);
      expect(find.byKey(mailRowKey(2)), findsOneWidget);
      expect(find.text('ANNA ANDERSSON'), findsOneWidget);
      expect(find.text('RE: PLANS'), findsOneWidget);
      // Two unread, so two markers.
      expect(find.text('*'), findsNWidgets(2));
    });

    testWidgets('wide: who it is from over what it is about', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _inbox, size: const Size(380, 185));

      final Offset from = tester.getTopLeft(find.text('ANNA ANDERSSON'));
      final Offset about = tester.getTopLeft(find.text('LUNCH ON FRIDAY?'));
      // Two lines, one under the other, not one line holding both.
      expect(about.dy, greaterThan(from.dy));
      expect(about.dx, from.dx);
    });

    testWidgets('wide: the messages are big enough to read', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _inbox, size: const Size(380, 185));

      final Text from = tester.widget<Text>(find.text('ANNA ANDERSSON'));
      final Text about = tester.widget<Text>(find.text('LUNCH ON FRIDAY?'));
      expect(from.style?.fontSize, greaterThanOrEqualTo(11));
      expect(about.style?.fontSize, greaterThanOrEqualTo(10));
    });

    testWidgets('wide: only as many lines as the height holds', (
      WidgetTester tester,
    ) async {
      final MailMessages many = MailMessages(
        <MailMessage>[
          for (int i = 0; i < 20; i++)
            _mail(100 - i, 'Sender $i', 'Subject $i'),
        ],
        total: 20,
        unread: 0,
      );

      await _pump(tester, many, size: const Size(380, 100));

      expect(find.byKey(mailRowKey(0)), findsOneWidget);
      expect(find.byKey(mailRowKey(19)), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an empty inbox says so', (WidgetTester tester) async {
      await _pump(
        tester,
        const MailMessages(<MailMessage>[], total: 0, unread: 0),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.text(Messages.mailInboxEmpty), findsOneWidget);
    });

    testWidgets('a message with no subject still shows something', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        MailMessages(<MailMessage>[_mail(1, 'Anna', '')], total: 1, unread: 1),
      );

      expect(find.text(Messages.mailNoSubject), findsOneWidget);
    });
  });

  group('without an inbox', () {
    testWidgets('no account: offers to set one up', (
      WidgetTester tester,
    ) async {
      await _pump(tester, const MailNotSetUp());

      expect(find.text(Messages.mailTapToSetUp), findsOneWidget);
    });

    testWidgets('unreadable: says why and offers a retry', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const MailUnavailable('imap.gmail.com did not answer'),
      );

      expect(find.text('IMAP.GMAIL.COM DID NOT ANSWER'), findsOneWidget);
      expect(find.text(Messages.mailTapToRetry), findsOneWidget);
    });
  });

  group('taps', () {
    testWidgets('anywhere on the tile calls onTap', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await _pump(tester, const MailNotSetUp(), onTap: () => taps++);

      final Rect tile = tester.getRect(find.byType(MailTileContentView));
      await tester.tapAt(tile.centerRight - const Offset(5, 0));
      await tester.tapAt(tile.bottomLeft + const Offset(5, -5));

      expect(taps, 2);
    });

    testWidgets('without onTap there is nothing to tap', (
      WidgetTester tester,
    ) async {
      await _pump(tester, const MailNotSetUp());

      expect(find.byType(GestureDetector), findsNothing);
    });
  });
}
