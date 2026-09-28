/// Exchange rates against the euro, as published by the European Central Bank.
class Rates {
  const Rates({
    required this._perEuro,
    required this.date,
    required this.fetchedAt,
    this.stale = false,
  });

  final Map<String, double> _perEuro;

  /// The day the ECB published these rates.
  final DateTime date;

  /// When this device downloaded them.
  final DateTime fetchedAt;

  /// True when they are a saved copy because the rates could not be fetched.
  final bool stale;

  /// Currency codes we have a rate for, sorted.
  List<String> get codes => _perEuro.keys.toList()..sort();

  /// [date] as `2026-09-25`.
  String get day => _day(date);

  bool knows(String code) => _perEuro.containsKey(code.toUpperCase());

  /// [amount] converted between two known currencies, via the euro. Codes are
  /// case-insensitive; an unknown one throws [ArgumentError].
  double convert(double amount, String from, String to) {
    final fromRate = _perEuro[from.toUpperCase()];
    final toRate = _perEuro[to.toUpperCase()];
    if (fromRate == null || toRate == null) {
      throw ArgumentError('unknown currency: ${fromRate == null ? from : to}');
    }
    return amount / fromRate * toRate;
  }

  Rates copyAsStale() =>
      Rates(perEuro: _perEuro, date: date, fetchedAt: fetchedAt, stale: true);

  Map<String, Object> toJson() => {
    'date': _day(date),
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
    'rates': _perEuro,
  };

  /// Throws [FormatException] for anything [toJson] would not have written.
  factory Rates.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('rates are not an object');
    final date = json['date'];
    final fetchedAt = json['fetchedAt'];
    final rates = json['rates'];
    if (date is! String || fetchedAt is! String || rates is! Map) {
      throw const FormatException('rates have missing fields');
    }
    final perEuro = <String, double>{};
    for (final entry in rates.entries) {
      final rate = entry.value;
      if (entry.key is! String || rate is! num || !(rate > 0)) {
        throw const FormatException('a rate is not a positive number');
      }
      perEuro[entry.key as String] = rate.toDouble();
    }
    if (perEuro.isEmpty) throw const FormatException('no rates');
    return Rates(
      perEuro: perEuro,
      date: DateTime.parse(date),
      fetchedAt: DateTime.parse(fetchedAt),
    );
  }

  static String _day(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// What the converter gets back when it asks for exchange rates: the rates, or
/// a short, printable reason there are none.
sealed class RatesResult {
  const RatesResult();
}

class RatesLoaded extends RatesResult {
  const RatesLoaded(this.rates);

  final Rates rates;
}

class RatesFailed extends RatesResult {
  const RatesFailed(this.reason);

  final String reason;
}
