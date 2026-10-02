import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/model/mail_cache.dart';
import 'package:android_tile_launcher/services/local_store.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
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
    this.store,
  });

  final MailService inner;
  final Duration maxAge;
  final DateTime Function() clock;

  /// Where the inbox listing is kept between runs (headers only); null keeps
  /// nothing.
  final LocalStore? store;

  static const String storeKey = 'mail_listing';

  MailMessages? _kept;
  int _keptCount = 0;
  DateTime? _keptAt;

  /// Forgets the saved listing too: it belongs to an account that is changing
  /// or going.
  Future<void> _forgetSaved() async {
    try {
      await store?.delete(storeKey);
    } on LocalStoreException {
      // A listing that cannot be removed is only ever a head start.
    }
  }

  Future<void> _save(MailMessages listing) async {
    final LocalStore? target = store;
    if (target == null) return;
    try {
      final MailAccountInfo? account = await inner.account();
      if (account == null) return;
      await target.write(
        storeKey,
        mailListingToJson(listing, account: account.email),
      );
    } on LocalStoreException {
      // See above.
    }
  }

  @override
  Future<MailMessages?> cachedInbox() async {
    final LocalStore? source = store;
    if (source == null) return null;
    try {
      final MailAccountInfo? account = await inner.account();
      if (account == null) return null;
      return mailListingFromJson(
        await source.read(storeKey),
        account: account.email,
      );
    } on LocalStoreException {
      return null;
    }
  }

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
    await _forgetSaved();
    return inner.setUp(email: email, host: host, password: password);
  }

  @override
  Future<bool> forget() async {
    _drop();
    await _forgetSaved();
    return inner.forget();
  }

  @override
  Future<MailResult> latest({
    int count = 20,
    bool fresh = false,
    int offset = 0,
    String? folder,
    bool withStarred = false,
  }) async {
    // Only the plain first page of the inbox is kept: it is what the tile
    // polls. The sheet's other pages, folders and starred listing are always
    // asked for.
    if (folder != null || offset != 0 || withStarred) {
      final MailResult result = await inner.latest(
        count: count,
        fresh: true,
        offset: offset,
        folder: folder,
        withStarred: withStarred,
      );
      // The sheet's own first page of the inbox is what it shows first next
      // time.
      if (folder == null &&
          offset == 0 &&
          withStarred &&
          result is MailMessages) {
        await _save(result);
      }
      return result;
    }
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
  Future<List<MailFolder>> folders() => inner.folders();

  @override
  Future<MailResult> search(
    MailFilter filter, {
    int count = 20,
    int offset = 0,
    String? folder,
  }) =>
      // A filtered search always asks the server fresh; caching it would need
      // one cache slot per filter for a feature used far less than a plain
      // read of the inbox.
      inner.search(filter, count: count, offset: offset, folder: folder);

  @override
  Future<MailMoveResult> moveToTrash(
    int uid, {
    int? validity,
    String? folder,
  }) async {
    // The inbox has changed, or is about to be.
    _drop();
    return inner.moveToTrash(uid, validity: validity, folder: folder);
  }

  @override
  Future<MailReadResult> read(int uid, {int? validity, String? folder}) async {
    // Opening a message changes its unread state, so the counts are stale.
    _drop();
    return inner.read(uid, validity: validity, folder: folder);
  }

  @override
  Future<MailMarkResult> mark(
    int uid, {
    required bool read,
    int? validity,
    String? folder,
  }) async {
    _drop();
    return inner.mark(uid, read: read, validity: validity, folder: folder);
  }

  @override
  Future<MailStarResult> star(
    int uid, {
    required bool starred,
    int? validity,
    String? folder,
  }) async {
    _drop();
    return inner.star(
      uid,
      starred: starred,
      validity: validity,
      folder: folder,
    );
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
