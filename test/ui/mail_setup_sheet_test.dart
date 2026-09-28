import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/ui/mail_setup_sheet.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_mail_service.dart';

Future<List<bool>> _open(WidgetTester tester, FakeMailService mail) async {
  final List<bool> outcomes = <bool>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () async =>
              outcomes.add(await showMailSetupSheet(context, mail: mail)),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return outcomes;
}

Finder _field(Key key) => find.byKey(key);

TextField _textField(WidgetTester tester, Key key) =>
    tester.widget<TextField>(_field(key));

void main() {
  testWidgets('the password is hidden, and nothing is autocorrected', (
    WidgetTester tester,
  ) async {
    await _open(tester, FakeMailService());

    final TextField password = _textField(tester, mailPasswordKey);
    expect(password.obscureText, isTrue);
    expect(password.autocorrect, isFalse);
    expect(password.enableSuggestions, isFalse);
    expect(find.text(Messages.mailAppPasswordNote), findsOneWidget);
  });

  testWidgets('the server follows the address until it is typed over', (
    WidgetTester tester,
  ) async {
    await _open(tester, FakeMailService());

    await tester.enterText(_field(mailEmailKey), 'kay@gmail.com');
    await tester.pump();
    expect(find.text('imap.gmail.com'), findsOneWidget);

    await tester.enterText(_field(mailServerKey), 'mail.example.com:143');
    await tester.enterText(_field(mailEmailKey), 'kay@outlook.com');
    await tester.pump();

    expect(find.text('mail.example.com:143'), findsOneWidget);
    expect(find.text('outlook.office365.com'), findsNothing);
  });

  testWidgets('CONNECT waits until every field is filled in', (
    WidgetTester tester,
  ) async {
    final FakeMailService mail = FakeMailService();
    await _open(tester, mail);

    await tester.enterText(_field(mailEmailKey), 'kay@gmail.com');
    await tester.pump();
    await tester.tap(find.byKey(mailConnectKey));
    await tester.pump();

    expect(mail.setUps, isEmpty);
  });

  testWidgets('CONNECT sets up with what was typed, and closes on success', (
    WidgetTester tester,
  ) async {
    final FakeMailService mail = FakeMailService();
    final List<bool> outcomes = await _open(tester, mail);

    await tester.enterText(_field(mailEmailKey), ' kay@gmail.com ');
    await tester.enterText(_field(mailPasswordKey), 'abcd efgh ijkl mnop');
    await tester.pump();
    await tester.tap(find.byKey(mailConnectKey));
    await tester.pumpAndSettle();

    // Spaces in an app password are only how Google shows it.
    expect(mail.setUps, <(String, String, String)>[
      ('kay@gmail.com', 'imap.gmail.com', 'abcdefghijklmnop'),
    ]);
    expect(outcomes, <bool>[true]);
    expect(find.byKey(mailConnectKey), findsNothing);
  });

  testWidgets('a failure says why, keeps the sheet and the fields', (
    WidgetTester tester,
  ) async {
    final FakeMailService mail = FakeMailService()
      ..setUpProblem = 'imap.gmail.com refused the login';
    final List<bool> outcomes = await _open(tester, mail);

    await tester.enterText(_field(mailEmailKey), 'kay@gmail.com');
    await tester.enterText(_field(mailPasswordKey), 'wrong');
    await tester.pump();
    await tester.tap(find.byKey(mailConnectKey));
    await tester.pumpAndSettle();

    expect(find.text('IMAP.GMAIL.COM REFUSED THE LOGIN'), findsOneWidget);
    expect(find.byKey(mailConnectKey), findsOneWidget);
    expect(find.text('kay@gmail.com'), findsOneWidget);
    expect(outcomes, isEmpty);
  });

  testWidgets('closing without connecting reports false', (
    WidgetTester tester,
  ) async {
    final List<bool> outcomes = await _open(tester, FakeMailService());

    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();

    expect(outcomes, <bool>[false]);
  });
}
