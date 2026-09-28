import 'package:android_tile_launcher/model/conversion.dart';
import 'package:android_tile_launcher/model/rates.dart';
import 'package:android_tile_launcher/model/units.dart';
import 'package:flutter_test/flutter_test.dart';

final Rates _rates = Rates(
  perEuro: const <String, double>{'EUR': 1, 'SEK': 11.29, 'USD': 1.1403},
  date: DateTime(2026, 9, 25),
  fetchedAt: DateTime(2026, 9, 25, 12),
);

void main() {
  group('keyNumber', () {
    String keys(List<String> presses, [String start = '']) =>
        presses.fold(start, keyNumber);

    test('digits build a number', () {
      expect(keys(<String>['1', '2', '3']), '123');
    });

    test('one decimal point, and 0. when it comes first', () {
      expect(keys(<String>['.']), '0.');
      expect(keys(<String>['1', '.', '5', '.']), '1.5');
      expect(keys(<String>['-', '.']), '-0.');
    });

    test('no leading zeros', () {
      expect(keys(<String>['0', '0']), '0');
      expect(keys(<String>['0', '5']), '5');
      expect(keys(<String>['+/-', '0', '5']), '-5');
    });

    test('+/- flips the sign, and can start one', () {
      expect(keys(<String>['5', '+/-']), '-5');
      expect(keys(<String>['5', '+/-', '+/-']), '5');
      expect(keys(<String>['+/-']), '-');
    });

    test('DEL takes back a character', () {
      expect(keys(<String>['1', '2', 'DEL']), '1');
      expect(keys(<String>['DEL']), '');
    });

    test('stops at fifteen digits', () {
      final String long = keys(List<String>.filled(20, '7'));

      expect(long.length, 15);
    });
  });

  group('convertedUnits', () {
    UnitDef unit(String name) => findUnit(name)!;

    test('kilometres to miles', () {
      expect(
        convertedUnits('5', unit('km'), unit('mi')),
        startsWith('3.10685'),
      );
    });

    test('temperatures use their offsets', () {
      expect(convertedUnits('100', unit('c'), unit('f')), '212');
      expect(convertedUnits('-40', unit('c'), unit('f')), '-40');
    });

    test('a number that is not finished yet gives nothing', () {
      expect(convertedUnits('', unit('km'), unit('mi')), isNull);
      expect(convertedUnits('-', unit('km'), unit('mi')), isNull);
      expect(convertedUnits('.', unit('km'), unit('mi')), isNull);
    });

    test('a trailing point is fine', () {
      expect(convertedUnits('5.', unit('km'), unit('m')), '5000');
    });
  });

  group('convertedMoney', () {
    test('via the euro, in cents', () {
      expect(convertedMoney('100', _rates, 'SEK', 'EUR'), '8.86');
      expect(convertedMoney('1', _rates, 'EUR', 'SEK'), '11.29');
    });

    test('an unknown currency, or no number yet, gives nothing', () {
      expect(convertedMoney('100', _rates, 'SEK', 'XXX'), isNull);
      expect(convertedMoney('', _rates, 'SEK', 'EUR'), isNull);
    });
  });

  group('formatAmount', () {
    test('cents for everyday amounts', () {
      expect(formatAmount(8.857), '8.86');
      expect(formatAmount(0), '0.00');
      expect(formatAmount(-3.5), '-3.50');
    });

    test('significant digits for tiny ones', () {
      expect(formatAmount(0.000123456), '0.000123');
    });
  });

  group('labels', () {
    test(
      'a unit is its symbol in capitals, temperatures with a degree sign',
      () {
        expect(unitLabel(findUnit('km')!), 'KM');
        expect(unitLabel(findUnit('c')!), '°C');
        expect(unitLabel(findUnit('f')!), '°F');
        expect(unitLabel(findUnit('k')!), 'K');
        expect(kindLabel(UnitKind.temperature), 'TEMP');
        expect(kindLabel(UnitKind.length), 'LENGTH');
      },
    );
  });

  group('defaults', () {
    test('every kind starts on a real pair of units of that kind', () {
      for (final UnitKind kind in UnitKind.values) {
        final ({String from, String to}) pair = defaultUnits(kind);

        expect(findUnit(pair.from)?.kind, kind, reason: '$kind from');
        expect(findUnit(pair.to)?.kind, kind, reason: '$kind to');
      }
    });

    test('currencies list the usual ones first, then the rest in order', () {
      expect(
        orderedCurrencies(<String>['AUD', 'EUR', 'GBP', 'JPY', 'SEK', 'USD']),
        <String>['SEK', 'EUR', 'USD', 'GBP', 'AUD', 'JPY'],
      );
    });
  });
}
