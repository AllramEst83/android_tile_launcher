import 'package:android_tile_launcher/model/contact.dart';
import 'package:android_tile_launcher/services/android_contacts_service.dart';
import 'package:android_tile_launcher/services/contacts_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _channel = MethodChannel(
  AndroidContactsService.channelName,
);

void _mockChannel(Future<Object?>? Function(MethodCall call) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

Map<String, Object?> _row(
  String key,
  String? name,
  String number, {
  String? label = 'Mobile',
}) => <String, Object?>{
  'key': key,
  'name': name,
  'number': number,
  'label': label,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => _mockChannel((call) => null));

  final AndroidContactsService service = AndroidContactsService(
    channel: _channel,
    timeout: const Duration(milliseconds: 50),
  );

  Future<List<Contact>> read() async =>
      ((await service.all()) as ContactsRead).contacts;

  test('asks for all, and never for permission', () async {
    MethodCall? seen;
    _mockChannel((call) async {
      seen = call;
      return <Object?>[];
    });

    await service.all();

    expect(seen?.method, 'all');
  });

  test('one contact per lookup key, numbers in the order given', () async {
    _mockChannel(
      (call) async => <Object?>[
        _row('k1', 'Anna', '070-111 11 11'),
        _row('k1', 'Anna', '08-222 22 22', label: 'Home'),
        _row('k2', 'Bo', '070-333 33 33'),
      ],
    );

    final List<Contact> found = await read();

    expect(found.map((c) => c.name), <String>['Anna', 'Bo']);
    expect(found.first.key, 'k1');
    expect(found.first.numbers, const <PhoneNumber>[
      PhoneNumber('070-111 11 11', 'MOBILE'),
      PhoneNumber('08-222 22 22', 'HOME'),
    ]);
  });

  test('the same number written two ways is one number', () async {
    _mockChannel(
      (call) async => <Object?>[
        _row('k1', 'Anna', '070-111 11 11'),
        _row('k1', 'Anna', '0701111111'),
      ],
    );

    expect((await read()).single.numbers, hasLength(1));
  });

  test('a contact with no name is shown by its number', () async {
    _mockChannel((call) async => <Object?>[_row('k1', null, '070-111 11 11')]);

    expect((await read()).single.name, '070-111 11 11');
  });

  test('a missing label is OTHER', () async {
    _mockChannel(
      (call) async => <Object?>[_row('k1', 'Anna', '070-1', label: null)],
    );

    expect((await read()).single.numbers.single.label, 'OTHER');
  });

  test('skips rows with no key or no number', () async {
    _mockChannel(
      (call) async => <Object?>[
        <String, Object?>{'name': 'No key', 'number': '1'},
        <String, Object?>{'key': 'k', 'name': 'No number'},
        _row('k2', 'Bo', '070-2'),
      ],
    );

    expect((await read()).map((c) => c.name), <String>['Bo']);
  });

  test('no permission is no access, not an error', () async {
    _mockChannel(
      (call) async => throw PlatformException(code: 'NO_PERMISSION'),
    );

    expect(await service.all(), isA<ContactsNoAccess>());
  });

  test('any other platform error is unavailable', () async {
    _mockChannel((call) async => throw PlatformException(code: 'QUERY_FAILED'));

    expect(await service.all(), isA<ContactsUnavailable>());
  });

  test('a reply that never comes gives up', () async {
    _mockChannel((call) => Future<Object?>.delayed(const Duration(seconds: 5)));

    expect(await service.all(), isA<ContactsUnavailable>());
  });

  test('no handler at all is unsupported, not a crash', () async {
    _mockChannel((call) => throw MissingPluginException());

    expect(await service.all(), isA<ContactsUnavailable>());
  });
}
