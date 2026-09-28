import 'package:android_tile_launcher/model/text_tv_page.dart';

/// Text TV pages for the tile and the full-screen viewer. Never throws: every
/// failure is a [TextTvResult] that says why.
abstract interface class TextTvRepository {
  /// Page [number] (100 to 899). A page read a few minutes ago may be reused
  /// (going back to a page just left must not fetch it again); [fresh]
  /// insists on asking the site.
  Future<TextTvResult> page(int number, {bool fresh = false});
}
