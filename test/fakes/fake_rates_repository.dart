import 'package:android_tile_launcher/model/rates.dart';
import 'package:android_tile_launcher/services/rates_repository.dart';

/// Answers with [result] and counts the requests.
class FakeRatesRepository implements RatesRepository {
  FakeRatesRepository([RatesResult? result]) : result = result ?? _default();

  RatesResult result;
  int calls = 0;

  /// SEK 11.29 and USD 1.1403 to the euro, as of 25 September 2026.
  static RatesResult _default() => RatesLoaded(
    Rates(
      perEuro: const <String, double>{
        'EUR': 1,
        'SEK': 11.29,
        'USD': 1.1403,
        'GBP': 0.86045,
        'NOK': 10.84,
        'JPY': 179.7,
      },
      date: DateTime(2026, 9, 25),
      fetchedAt: DateTime(2026, 9, 25, 12),
    ),
  );

  @override
  Future<RatesResult> rates() async {
    calls++;
    return result;
  }
}
