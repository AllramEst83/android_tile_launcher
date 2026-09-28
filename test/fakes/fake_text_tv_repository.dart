import 'package:android_tile_launcher/model/text_tv_page.dart';
import 'package:android_tile_launcher/services/text_tv_repository.dart';

/// Serves pages from [pages] (anything else is [TextTvNotBroadcast]), or
/// [failure] for every request while it is set, and records what was asked.
class FakeTextTvRepository implements TextTvRepository {
  FakeTextTvRepository([Map<int, TextTvPage>? pages])
    : pages = pages ?? <int, TextTvPage>{};

  final Map<int, TextTvPage> pages;
  TextTvResult? failure;

  /// Every `(number, fresh)` asked for, in order.
  final List<(int, bool)> requests = <(int, bool)>[];

  @override
  Future<TextTvResult> page(int number, {bool fresh = false}) async {
    requests.add((number, fresh));
    final TextTvResult? failed = failure;
    if (failed != null) return failed;
    final TextTvPage? page = pages[number];
    return page == null ? TextTvNotBroadcast(number) : TextTvShown(page);
  }
}
