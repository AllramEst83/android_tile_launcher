import 'package:android_tile_launcher/model/rates.dart';

/// Exchange rates for the converter. Never throws: a failure is a
/// [RatesFailed] that says why.
abstract interface class RatesRepository {
  /// Recent rates (kept for hours, and for offline use), or why there are none.
  Future<RatesResult> rates();
}
