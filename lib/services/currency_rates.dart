import 'dart:convert';

import 'package:android_tile_launcher/model/rates.dart';
import 'package:android_tile_launcher/services/http_fetcher.dart';
import 'package:android_tile_launcher/services/local_store.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
import 'package:android_tile_launcher/services/network_exception.dart';

/// Currency rates from frankfurter.dev (ECB reference rates, no key needed),
/// kept in a [LocalStore] so conversions still work offline, with the date the
/// rates are from.
class CurrencyRates {
  CurrencyRates({
    required this._fetcher,
    required this._store,
    this._now = DateTime.now,
    this._maxAge = const Duration(hours: 6),
  });

  static const storeKey = 'currency.rates';

  final HttpFetcher _fetcher;
  final LocalStore _store;
  final DateTime Function() _now;

  /// The ECB publishes once a working day, so asking more often is pointless.
  final Duration _maxAge;

  /// Rates no older than the maximum age from the saved copy, else fresh from
  /// the network. If the network fails, the saved copy however old is returned
  /// marked [Rates.stale]; only with no saved copy does the failure propagate
  /// as a [NetworkException].
  Future<Rates> rates() async {
    final saved = await _saved();
    if (saved != null) {
      // A negative age means the clock was wrong when it was saved.
      final age = _now().difference(saved.fetchedAt);
      if (!age.isNegative && age < _maxAge) return saved;
    }
    try {
      final fresh = await _download();
      await _save(fresh);
      return fresh;
    } on NetworkException {
      if (saved != null) return saved.copyAsStale();
      rethrow;
    }
  }

  Future<Rates> _download() async {
    final body = await _fetcher.get(
      Uri.https('api.frankfurter.dev', '/v1/latest'),
    );
    try {
      final json = jsonDecode(body);
      if (json is! Map || json['base'] != 'EUR') {
        throw const FormatException('not euro-based rates');
      }
      final rates = json['rates'];
      if (rates is! Map) throw const FormatException('no rates');
      // The euro is the base, so the service leaves it out of its own list.
      return Rates.fromJson({
        'date': json['date'],
        'fetchedAt': _now().toUtc().toIso8601String(),
        'rates': {...rates, 'EUR': 1.0},
      });
    } on FormatException {
      throw const NetworkException(
        'frankfurter.dev sent an answer I could not read',
      );
    }
  }

  /// The saved copy, or null when there is none or it cannot be trusted. Rates
  /// are disposable, so unlike notes a damaged copy is simply replaced.
  Future<Rates?> _saved() async {
    try {
      final json = await _store.read(storeKey);
      return json == null ? null : Rates.fromJson(json);
    } on LocalStoreException {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// Best effort: failing to save must not fail a conversion that worked.
  Future<void> _save(Rates rates) async {
    try {
      await _store.write(storeKey, rates.toJson());
    } on LocalStoreException {
      // The rates are still returned; they just are not kept for offline use.
    }
  }
}
