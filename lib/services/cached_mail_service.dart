import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/services/mail_service.dart';

DateTime _systemNow() => DateTime.now();

/// A [MailService] that reuses a recent inbox listing for [maxAge], so the
/// tile's poll and every return to the launcher cost no login (servers throttle
/// those, and each one takes a second or two). Only a good listing is kept; a
/// failure is asked for again next time. Anything that changes the account or
/// the inbox drops it.
class CachedMailService implements MailService {
  CachedMailService({
    required this.inner,
    this.maxAge = const Duration(minutes: 3),
    this.clock = _systemNow,
  });

  final MailService inner;
  final Duration maxAge;
  final DateTime Function() clock;

  MailMessages? _kept;
  int _keptCount = 0;
  DateTime? _keptAt;

  void _drop() {
    _kept = null;
    _keptAt = null;
  }

  @override
  Future<MailAccountInfo?> account() => inner.account();

  @override
  Future<String?> setUp({
    required String email,
    required String host,
    required String password,
  }) async {
    _drop();
    return inner.setUp(email: email, host: host, password: password);
  }

  @override
  Future<bool> forget() async {
    _drop();
    return inner.forget();
  }

  @override
  Future<MailResult> latest({int count = 20, bool fresh = false}) async {
    final MailMessages? kept = _kept;
    final DateTime? at = _keptAt;
    if (!fresh &&
        kept != null &&
        at != null &&
        // Asking for more than was kept needs the server, unless the whole
        // inbox was already there.
        (count <= _keptCount || kept.messages.length >= kept.total) &&
        clock().difference(at) < maxAge) {
      return kept;
    }
    final MailResult result = await inner.latest(count: count, fresh: true);
    if (result is MailMessages) {
      _kept = result;
      _keptCount = count;
      _keptAt = clock();
    } else {
      _drop();
    }
    return result;
  }

  @override
  Future<MailMoveResult> moveToTrash(int uid, {int? validity}) async {
    // The inbox has changed, or is about to be.
    _drop();
    return inner.moveToTrash(uid, validity: validity);
  }

  @override
  Future<MailReadResult> read(int uid, {int? validity}) async {
    // Opening a message changes its unread state, so the counts are stale.
    _drop();
    return inner.read(uid, validity: validity);
  }

  @override
  Future<MailMarkResult> mark(
    int uid, {
    required bool read,
    int? validity,
  }) async {
    _drop();
    return inner.mark(uid, read: read, validity: validity);
  }

  @override
  Future<MailSendResult> send({
    required List<String> to,
    List<String> cc = const <String>[],
    required String subject,
    required String text,
  }) =>
      // Sending changes nothing about the inbox listing kept above.
      inner.send(to: to, cc: cc, subject: subject, text: text);
}
