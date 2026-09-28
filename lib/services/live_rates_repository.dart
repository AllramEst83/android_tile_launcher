import 'package:android_tile_launcher/model/rates.dart';
import 'package:android_tile_launcher/services/currency_rates.dart';
import 'package:android_tile_launcher/services/network_exception.dart';
import 'package:android_tile_launcher/services/rates_repository.dart';

/// [RatesRepository] on [CurrencyRates] (ECB rates from frankfurter.dev, kept
/// in the local store so conversions work offline).
class LiveRatesRepository implements RatesRepository {
  const LiveRatesRepository({required this.currencyRates});

  final CurrencyRates currencyRates;

  @override
  Future<RatesResult> rates() async {
    try {
      return RatesLoaded(await currencyRates.rates());
    } on NetworkException catch (error) {
      return RatesFailed(error.message);
    }
  }
}
