import 'package:android_tile_launcher/model/contact.dart';
import 'package:flutter_test/flutter_test.dart';

Contact _contact(String key, String name, List<PhoneNumber> numbers) =>
    Contact(key: key, name: name, numbers: numbers);

void main() {
  group('dialable', () {
    test('keeps digits and a leading plus, drops the rest', () {
      expect(dialable('+46 70-123 45 67'), '+46701234567');
      expect(dialable('(08) 123 456'), '08123456');
      expect(dialable('*100#'), '100');
    });
  });

  group('whatsAppNumber', () {
    test('a number with a plus is international already', () {
      expect(whatsAppNumber('+46 70 123 45 67'), '46701234567');
    });

    test('a 00 prefix is a plus', () {
      expect(whatsAppNumber('0046701234567'), '46701234567');
    });

    test('a national number gets the default country code', () {
      expect(whatsAppNumber('070-123 45 67'), '46701234567');
      expect(defaultCountryCode, '46');
    });

    test('a number that starts with neither is left as it is', () {
      expect(whatsAppNumber('46701234567'), '46701234567');
    });
  });

  group('preferredNumber', () {
    test('a mobile number wins over one listed before it', () {
      final Contact c = _contact('k', 'Anna', const <PhoneNumber>[
        PhoneNumber('08-123', 'HOME'),
        PhoneNumber('070-1', 'MOBILE'),
      ]);

      expect(c.preferredNumber.number, '070-1');
    });

    test('without a mobile number, the first', () {
      final Contact c = _contact('k', 'Anna', const <PhoneNumber>[
        PhoneNumber('08-123', 'HOME'),
        PhoneNumber('08-456', 'WORK'),
      ]);

      expect(c.preferredNumber.number, '08-123');
    });
  });

  group('findContact', () {
    final List<Contact> book = <Contact>[
      _contact('k1', 'Anna', const <PhoneNumber>[PhoneNumber('1', 'MOBILE')]),
      _contact('k2', 'Bo', const <PhoneNumber>[PhoneNumber('2', 'MOBILE')]),
    ];

    test('by lookup key, whatever the stored name says', () {
      expect(findContact(book, key: 'k2', name: 'Old name')?.name, 'Bo');
    });

    test('by name when the key no longer resolves, ignoring case', () {
      expect(findContact(book, key: 'gone', name: 'ANNA')?.key, 'k1');
    });

    test('null when neither is there', () {
      expect(findContact(book, key: 'gone', name: 'Cecilia'), isNull);
    });
  });
}
