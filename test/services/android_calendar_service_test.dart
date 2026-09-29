import 'package:android_tile_launcher/services/android_calendar_service.dart';
import 'package:android_tile_launcher/services/calendar_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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

  final AndroidCalendarService service = AndroidCalendarService(
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
}
