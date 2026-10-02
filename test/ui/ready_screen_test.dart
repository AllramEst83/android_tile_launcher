import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/services/todo_list.dart';
import 'package:android_tile_launcher/ui/ready_screen.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_agenda_repository.dart';
import '../fakes/fake_mail_service.dart';
import '../fakes/in_memory_local_store.dart';

// Monday 28 September 2026, half past ten.
final DateTime _now = DateTime(2026, 9, 28, 10, 30);

Future<TodoList> _pump(
  WidgetTester tester, {
  AgendaSnapshot? agenda,
  MailResult? mail,
  List<String> todos = const <String>[],
}) async {
  final TodoList list = TodoList(store: InMemoryLocalStore());
  for (final String t in todos) {
    await list.add(t);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: ReadyScreen(
        agenda: FakeAgendaRepository(
          agenda ??
              AgendaReady(<CalendarEvent>[
                CalendarEvent(
                  id: 1,
                  title: 'Lunch',
                  start: DateTime(2026, 9, 28, 12),
                  end: DateTime(2026, 9, 28, 13),
                ),
              ]),
        ),
        todos: list,
        mail: FakeMailService(
          mail ?? const MailMessages([], total: 0, unread: 4),
        ),
        clock: () => _now,
      ),
    ),
  );
  return list;
}

String _text(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(readyTextKey)).data!;

void main() {
  testWidgets('types LOAD "TODAY",8 first', (WidgetTester tester) async {
    await _pump(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(_text(tester), startsWith('LOAD "'));
    expect(_text(tester), isNot(contains('NEXT UP')));
  });

  testWidgets('runs through to the whole summary on its own', (
    WidgetTester tester,
  ) async {
    await _pump(tester, todos: <String>['Milk']);
    await tester.pump(const Duration(seconds: 30));

    final String text = _text(tester);
    expect(text, contains('LOAD "TODAY",8'));
    expect(text, contains('MON 28 SEP'));
    expect(text, contains('12:00 LUNCH'));
    expect(text, contains('[ ] MILK'));
    expect(text, contains('UNREAD MAIL: 4'));
  });

  testWidgets('a tap skips the typing', (WidgetTester tester) async {
    await _pump(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(_text(tester), isNot(contains('UNREAD MAIL')));

    await tester.tap(find.byKey(readyTextKey));
    await tester.pump();

    expect(_text(tester), contains('UNREAD MAIL: 4'));
  });

  testWidgets('leaves out what it cannot read', (WidgetTester tester) async {
    await _pump(
      tester,
      agenda: const AgendaNeedsPermission(),
      mail: const MailNotSetUp(),
    );
    await tester.pump(const Duration(seconds: 30));

    final String text = _text(tester);
    expect(text, contains('NO CALENDAR ACCESS.'));
    expect(text, isNot(contains('UNREAD MAIL')));
  });

  testWidgets('the border flashes while loading, then is steady', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    final Set<Color?> seen = <Color?>{};
    for (int i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      seen.add(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor);
    }

    expect(seen.length, greaterThan(2));
    await tester.pump(const Duration(seconds: 30));
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      C64.lightBlue,
    );
  });

  testWidgets('X closes it', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: tileLauncherTheme(),
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showReadyScreen(
              context,
              agenda: FakeAgendaRepository(const AgendaReady([])),
              todos: TodoList(store: InMemoryLocalStore()),
              mail: FakeMailService(const MailNotSetUp()),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(readyCloseKey), findsOneWidget);

    await tester.tap(find.byKey(readyCloseKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(readyCloseKey), findsNothing);
  });
}
