import 'package:android_tile_launcher/model/number_format.dart';
import 'package:android_tile_launcher/model/rates.dart';
import 'package:android_tile_launcher/model/units.dart';

/// Digits shown for a converted unit value; more would only show rounding
/// noise.
const int _resultDigits = 8;

/// The longest number the pad takes: a screen's width, and more than a double
/// can tell apart anyway.
const int _maxDigits = 15;

/// The number keyed on the converter's pad after pressing [key]: a digit, `.`,
/// `+/-` (flips the sign) or `DEL` (takes back the last character). A second
/// `.`, a digit past [_maxDigits] and a leading `00` are ignored.
String keyNumber(String current, String key) {
  switch (key) {
    case 'DEL':
      return current.isEmpty
          ? current
          : current.substring(0, current.length - 1);
    case '+/-':
      if (current.isEmpty) return '-';
      return current.startsWith('-') ? current.substring(1) : '-$current';
    case '.':
      if (current.contains('.')) return current;
      return current.isEmpty || current == '-' ? '${current}0.' : '$current.';
  }
  if (current.replaceAll('-', '').replaceAll('.', '').length >= _maxDigits) {
    return current;
  }
  // No leading zeros: 0 then 5 is 5.
  if (current == '0' || current == '-0') {
    return key == '0' ? current : '${current.replaceAll('0', '')}$key';
  }
  return current + key;
}

/// [text] as a number, or null when it is not one yet (empty, `-`, `.`).
double? _number(String text) => double.tryParse(text);

/// [text] converted between two units of one kind, as it is shown, or null
/// when [text] is not a number yet.
String? convertedUnits(String text, UnitDef from, UnitDef to) {
  final double? value = _number(text);
  if (value == null) return null;
  final double result = convertUnits(value, from, to);
  if (!result.isFinite) return null;
  return formatNumber(result, significant: _resultDigits);
}

/// [text] converted between two currencies, as it is shown (cents), or null
/// when [text] is not a number yet or a currency is not known.
String? convertedMoney(String text, Rates rates, String from, String to) {
  final double? value = _number(text);
  if (value == null || !rates.knows(from) || !rates.knows(to)) return null;
  final double result = rates.convert(value, from, to);
  if (!result.isFinite) return null;
  return formatAmount(result);
}

/// Cents for everyday amounts, significant digits for tiny ones.
String formatAmount(double value) {
  if (value.abs() >= 0.01 || value == 0) return value.toStringAsFixed(2);
  return formatNumber(value, significant: 3);
}

/// How a unit is labelled on the pad: its first name in capitals, with a degree
/// sign on Celsius and Fahrenheit.
String unitLabel(UnitDef unit) {
  final String symbol = unit.symbol.toUpperCase();
  if (unit.kind == UnitKind.temperature && symbol != 'K') return '°$symbol';
  return symbol;
}

/// The label of a kind of unit on the pad.
String kindLabel(UnitKind kind) => switch (kind) {
  UnitKind.temperature => 'TEMP',
  _ => kind.name.toUpperCase(),
};

/// The units to start from and to when a kind is chosen: the pair a person
/// most likely wants (kilometres to miles, Celsius to Fahrenheit).
({String from, String to}) defaultUnits(UnitKind kind) => switch (kind) {
  UnitKind.length => (from: 'km', to: 'mi'),
  UnitKind.mass => (from: 'kg', to: 'lb'),
  UnitKind.volume => (from: 'dl', to: 'cup'),
  UnitKind.time => (from: 'h', to: 'min'),
  UnitKind.speed => (from: 'km/h', to: 'mph'),
  UnitKind.temperature => (from: 'c', to: 'f'),
  UnitKind.area => (from: 'm2', to: 'ft2'),
  UnitKind.data => (from: 'mb', to: 'gb'),
};

/// The currencies to start from and to: kronor to euros.
const ({String from, String to}) defaultCurrencies = (from: 'SEK', to: 'EUR');

/// Currency codes in the order the pad lists them: the ones a Swede reaches for
/// first, then the rest alphabetically.
List<String> orderedCurrencies(List<String> codes) {
  const List<String> first = <String>['SEK', 'EUR', 'USD', 'GBP', 'NOK', 'DKK'];
  return <String>[
    for (final String code in first)
      if (codes.contains(code)) code,
    for (final String code in codes)
      if (!first.contains(code)) code,
  ];
}
