import 'package:android_tile_launcher/model/calendar_choices.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:flutter_test/flutter_test.dart';

CalendarEvent _on(int? calendarId, {bool visible = true}) => CalendarEvent(
  id: calendarId ?? 0,
  title: 'E',
  start: DateTime(2026, 9, 28, 9),
  end: DateTime(2026, 9, 28, 10),
  calendarId: calendarId,
  calendarVisible: visible,
);

void main() {
  test('with no choices, the phone calendar app decides', () {
    const CalendarChoices none = CalendarChoices();

    expect(none.shows(const CalendarInfo(id: 1, name: 'A')), isTrue);
    expect(
      none.shows(const CalendarInfo(id: 2, name: 'B', visible: false)),
      isFalse,
    );
    expect(none.showsEvent(_on(1)), isTrue);
    expect(none.showsEvent(_on(2, visible: false)), isFalse);
  });

  test('a choice beats the phone, either way', () {
    const CalendarChoices picked = CalendarChoices(<int, bool>{
      1: false,
      2: true,
    });

    expect(picked.shows(const CalendarInfo(id: 1, name: 'A')), isFalse);
    expect(
      picked.shows(const CalendarInfo(id: 2, name: 'B', visible: false)),
      isTrue,
    );
    expect(picked.showsEvent(_on(1)), isFalse);
    expect(picked.showsEvent(_on(2, visible: false)), isTrue);
  });

  test('an event that never said its calendar always shows', () {
    const CalendarChoices picked = CalendarChoices(<int, bool>{0: false});

    expect(picked.showsEvent(_on(null)), isTrue);
  });

  test('filter keeps the order of what it keeps', () {
    final List<CalendarEvent> events = <CalendarEvent>[_on(3), _on(1), _on(2)];

    expect(
      const CalendarChoices(<int, bool>{1: false}).filter(events),
      <CalendarEvent>[events[0], events[2]],
    );
  });

  test('withShown changes one calendar and leaves the original alone', () {
    const CalendarChoices before = CalendarChoices(<int, bool>{1: false});

    final CalendarChoices after = before.withShown(2, shown: false);

    expect(after, const CalendarChoices(<int, bool>{1: false, 2: false}));
    expect(before, const CalendarChoices(<int, bool>{1: false}));
  });

  test('hiddenAmong counts the hidden calendars', () {
    const List<CalendarInfo> calendars = <CalendarInfo>[
      CalendarInfo(id: 1, name: 'A'),
      CalendarInfo(id: 2, name: 'B', visible: false),
      CalendarInfo(id: 3, name: 'C'),
    ];

    expect(
      const CalendarChoices(<int, bool>{1: false}).hiddenAmong(calendars),
      2,
    );
  });

  test('JSON round trip', () {
    const CalendarChoices picked = CalendarChoices(<int, bool>{
      1: false,
      22: true,
    });

    expect(CalendarChoices.fromJson(picked.toJson()), picked);
  });

  test('fromJson skips what it does not understand', () {
    expect(
      CalendarChoices.fromJson(<String, Object?>{
        '1': false,
        'x': true,
        '2': 'yes',
        '3': null,
      }),
      const CalendarChoices(<int, bool>{1: false}),
    );
    expect(CalendarChoices.fromJson('nonsense'), const CalendarChoices());
    expect(CalendarChoices.fromJson(null), const CalendarChoices());
  });
}
