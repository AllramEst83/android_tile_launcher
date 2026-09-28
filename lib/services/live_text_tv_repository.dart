import 'package:android_tile_launcher/model/text_tv_page.dart';
import 'package:android_tile_launcher/services/network_exception.dart';
import 'package:android_tile_launcher/services/text_tv.dart';
import 'package:android_tile_launcher/services/text_tv_repository.dart';

DateTime _systemNow() => DateTime.now();

/// [TextTvRepository] on [TextTv], keeping the pages it has read for [maxAge]
/// (the news does not change by the second, and a reader flips back and forth
/// between the same few pages). Only a page that was read is kept; a failure
/// or an unbroadcast page is asked for again. At most [capacity] pages are
/// kept, the longest ago read going first.
class LiveTextTvRepository implements TextTvRepository {
  LiveTextTvRepository({
    required this.textTv,
    this.maxAge = const Duration(minutes: 5),
    this.capacity = 40,
    this.clock = _systemNow,
  });

  final TextTv textTv;
  final Duration maxAge;
  final int capacity;
  final DateTime Function() clock;

  // Insertion order is read order, so the first key is the oldest.
  final Map<int, (TextTvPage, DateTime)> _kept =
      <int, (TextTvPage, DateTime)>{};

  @override
  Future<TextTvResult> page(int number, {bool fresh = false}) async {
    final (TextTvPage, DateTime)? kept = _kept[number];
    if (!fresh && kept != null && clock().difference(kept.$2) < maxAge) {
      return TextTvShown(kept.$1);
    }
    try {
      final TextTvPage? page = await textTv.page(number);
      if (page == null) {
        _kept.remove(number);
        return TextTvNotBroadcast(number);
      }
      _kept.remove(number);
      _kept[number] = (page, clock());
      while (_kept.length > capacity) {
        _kept.remove(_kept.keys.first);
      }
      return TextTvShown(page);
    } on NetworkException catch (error) {
      return TextTvFailed(error.message);
    }
  }
}
