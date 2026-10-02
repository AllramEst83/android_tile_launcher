import 'package:android_tile_launcher/model/mail.dart';

/// The user's inbox, read over IMAP with an app password kept on the device.
abstract interface class MailService {
  /// The account that is set up, or null.
  Future<MailAccountInfo?> account();

  /// Logs in with [password] and, only if that works, remembers all three so
  /// later calls need no typing. Returns null on success, else why it failed
  /// (nothing is saved then). Never throws.
  Future<String?> setUp({
    required String email,
    required String host,
    required String password,
  });

  /// Forgets the account and its password, and says whether there was
  /// anything to forget (a damaged saved account counts).
  Future<bool> forget();

  /// The [count] newest messages in the inbox. Never throws. A recent answer
  /// may be reused (the tile polls, and coming back to the launcher must not
  /// log in to the server every time); [fresh] insists on asking the server.
  ///
  /// [offset] skips that many of the newest, for the next page after a
  /// result's `nextOffset`. [folder] is a server path from [folders]; null is
  /// the inbox. With [withStarred] (inbox, first page) the result also lists
  /// every starred message on the account in `starred`, and leaves them out
  /// of `messages`.
  Future<MailResult> latest({
    int count = 20,
    bool fresh = false,
    int offset = 0,
    String? folder,
    bool withStarred = false,
  });

  /// The account's folders worth showing, in the order to show them. Empty if
  /// there is no account or the server could not be asked. Never throws.
  Future<List<MailFolder>> folders();

  /// The [count] newest messages matching [filter], always fresh from the
  /// server. Never throws; an empty [filter] behaves like [latest].
  Future<MailResult> search(
    MailFilter filter, {
    int count = 20,
    int offset = 0,
    String? folder,
  });

  /// For every call that takes a [folder] (null is the inbox), [uid] is the
  /// server's id in that folder.
  ///
  /// Moves the inbox message with [uid] to the server's Trash folder: never
  /// deletes it outright, so it can be got back. If [validity] is given and
  /// the server's differs, the ids have been renumbered since the list was
  /// read, so nothing is touched. Never throws, and changes nothing unless it
  /// returns [MailMoved].
  Future<MailMoveResult> moveToTrash(int uid, {int? validity, String? folder});

  /// Opens the inbox message with [uid] in full and marks it read on the
  /// server (the way opening a mail does anywhere), fetching it without
  /// touching its flags first so a failure to open never changes it. A message
  /// over a size limit is not fetched, and a message with no readable text is
  /// still opened. If [validity] is given and the server's differs, the ids have
  /// been renumbered and nothing is touched. Never throws.
  Future<MailReadResult> read(int uid, {int? validity, String? folder});

  /// Marks the inbox message with [uid] read (or, with `read: false`, unread)
  /// on the server. Same [validity] rule as [read]. Never throws, and changes
  /// nothing unless it returns [MailMarked].
  Future<MailMarkResult> mark(
    int uid, {
    required bool read,
    int? validity,
    String? folder,
  });

  /// Stars (sets `\Flagged` on) the inbox message with [uid], or with
  /// `starred: false` unstars it. Same [validity] rule as [read]. Never
  /// throws, and changes nothing unless it returns [MailStarred].
  Future<MailStarResult> star(
    int uid, {
    required bool starred,
    int? validity,
    String? folder,
  });

  /// Sends a new message from the set-up account to every address in [to],
  /// copying every address in [cc]. Never throws; nothing is sent unless it
  /// returns [MailSent].
  Future<MailSendResult> send({
    required List<String> to,
    List<String> cc = const <String>[],
    required String subject,
    required String text,
  });
}
