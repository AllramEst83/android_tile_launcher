import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/ui/compose_sheet.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_mail_service.dart';

Future<void> _open(WidgetTester tester, FakeMailService mail) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showComposeSheet(context, mail: mail),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Backspacing past the last (invisible) character of an otherwise-empty
/// field with chips already in it: what the field's own text becomes once
/// the platform reports the deletion, whatever key actually caused it.
Future<void> _backspaceToEmpty(WidgetTester tester, Key key) async {
  await tester.enterText(find.byKey(key), '');
  await tester.pumpAndSettle();
}

/// What a field actually reads as, ignoring the invisible placeholder it
/// carries while empty with chips already there.
String _visible(WidgetTester tester, Key key) => tester
    .widget<TextField>(find.byKey(key))
    .controller!
    .text
    .replaceAll('​', '');

void main() {
  group('chip-as-you-type', () {
    testWidgets('a complete address followed by a space becomes a chip', (
      WidgetTester tester,
    ) async {
      await _open(tester, FakeMailService());

      await tester.enterText(find.byKey(composeToKey), 'anna@example.com ');
      await tester.pumpAndSettle();

      expect(
        find.byKey(composeChipKey('to', 'anna@example.com')),
        findsOneWidget,
      );
      expect(_visible(tester, composeToKey), '');
    });

    testWidgets('a comma or semicolon chips it too', (
      WidgetTester tester,
    ) async {
      await _open(tester, FakeMailService());

      await tester.enterText(find.byKey(composeToKey), 'anna@example.com,');
      await tester.pumpAndSettle();
      expect(
        find.byKey(composeChipKey('to', 'anna@example.com')),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(composeCcKey), 'bo@example.com;');
      await tester.pumpAndSettle();
      expect(
        find.byKey(composeChipKey('cc', 'bo@example.com')),
        findsOneWidget,
      );
    });

    testWidgets('an incomplete address stays as text, not a chip', (
      WidgetTester tester,
    ) async {
      await _open(tester, FakeMailService());

      await tester.enterText(find.byKey(composeToKey), 'anna ');
      await tester.pumpAndSettle();

      expect(find.byKey(composeChipKey('to', 'anna')), findsNothing);
      expect(
        tester.widget<TextField>(find.byKey(composeToKey)).controller?.text,
        'anna ',
      );
    });

    testWidgets('pasting several at once chips the complete ones', (
      WidgetTester tester,
    ) async {
      await _open(tester, FakeMailService());

      await tester.enterText(
        find.byKey(composeToKey),
        'anna@example.com, bad, bo@example.com ',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(composeChipKey('to', 'anna@example.com')),
        findsOneWidget,
      );
      expect(
        find.byKey(composeChipKey('to', 'bo@example.com')),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byKey(composeToKey)).controller?.text,
        'bad,',
      );
    });

    testWidgets('deleting letters keeps it text until complete again', (
      WidgetTester tester,
    ) async {
      await _open(tester, FakeMailService());

      await tester.enterText(find.byKey(composeToKey), 'anna@example.com');
      await tester.pumpAndSettle();
      // No delimiter typed yet: still plain text, not a chip.
      expect(
        find.byKey(composeChipKey('to', 'anna@example.com')),
        findsNothing,
      );

      await tester.enterText(find.byKey(composeToKey), 'anna@example.co');
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byKey(composeToKey)).controller?.text,
        'anna@example.co',
      );
    });

    testWidgets('losing focus chips a finished address', (
      WidgetTester tester,
    ) async {
      await _open(tester, FakeMailService());

      await tester.enterText(find.byKey(composeToKey), 'anna@example.com');
      await tester.tap(find.byKey(composeSubjectKey));
      await tester.pumpAndSettle();

      expect(
        find.byKey(composeChipKey('to', 'anna@example.com')),
        findsOneWidget,
      );
    });

    testWidgets('backspace on an empty field un-chips the last address', (
      WidgetTester tester,
    ) async {
      await _open(tester, FakeMailService());
      await tester.enterText(find.byKey(composeToKey), 'anna@example.com,');
      await tester.pumpAndSettle();
      expect(
        find.byKey(composeChipKey('to', 'anna@example.com')),
        findsOneWidget,
      );

      await _backspaceToEmpty(tester, composeToKey);

      expect(
        find.byKey(composeChipKey('to', 'anna@example.com')),
        findsNothing,
      );
      expect(
        tester.widget<TextField>(find.byKey(composeToKey)).controller?.text,
        'anna@example.com',
      );
    });

    testWidgets("a chip's own X removes it", (WidgetTester tester) async {
      await _open(tester, FakeMailService());
      await tester.enterText(find.byKey(composeToKey), 'anna@example.com,');
      await tester.pumpAndSettle();

      await tester.tap(find.text('X'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(composeChipKey('to', 'anna@example.com')),
        findsNothing,
      );
    });

    testWidgets('sending still works from pending text with no delimiter', (
      WidgetTester tester,
    ) async {
      final FakeMailService mail = FakeMailService();
      await _open(tester, mail);

      await tester.enterText(find.byKey(composeToKey), 'anna@example.com');
      await tester.enterText(find.byKey(composeCcKey), 'bo@example.com');
      await tester.enterText(find.byKey(composeSubjectKey), 'Hi');
      await tester.enterText(find.byKey(composeBodyKey), 'Hello there');
      await tester.tap(find.byKey(composeSendKey));
      await tester.pumpAndSettle();

      expect(mail.sent, hasLength(1));
      final (to, cc, subject, text) = mail.sent.single;
      expect(to, <String>['anna@example.com']);
      expect(cc, <String>['bo@example.com']);
      expect(subject, 'Hi');
      expect(text, 'Hello there');
      expect(find.text(Messages.mailComposeTitle), findsNothing);
    });
  });
}
