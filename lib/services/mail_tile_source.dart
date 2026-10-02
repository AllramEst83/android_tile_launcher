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
    // Starred messages older than the newest few ride along for the sheet;
    // the tile lists only the newest.
    final MailResult shown =
        result is MailMessages && result.messages.length > count
        ? MailMessages(
            result.messages.sublist(0, count),
            total: result.total,
            unread: result.unread,
            validity: result.validity,
          )
        : result;
    return MailContent(result: shown, now: clock());
  }
}
