import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/mail_service.dart';
import 'package:android_tile_launcher/services/tile_source.dart';

DateTime _systemNow() => DateTime.now();

/// The mail tile's content: the newest few messages and the unread count, or
/// why there are none to show. [count] is only how many the tile can list.
class MailTileSource implements TileSource {
  const MailTileSource({
    required this.service,
    this.count = 10,
    this.clock = _systemNow,
  });

  final MailService service;
  final int count;
  final DateTime Function() clock;

  @override
  Future<TileContent> read() async {
    final MailResult result = await service.latest(count: count);
    // Plain inbox order, starred or not: the tile asks for no starred listing.
    return MailContent(result: result, now: clock());
  }
}
