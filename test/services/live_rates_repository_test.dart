import 'dart:io';

import 'package:android_tile_launcher/model/rates.dart';
import 'package:android_tile_launcher/services/currency_rates.dart';
import 'package:android_tile_launcher/services/live_rates_repository.dart';
import 'package:android_tile_launcher/services/network_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_http_fetcher.dart';
import '../fakes/in_memory_local_store.dart';

void main() {
  late FakeHttpFetcher fetcher;
  late LiveRatesRepository repository;
  setUp(() {
    fetcher = FakeHttpFetcher();
    repository = LiveRatesRepository(
      currencyRates: CurrencyRates(
        fetcher: fetcher,
        store: InMemoryLocalStore(),
      ),
    );
  });

  test('rates from the service', () async {
    fetcher.route(
      'frankfurter.dev',
      File('test/fixtures/frankfurter_latest.json').readAsStringSync(),
    );

    final RatesResult result = await repository.rates();

    expect(result, isA<RatesLoaded>());
    expect((result as RatesLoaded).rates.knows('SEK'), isTrue);
    expect(result.rates.day, '2026-09-25');
  });

  test('a failure says why, and never throws', () async {
    fetcher.route(
      'frankfurter.dev',
      const NetworkException(
        "can't reach api.frankfurter.dev (no connection?)",
      ),
    );

    final RatesResult result = await repository.rates();

    expect(result, isA<RatesFailed>());
    expect((result as RatesFailed).reason, contains('no connection'));
  });
}
