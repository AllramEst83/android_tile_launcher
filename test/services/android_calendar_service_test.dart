import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/services/android_calendar_service.dart';
import 'package:android_tile_launcher/services/calendar_service.dart';
import 'package:android_tile_launcher/services/permission_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_permission_service.dart';

const MethodChannel _channel = MethodChannel(
  AndroidCalendarService.channelName,
);

/// Stands in for the Kotlin side; the real platform is never touched in tests.
void _mockChannel(Future<Object?>? Function(MethodCall call) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

int _ms(DateTime time) => time.millisecondsSinceEpoch;

Map<String, Object?> _timed(
  int id,
  String title,
  DateTime start,
  DateTime end,
) => <String, Object?>{
  'id': id,
  'title': title,
  'begin': _ms(start),
  'end': _ms(end),
  'allDay': false,
};

/// The provider stores an all-day event as UTC midnights, end exclusive.
Map<String, Object?> _allDay(
  int id,
  String title,
  int year,
  int month,
  int day, {
  int days = 1,
}) => <String, Object?>{
  'id': id,
  'title': title,
  'begin': _ms(DateTime.utc(year, month, day)),
  'end': _ms(DateTime.utc(year, month, day + days)),
  'allDay': true,
};

final DateTime _from = DateTime(2026, 9, 26);
final DateTime _to = DateTime(2026, 9, 27);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => _mockChannel((call) => null));

  final FakePermissionService permissions = FakePermissionService();
  setUp(() {
    permissions.answer = PermissionStatus.granted;
    permissions.requested.clear();
  });
  final AndroidCalendarService service = AndroidCalendarService(
    permissions: permissions,
    channel: _channel,
    timeout: const Duration(milliseconds: 50),
  );

  Future<List<Object?>> titles() async =>
      ((await service.events(from: _from, to: _to)) as CalendarEvents).events
          .map((e) => e.title)
          .toList();

  Future<CalendarEvents> events() async =>
      (await service.events(from: _from, to: _to)) as CalendarEvents;

  test('asks for events a day either side, and never for permission', () async {
    MethodCall? seen;
    _mockChannel((call) async {
      seen = call;
      return <Object?>[];
    });

    await service.events(from: _from, to: _to);

    expect(seen?.method, 'events');
    expect(seen?.arguments, <String, Object?>{
      'begin': _ms(DateTime(2026, 9, 25)),
      'end': _ms(DateTime(2026, 9, 28)),
    });
  });

  test('maps a timed event to local times', () async {
    _mockChannel(
      (call) async => <Object?>[
        <String, Object?>{
          ..._timed(
            7,
            ' Lunch ',
            DateTime(2026, 9, 26, 12),
            DateTime(2026, 9, 26, 13),
          ),
          'location': ' Cafe ',
          'description': ' Bring the report ',
          'calendarId': 4,
        },
      ],
    );

    final found = (await events()).events;

    expect(found, hasLength(1));
    expect(found.single.id, 7);
    expect(found.single.title, 'Lunch');
    expect(found.single.start, DateTime(2026, 9, 26, 12));
    expect(found.single.end, DateTime(2026, 9, 26, 13));
    expect(found.single.allDay, isFalse);
    expect(found.single.location, 'Cafe');
    expect(found.single.calendarId, 4);
    expect(found.single.description, 'Bring the report');
  });

  test('an all-day event is a date, whatever the time zone', () async {
    _mockChannel((call) async => <Object?>[_allDay(3, 'Holiday', 2026, 9, 26)]);

    final found = (await events()).events;

    expect(found.single.allDay, isTrue);
    expect(found.single.start, DateTime(2026, 9, 26));
    expect(found.single.end, DateTime(2026, 9, 27));
  });

  test('all-day events on the days either side are not in range', () async {
    _mockChannel(
      (call) async => <Object?>[
        _allDay(1, 'Yesterday', 2026, 9, 25),
        _allDay(2, 'Tomorrow', 2026, 9, 27),
      ],
    );

    expect(await titles(), isEmpty);
  });

  test(
    'a multi-day all-day event that reaches into the range is kept',
    () async {
      _mockChannel(
        (call) async => <Object?>[_allDay(3, 'Trip', 2026, 9, 24, days: 3)],
      );

      expect(await titles(), <Object?>['Trip']);
    },
  );

  test(
    'a timed event outside the range is dropped, one crossing in is kept',
    () async {
      _mockChannel(
        (call) async => <Object?>[
          _timed(
            1,
            'before',
            DateTime(2026, 9, 25, 10),
            DateTime(2026, 9, 25, 11),
          ),
          _timed(
            2,
            'crossing',
            DateTime(2026, 9, 25, 23),
            DateTime(2026, 9, 26, 1),
          ),
          _timed(
            3,
            'after',
            DateTime(2026, 9, 27, 0, 30),
            DateTime(2026, 9, 27, 1),
          ),
        ],
      );

      expect(await titles(), <Object?>['crossing']);
    },
  );

  test('an event with no length is kept when it is in the range', () async {
    final DateTime at = DateTime(2026, 9, 26, 8);
    _mockChannel((call) async => <Object?>[_timed(1, 'ping', at, at)]);

    expect((await events()).events.single.start, at);
  });

  test('all-day events sort first, then by start, then by title', () async {
    _mockChannel(
      (call) async => <Object?>[
        _timed(1, 'b', DateTime(2026, 9, 26, 9), DateTime(2026, 9, 26, 10)),
        _timed(2, 'A', DateTime(2026, 9, 26, 9), DateTime(2026, 9, 26, 10)),
        _timed(3, 'early', DateTime(2026, 9, 26, 7), DateTime(2026, 9, 26, 8)),
        _allDay(4, 'holiday', 2026, 9, 26),
      ],
    );

    expect(await titles(), <Object?>['holiday', 'early', 'A', 'b']);
  });

  test('skips malformed entries and tolerates missing text', () async {
    _mockChannel(
      (call) async => <Object?>[
        <String, Object?>{'title': 'no id'},
        <String, Object?>{'id': 1, 'begin': 'soon', 'end': 2},
        <String, Object?>{
          'id': 5,
          'begin': _ms(DateTime(2026, 9, 26, 9)),
          'end': _ms(DateTime(2026, 9, 26, 10)),
          'title': null,
          'location': ' ',
          'description': ' ',
        },
      ],
    );

    final found = (await events()).events;

    expect(found, hasLength(1));
    expect(found.single.title, '');
    expect(found.single.location, isNull);
    expect(found.single.description, isNull);
    expect(found.single.calendarId, isNull);
  });

  test('a broken range (end before start) is made harmless', () async {
    _mockChannel(
      (call) async => <Object?>[
        _timed(1, 'odd', DateTime(2026, 9, 26, 10), DateTime(2026, 9, 26, 9)),
      ],
    );

    final found = (await events()).events;

    expect(found.single.end, found.single.start);
  });

  test('no permission is no access, not an error', () async {
    _mockChannel(
      (call) async => throw PlatformException(code: 'NO_PERMISSION'),
    );

    expect(await service.events(from: _from, to: _to), isA<CalendarNoAccess>());
  });

  test('any other platform error is unavailable', () async {
    _mockChannel((call) async => throw PlatformException(code: 'QUERY_FAILED'));

    expect(
      await service.events(from: _from, to: _to),
      isA<CalendarUnavailable>(),
    );
  });

  test('a reply that never comes gives up', () async {
    _mockChannel((call) => Future<Object?>.delayed(const Duration(seconds: 5)));

    expect(
      await service.events(from: _from, to: _to),
      isA<CalendarUnavailable>(),
    );
  });

  test('no handler at all is unsupported, not a crash', () async {
    _mockChannel((call) => throw MissingPluginException());

    expect(
      await service.events(from: _from, to: _to),
      isA<CalendarUnavailable>(),
    );
  });

  group('writableCalendars', () {
    test('asks for read permission and maps the calendars', () async {
      _mockChannel(
        (call) async => <Object?>[
          <String, Object?>{'id': 1, 'name': 'Family', 'primary': false},
          <String, Object?>{'id': 2, 'name': '', 'primary': true},
        ],
      );

      final result = await service.writableCalendars();

      expect(permissions.requested, <AppPermission>[AppPermission.calendar]);
      expect(
        (result as CalendarList).calendars.map(
          (c) => (c.id, c.name, c.primary),
        ),
        <(int, String, bool)>[(1, 'Family', false), (2, '?', true)],
      );
    });

    test('refused permission is denied, and connects to nothing', () async {
      permissions.answer = PermissionStatus.denied;
      MethodCall? seen;
      _mockChannel((call) async {
        seen = call;
        return <Object?>[];
      });

      final result = await service.writableCalendars();

      expect(result, isA<CalendarListDenied>());
      expect(seen, isNull);
    });
  });

  group('createEvent / updateEvent', () {
    NewCalendarEvent event({int? calendarId}) => NewCalendarEvent(
      calendarId: calendarId,
      title: 'Lunch',
      location: 'Cafe',
      description: 'Bring the report',
      start: DateTime(2026, 9, 26, 12),
      end: DateTime(2026, 9, 26, 13),
    );

    test('insert asks for write permission and sends the fields', () async {
      MethodCall? seen;
      _mockChannel((call) async {
        seen = call;
        return 9;
      });

      final result = await service.createEvent(event(calendarId: 4));

      expect(permissions.requested, <AppPermission>[
        AppPermission.calendarWrite,
      ]);
      expect(seen?.method, 'insertEvent');
      expect(seen?.arguments, <String, Object?>{
        'calendarId': 4,
        'title': 'Lunch',
        'location': 'Cafe',
        'description': 'Bring the report',
        'begin': _ms(DateTime(2026, 9, 26, 12)),
        'end': _ms(DateTime(2026, 9, 26, 13)),
      });
      expect(result, isA<CalendarEventSaved>());
      expect((result as CalendarEventSaved).id, 9);
    });

    test('update never sends a calendar id of its own', () async {
      MethodCall? seen;
      _mockChannel((call) async {
        seen = call;
        return 9;
      });

      await service.updateEvent(9, event());

      expect(seen?.method, 'updateEvent');
      expect(seen?.arguments, isA<Map<Object?, Object?>>());
      expect((seen!.arguments as Map<Object?, Object?>)['id'], 9);
      expect(
        (seen!.arguments as Map<Object?, Object?>).containsKey('calendarId'),
        isFalse,
      );
    });

    test('refused permission is denied, and connects to nothing', () async {
      permissions.answer = PermissionStatus.permanentlyDenied;
      MethodCall? seen;
      _mockChannel((call) async {
        seen = call;
        return 9;
      });

      final result = await service.createEvent(event(calendarId: 4));

      expect(result, isA<CalendarWriteDenied>());
      expect((result as CalendarWriteDenied).permanent, isTrue);
      expect(seen, isNull);
    });

    test('an event that no longer exists is a failure that says so', () async {
      _mockChannel((call) async => throw PlatformException(code: 'NOT_FOUND'));

      final result = await service.updateEvent(9, event());

      expect(result, isA<CalendarWriteFailed>());
    });
  });

  group('deleteEvent', () {
    test('asks for write permission and reports whether a row went', () async {
      MethodCall? seen;
      _mockChannel((call) async {
        seen = call;
        return true;
      });

      final result = await service.deleteEvent(5);

      expect(permissions.requested, <AppPermission>[
        AppPermission.calendarWrite,
      ]);
      expect(seen?.method, 'deleteEvent');
      expect(seen?.arguments, <String, Object?>{'id': 5});
      expect(result, isA<CalendarEventDeleted>());
    });

    test('nothing removed is already gone, not a failure', () async {
      _mockChannel((call) async => false);

      expect(await service.deleteEvent(5), isA<CalendarEventAlreadyGone>());
    });

    test('refused permission is denied, and connects to nothing', () async {
      permissions.answer = PermissionStatus.denied;
      MethodCall? seen;
      _mockChannel((call) async {
        seen = call;
        return true;
      });

      final result = await service.deleteEvent(5);

      expect(result, isA<CalendarDeleteDenied>());
      expect(seen, isNull);
    });
  });
}
