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
  TextScaler textScaler = TextScaler.noScaling,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
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

    testWidgets('medium on a narrow, tall tile: content sits at the top, not '
        'centred with a gap above it', (WidgetTester tester) async {
      // Regression: this branch centred its Column, unnoticed while the
      // only medium size tested was square (185x185, content nearly
      // filling it). TileSize.tall (1 column x 2 rows) is the same width
      // but twice as high, so the leftover height below the content used
      // to be split above and below it too, pushing MAIL/the count/UNREAD
      // visibly down from the tile's top edge.
      await _pump(tester, _inbox, size: const Size(150, 300));

      final double tileTop = tester
          .getTopLeft(find.byType(MailTileContentView))
          .dy;
      final double titleTop = tester
          .getTopLeft(find.text(Messages.mailTitle))
          .dy;
      // Only the tile's own padding (half a gutter) should separate them.
      expect(titleTop - tileTop, lessThan(TileMetrics.gutter));
    });

    testWidgets(
      'medium on a tile too short for the newest message: no overflow, '
      'and the sender/subject shrink or drop rather than spill past the '
      'tile',
      (WidgetTester tester) async {
        // Regression: this branch had no height budget at all — it always
        // added the sender and a two-line subject under the header, so a
        // medium tile short enough (a real one, on a phone whose grid gives
        // it less headroom than the square 185x185 this group otherwise
        // tests) overflowed at its bottom edge.
        await _pump(tester, _inbox, size: const Size(150, 100));

        expect(tester.takeException(), isNull);
      },
    );

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

  group('at a larger text scale (the FONT SIZE setting)', () {
    // Regression: the wide inbox list's rows were fixed-height SizedBoxes
    // sized off the bare, unscaled type size, so a message's sender and
    // subject painted taller than their box at a larger scale and bled into
    // the row below — a visual overlap a `RenderFlex` never flags (only a
    // *main*-axis overflow throws; these rows overflow their *cross* axis),
    // so `tester.takeException()` alone cannot catch it. The regression test
    // is geometric: the row's own allocated height must grow with the
    // scaler, not stay fixed while the text inside it grows.
    const TextScaler extraLarge = TextScaler.linear(1.3);

    testWidgets('small: the count still fits', (WidgetTester tester) async {
      await _pump(
        tester,
        _inbox,
        size: const Size(90, 90),
        textScaler: extraLarge,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('medium: the newest message still fits', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _inbox, textScaler: extraLarge);

      expect(tester.takeException(), isNull);
    });

    testWidgets('without an inbox: the message still fits', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const MailUnavailable('imap.gmail.com did not answer'),
        textScaler: extraLarge,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'wide: a message row grows with the scale, so its text is never '
      'taller than the row',
      (WidgetTester tester) async {
        await _pump(tester, _inbox, size: const Size(380, 400));
        final double normalHeight = tester
            .getRect(find.byKey(mailRowKey(0)))
            .height;

        await _pump(
          tester,
          _inbox,
          size: const Size(380, 400),
          textScaler: extraLarge,
        );
        final double scaledHeight = tester
            .getRect(find.byKey(mailRowKey(0)))
            .height;

        expect(scaledHeight, closeTo(normalHeight * 1.3, 0.5));
      },
    );

    testWidgets('wide: the header row grows with the scale too', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _inbox, size: const Size(380, 400));
      final double normalHeight = tester
          .getRect(find.byKey(mailHeaderKey))
          .height;

      await _pump(
        tester,
        _inbox,
        size: const Size(380, 400),
        textScaler: extraLarge,
      );
      final double scaledHeight = tester
          .getRect(find.byKey(mailHeaderKey))
          .height;

      // Grows with the scale, not by exactly the same factor: 2px of it is
      // fixed padding, not type size.
      expect(scaledHeight, greaterThan(normalHeight * 1.2));
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
