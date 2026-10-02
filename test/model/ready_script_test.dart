import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/model/ready_script.dart';
import 'package:android_tile_launcher/model/todo_item.dart';
import 'package:flutter_test/flutter_test.dart';

// Monday 28 September 2026, half past ten.
final DateTime _now = DateTime(2026, 9, 28, 10, 30);

CalendarEvent _event(int id, String title, DateTime start, {int hours = 1}) =>
    CalendarEvent(
      id: id,
      title: title,
      start: start,
      end: start.add(Duration(hours: hours)),
    );

void main() {
  test('is typed as a LOAD of today, then the summary after READY.', () {
    final ReadyScript script = readyScript(
      now: _now,
      events: const <CalendarEvent>[],
      todos: const <TodoItem>[],
    );

    expect(script.intro, <String>[
      'LOAD "TODAY",8',
      'SEARCHING FOR TODAY',
      'LOADING',
    ]);
    expect(script.body.take(3), <String>['READY.', 'RUN', '']);
    expect(script.body[3], 'MON 28 SEP');
    expect(script.body.last, 'READY.');
  });

  test(
    'lists the events still to come, soonest first, and counts the rest',
    () {
      final ReadyScript script = readyScript(
        now: _now,
        events: <CalendarEvent>[
          // Over already: left out.
          _event(1, 'Breakfast', DateTime(2026, 9, 28, 8)),
          _event(2, 'Lunch', DateTime(2026, 9, 28, 12)),
          _event(3, 'Dentist', DateTime(2026, 9, 29, 9)),
          _event(4, 'Gym', DateTime(2026, 9, 29, 17)),
          _event(5, 'Dinner', DateTime(2026, 9, 29, 19)),
          _event(6, 'Film', DateTime(2026, 9, 30, 20)),
        ],
        todos: const <TodoItem>[],
      );

      expect(script.body, contains(' 12:00 LUNCH'));
      expect(script.body, contains(' TUE 09:00 DENTIST'));
      expect(script.body.any((l) => l.contains('BREAKFAST')), isFalse);
      expect(script.body.any((l) => l.contains('FILM')), isFalse);
      expect(script.body, contains(' +1 MORE'));
    },
  );

  test('says so when nothing is planned or the calendar is closed', () {
    expect(
      readyScript(
        now: _now,
        events: const <CalendarEvent>[],
        todos: const <TodoItem>[],
      ).body,
      contains(' NOTHING PLANNED.'),
    );
    expect(
      readyScript(now: _now, events: null, todos: const <TodoItem>[]).body,
      contains(' NO CALENDAR ACCESS.'),
    );
  });

  test('lists only the open to-dos', () {
    final ReadyScript script = readyScript(
      now: _now,
      events: const <CalendarEvent>[],
      todos: const <TodoItem>[
        TodoItem(id: 1, title: 'Milk'),
        TodoItem(id: 2, title: 'Bread', done: true),
        TodoItem(id: 3, title: 'Eggs'),
      ],
    );

    expect(script.body, contains('TO-DO: 2 OPEN'));
    expect(script.body, contains(' [ ] MILK'));
    expect(script.body, contains(' [ ] EGGS'));
    expect(script.body.any((l) => l.contains('BREAD')), isFalse);
  });

  test('tells an empty list from one that is all done', () {
    expect(
      readyScript(
        now: _now,
        events: const <CalendarEvent>[],
        todos: const <TodoItem>[],
      ).body,
      contains(' NOTHING TO DO.'),
    );
    expect(
      readyScript(
        now: _now,
        events: const <CalendarEvent>[],
        todos: const <TodoItem>[TodoItem(id: 1, title: 'a', done: true)],
      ).body,
      contains(' ALL DONE.'),
    );
  });

  test('prints the unread mail only when it is known', () {
    final ReadyScript with4 = readyScript(
      now: _now,
      events: const <CalendarEvent>[],
      todos: const <TodoItem>[],
      unread: 4,
    );
    final ReadyScript without = readyScript(
      now: _now,
      events: const <CalendarEvent>[],
      todos: const <TodoItem>[],
    );

    expect(with4.body, contains('UNREAD MAIL: 4'));
    expect(without.body.any((l) => l.startsWith('UNREAD')), isFalse);
  });

  test('caps the to-do lines and counts the rest', () {
    final ReadyScript script = readyScript(
      now: _now,
      events: const <CalendarEvent>[],
      todos: <TodoItem>[
        for (int i = 1; i <= 8; i++) TodoItem(id: i, title: 'Job $i'),
      ],
    );

    expect(script.body.where((l) => l.startsWith(' [ ]')), hasLength(5));
    expect(script.body, contains(' +3 MORE'));
  });
}
