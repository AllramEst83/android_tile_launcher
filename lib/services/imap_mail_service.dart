import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/model/mail_format.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
import 'package:android_tile_launcher/services/mail_account.dart';
import 'package:android_tile_launcher/services/mail_service.dart';
import 'package:enough_mail/enough_mail.dart'
    show
        ContentDisposition,
        ContentInfo,
        ImapClient,
        ImapException,
        MailAddress,
        MessageBuilder,
        MessageFlags,
        MessageSequence,
        MimeMessage,
        SearchQueryBuilder,
        SearchQueryType,
        SearchTermBefore,
        SearchTermBody,
        SearchTermFrom,
        SearchTermOr,
        SearchTermSince,
        SearchTermSubject,
        SearchTermTo,
        SmtpClient,
        SmtpException,
        SmtpResponse,
        StatusFlags,
        StoreAction;

/// [MailService] on `enough_mail`'s IMAP and SMTP clients. This is the only
/// file that knows about the package. Listing only reads (a message is
/// fetched by its envelope, so no body is downloaded). The changes it can
/// make are moving a message to Trash (never deleting anything outright) and
/// sending a new one.
class ImapMailService implements MailService {
  ImapMailService({
    required this._accounts,
    this.secure = true,
    this.timeout = const Duration(seconds: 20),
    this.smtpHost,
    this.smtpPort = 465,
    this.clock = DateTime.now,
  });

  final MailAccountStore _accounts;

  /// The largest message [read] will fetch, in bytes.
  static const int maxReadBytes = 8 * 1024 * 1024;

  /// TLS to the server. Only a test against a local server turns it off.
  final bool secure;

  /// For connecting and for each answer after that.
  final Duration timeout;

  /// Overrides [guessSmtpHost] (tests only, against a local fake server);
  /// normally null, so the account's own address is used to guess it.
  final String? smtpHost;

  /// TLS from the first byte (no `STARTTLS`), the same as [secure] does for
  /// IMAP; ports 465 and 993 both expect this.
  final int smtpPort;

  /// What "now" is, for turning [MailFilter.age] into a cutoff date.
  /// Injectable for tests; normally the real clock.
  final DateTime Function() clock;

  @override
  Future<MailAccountInfo?> account() async {
    try {
      final saved = await _accounts.load();
      if (saved == null) return null;
      return MailAccountInfo(email: saved.email, host: saved.host);
    } on LocalStoreException {
      return null;
    }
  }

  @override
  Future<String?> setUp({
    required String email,
    required String host,
    required String password,
  }) async {
    final target = splitHostPort(host);
    final account = MailAccount(
      email: email,
      host: target.host,
      port: target.port,
      password: password,
    );
    final outcome = await _session<Object?>(account, (client) async => null);
    switch (outcome) {
      case _Failed(:final reason):
        return reason;
      case _Done():
        break;
    }
    try {
      await _accounts.save(account);
    } on LocalStoreException catch (error) {
      return error.message;
    }
    return null;
  }

  @override
  Future<bool> forget() async {
    final had = await _accounts.exists();
    await _accounts.clear();
    return had;
  }

  @override
  Future<MailResult> latest({int count = 20, bool fresh = false}) async {
    final MailAccount? saved;
    try {
      saved = await _accounts.load();
    } on LocalStoreException catch (error) {
      return MailUnavailable(error.message);
    }
    if (saved == null) return const MailNotSetUp();

    final outcome = await _session<MailMessages>(saved, (client) async {
      final inbox = await client.selectInbox();
      final total = inbox.messagesExists;
      if (total == 0) {
        return const MailMessages([], total: 0, unread: 0);
      }
      final status = await client.statusMailbox(inbox, [StatusFlags.unseen]);
      // The newest `count` by position. (The library's own "recent" call asks
      // for one more than it is told.)
      final first = total > count ? total - count + 1 : 1;
      final fetched = await client.fetchMessages(
        MessageSequence.fromRange(first, total),
        '(UID FLAGS ENVELOPE)',
        responseTimeout: timeout,
      );
      final messages = [
        for (final message in fetched.messages) ?mailMessageFrom(message),
      ]..sort((a, b) => b.uid.compareTo(a.uid));
      return MailMessages(
        messages,
        total: total,
        unread: status.messagesUnseen,
        validity: inbox.uidValidity,
      );
    });
    return switch (outcome) {
      _Done(:final value) => value,
      _Failed(:final reason) => MailUnavailable(reason),
    };
  }

  @override
  Future<MailResult> search(MailFilter filter, {int count = 20}) async {
    final MailAccount? saved;
    try {
      saved = await _accounts.load();
    } on LocalStoreException catch (error) {
      return MailUnavailable(error.message);
    }
    if (saved == null) return const MailNotSetUp();

    final outcome = await _session<MailMessages>(saved, (client) async {
      final inbox = await client.selectInbox();
      final query = _queryFor(filter);
      final found = query == null
          ? await client.uidSearchMessages(
              searchCriteria: 'ALL',
              responseTimeout: timeout,
            )
          : await client.uidSearchMessagesWithQuery(
              query,
              responseTimeout: timeout,
            );
      final uids = found.matchingSequence?.toList() ?? <int>[];
      if (uids.isEmpty) {
        return const MailMessages([], total: 0, unread: 0);
      }
      final sequence = MessageSequence(isUidSequence: true);
      for (final uid in uids) {
        sequence.add(uid);
      }
      final fetched = await client.uidFetchMessages(
        sequence,
        '(UID FLAGS ENVELOPE)',
        responseTimeout: timeout,
      );
      final messages = [
        for (final message in fetched.messages) ?mailMessageFrom(message),
      ]..sort((a, b) => b.uid.compareTo(a.uid));
      // The newest [count], plus any older starred message: a star keeps it
      // in the list however far down the inbox it has sunk.
      final capped = messages.length > count
          ? <MailMessage>[
              ...messages.sublist(0, count),
              ...messages.sublist(count).where((m) => m.starred),
            ]
          : messages;
      return MailMessages(
        capped,
        total: messages.length,
        unread: messages.where((m) => m.unread).length,
        validity: inbox.uidValidity,
      );
    });
    return switch (outcome) {
      _Done(:final value) => value,
      _Failed(:final reason) => MailUnavailable(reason),
    };
  }

  @override
  Future<MailMoveResult> moveToTrash(int uid, {int? validity}) async {
    final MailAccount? saved;
    try {
      saved = await _accounts.load();
    } on LocalStoreException catch (error) {
      return MailMoveFailed(error.message);
    }
    if (saved == null) return const MailMoveNotSetUp();
    final host = saved.host;

    final outcome = await _session<MailMoveResult>(saved, (client) async {
      final inbox = await client.selectInbox();
      if (validity != null && inbox.uidValidity != validity) {
        return const MailMoveFailed(
          'the server renumbered the inbox; run mail again',
        );
      }
      final sequence = MessageSequence.fromId(uid, isUid: true);
      final present = await client.uidFetchMessages(sequence, '(UID)');
      if (present.messages.isEmpty) return const MailGone();

      final boxes = await client.listMailboxes(recursive: true);
      final trash = boxes.where((box) => box.isTrash).firstOrNull;
      if (trash == null) {
        // Never fall back to deleting: without a Trash there is nowhere safe.
        return MailMoveFailed('no Trash folder on $host; nothing was changed');
      }
      if (client.serverInfo.supportsMove) {
        await client.uidMove(sequence, targetMailbox: trash);
      } else if (client.serverInfo.supportsUidPlus) {
        // Copy first: if a later step fails the message is still in the inbox.
        // Only this uid is expunged, never others already marked deleted.
        await client.uidCopy(sequence, targetMailbox: trash);
        await client.uidStore(
          sequence,
          [MessageFlags.deleted],
          action: StoreAction.add,
          silent: true,
        );
        await client.uidExpunge(sequence);
      } else {
        return MailMoveFailed(
          "$host can't move a message safely; nothing was changed",
        );
      }
      return MailMoved(trash.name);
    });
    return switch (outcome) {
      _Done(:final value) => value,
      _Failed(:final reason) => MailMoveFailed(reason),
    };
  }

  @override
  Future<MailReadResult> read(int uid, {int? validity}) async {
    final MailAccount? saved;
    try {
      saved = await _accounts.load();
    } on LocalStoreException catch (error) {
      return MailReadFailed(error.message);
    }
    if (saved == null) return const MailReadNotSetUp();

    final outcome = await _session<MailReadResult>(saved, (client) async {
      final inbox = await client.selectInbox();
      if (validity != null && inbox.uidValidity != validity) {
        return const MailReadFailed(
          'the server renumbered the inbox; refresh the list',
        );
      }
      final sequence = MessageSequence.fromId(uid, isUid: true);

      // How big it is first, so a message with a huge attachment is not
      // pulled down just to be looked at.
      final sizes = await client.uidFetchMessages(
        sequence,
        '(UID FLAGS RFC822.SIZE)',
        responseTimeout: timeout,
      );
      final sized = sizes.messages.firstOrNull;
      if (sized == null) return const MailReadGone();
      final size = sized.size;
      if (size != null && size > maxReadBytes) {
        final mb = (size / (1024 * 1024)).toStringAsFixed(1);
        return MailReadFailed(
          'this message is $mb MB, too big to show here; open it in your mail app',
        );
      }

      // PEEK: reading it does not set \Seen by itself. That is done below, on
      // purpose, so a message that fails to open is left as it was.
      final fetched = await client.uidFetchMessages(
        sequence,
        '(UID FLAGS ENVELOPE BODY.PEEK[])',
        responseTimeout: timeout,
      );
      final message = fetched.messages.firstOrNull;
      final entry = message == null ? null : mailMessageFrom(message);
      if (message == null || entry == null) return const MailReadGone();

      var marked = true;
      try {
        await client.uidStore(
          sequence,
          [MessageFlags.seen],
          action: StoreAction.add,
          silent: true,
        );
      } on ImapException {
        marked = false;
      }
      return MailOpened(mailBodyFrom(message, entry, markedRead: marked));
    });
    return switch (outcome) {
      _Done(:final value) => value,
      _Failed(:final reason) => MailReadFailed(reason),
    };
  }

  @override
  Future<MailMarkResult> mark(
    int uid, {
    required bool read,
    int? validity,
  }) async {
    final MailAccount? saved;
    try {
      saved = await _accounts.load();
    } on LocalStoreException catch (error) {
      return MailMarkFailed(error.message);
    }
    if (saved == null) return const MailMarkNotSetUp();

    final outcome = await _session<MailMarkResult>(saved, (client) async {
      final inbox = await client.selectInbox();
      if (validity != null && inbox.uidValidity != validity) {
        return const MailMarkFailed(
          'the server renumbered the inbox; refresh the list',
        );
      }
      final sequence = MessageSequence.fromId(uid, isUid: true);
      final present = await client.uidFetchMessages(sequence, '(UID)');
      if (present.messages.isEmpty) return const MailMarkGone();
      await client.uidStore(
        sequence,
        [MessageFlags.seen],
        action: read ? StoreAction.add : StoreAction.remove,
        silent: true,
      );
      return MailMarked(read: read);
    });
    return switch (outcome) {
      _Done(:final value) => value,
      _Failed(:final reason) => MailMarkFailed(reason),
    };
  }

  @override
  Future<MailStarResult> star(
    int uid, {
    required bool starred,
    int? validity,
  }) async {
    final MailAccount? saved;
    try {
      saved = await _accounts.load();
    } on LocalStoreException catch (error) {
      return MailStarFailed(error.message);
    }
    if (saved == null) return const MailStarNotSetUp();

    final outcome = await _session<MailStarResult>(saved, (client) async {
      final inbox = await client.selectInbox();
      if (validity != null && inbox.uidValidity != validity) {
        return const MailStarFailed(
          'the server renumbered the inbox; refresh the list',
        );
      }
      final sequence = MessageSequence.fromId(uid, isUid: true);
      final present = await client.uidFetchMessages(sequence, '(UID)');
      if (present.messages.isEmpty) return const MailStarGone();
      await client.uidStore(
        sequence,
        [MessageFlags.flagged],
        action: starred ? StoreAction.add : StoreAction.remove,
        silent: true,
      );
      return MailStarred(starred: starred);
    });
    return switch (outcome) {
      _Done(:final value) => value,
      _Failed(:final reason) => MailStarFailed(reason),
    };
  }

  @override
  Future<MailSendResult> send({
    required List<String> to,
    List<String> cc = const <String>[],
    required String subject,
    required String text,
  }) async {
    final MailAccount? saved;
    try {
      saved = await _accounts.load();
    } on LocalStoreException catch (error) {
      return MailSendFailed(error.message);
    }
    if (saved == null) return const MailSendNotSetUp();

    final String host = smtpHost ?? guessSmtpHost(saved.email);
    if (host.isEmpty) {
      return const MailSendFailed(
        'could not work out the mail server to send through',
      );
    }
    final client = SmtpClient('android-tile-launcher.local');
    var loggedIn = false;
    try {
      await client.connectToServer(
        host,
        smtpPort,
        isSecure: secure,
        timeout: timeout,
      );
      await client.ehlo();
      try {
        final SmtpResponse authResponse = await client
            .authenticate(saved.email, saved.password)
            .timeout(timeout);
        if (!authResponse.isOkStatus) throw SmtpException.message(client, '');
      } on SmtpException {
        return MailSendFailed(
          '$host refused the login (check the address and the app password)',
        );
      }
      loggedIn = true;
      final MimeMessage message = MessageBuilder.buildSimpleTextMessage(
        MailAddress('', saved.email),
        <MailAddress>[
          for (final String address in to) MailAddress('', address),
        ],
        text,
        cc: <MailAddress>[
          for (final String address in cc) MailAddress('', address),
        ],
        subject: subject,
      );
      final SmtpResponse sendResponse = await client
          .sendMessage(message)
          .timeout(timeout);
      if (!sendResponse.isOkStatus) {
        return MailSendFailed('$host refused the message');
      }
      return const MailSent();
    } on SocketException {
      return MailSendFailed("can't reach $host (no connection?)");
    } on HandshakeException {
      return MailSendFailed('could not make a secure connection to $host');
    } on TimeoutException {
      return MailSendFailed('$host did not answer in time');
    } on SmtpException catch (error) {
      return MailSendFailed('$host: ${_scrub(error.message, saved.password)}');
    } on Object catch (error) {
      return MailSendFailed(
        '$host: ${_scrub(error.toString(), saved.password)}',
      );
    } finally {
      try {
        if (loggedIn) await client.quit().timeout(const Duration(seconds: 3));
      } on Object {
        // Leaving is best effort; the socket is closed below either way.
      }
      try {
        await client.disconnect();
      } on Object {
        // Nothing left to clean up.
      }
    }
  }

  /// Connects, logs in, runs [body] and always hangs up. Every way it can go
  /// wrong is a [_Failed] with a sentence for the user; none contains the
  /// password.
  Future<_Outcome<T>> _session<T>(
    MailAccount account,
    Future<T> Function(ImapClient client) body,
  ) async {
    final client = ImapClient(defaultResponseTimeout: timeout);
    var loggedIn = false;
    try {
      await client.connectToServer(
        account.host,
        account.port,
        isSecure: secure,
        timeout: timeout,
      );
      try {
        await client.login(account.email, account.password);
      } on ImapException {
        return _Failed(
          '${account.host} refused the login '
          '(check the address and the app password)',
        );
      }
      loggedIn = true;
      return _Done(await body(client));
    } on SocketException {
      return _Failed("can't reach ${account.host} (no connection?)");
    } on HandshakeException {
      return _Failed('could not make a secure connection to ${account.host}');
    } on TimeoutException {
      return _Failed('${account.host} did not answer in time');
    } on ImapException catch (error) {
      return _Failed(
        '${account.host}: ${_scrub(error.message, account.password)}',
      );
    } on Object catch (error) {
      return _Failed(
        '${account.host}: ${_scrub(error.toString(), account.password)}',
      );
    } finally {
      await _hangUp(client, loggedIn: loggedIn);
    }
  }

  /// [filter] as an IMAP search query, or null when [filter] is empty (a
  /// plain, unfiltered search). Free text searches the subject or the body
  /// (whichever matches); every other set field narrows the results further.
  SearchQueryBuilder? _queryFor(MailFilter filter) {
    if (filter.isEmpty) return null;
    final SearchQueryBuilder query = SearchQueryBuilder.from(
      '',
      SearchQueryType.subject,
    );
    if (filter.text.isNotEmpty) {
      query.add(
        SearchTermOr(
          SearchTermSubject(filter.text),
          SearchTermBody(filter.text),
        ),
      );
    }
    if (filter.from.isNotEmpty) query.add(SearchTermFrom(filter.from));
    if (filter.to.isNotEmpty) query.add(SearchTermTo(filter.to));
    final MailAgeFilter? age = filter.age;
    if (age != null) {
      query.add(
        age.direction == MailAgeDirection.older
            ? SearchTermBefore(age.cutoff(clock()))
            : SearchTermSince(age.cutoff(clock())),
      );
    }
    return query;
  }

  Future<void> _hangUp(ImapClient client, {required bool loggedIn}) async {
    try {
      if (loggedIn && client.isConnected) {
        await client.logout().timeout(const Duration(seconds: 3));
      }
    } on Object {
      // Leaving is best effort; the socket is closed below either way.
    }
    try {
      await client.disconnect();
    } on Object {
      // Nothing left to clean up.
    }
  }
}

/// The first line of [text] with the [secret] blanked, so an error from the
/// server or the library can never put the password on the screen.
String _scrub(String? text, String secret) {
  final line = (text ?? 'something went wrong').split('\n').first.trim();
  return secret.isEmpty ? line : line.replaceAll(secret, '***');
}

/// [addresses] as [MailParticipant]s, an address with no address itself
/// (which happens) left out. Kept apart from the network so it can be tested
/// on its own.
List<MailParticipant> _participantsFrom(List<MailAddress>? addresses) => [
  for (final MailAddress a in addresses ?? const <MailAddress>[])
    if (a.email.trim().isNotEmpty)
      MailParticipant(
        address: a.email.trim(),
        name: a.personalName?.trim() ?? '',
      ),
];

sealed class _Outcome<T> {
  const _Outcome();
}

class _Done<T> extends _Outcome<T> {
  const _Done(this.value);

  final T value;
}

class _Failed<T> extends _Outcome<T> {
  const _Failed(this.reason);

  final String reason;
}

/// [text] as a host and port: `imap.example.com` is port 993, and
/// `imap.example.com:143` names its own. A colon followed by anything but a
/// number is left in the host.
({String host, int port}) splitHostPort(String text) {
  final colon = text.lastIndexOf(':');
  final port = colon < 0 ? null : int.tryParse(text.substring(colon + 1));
  if (port == null) return (host: text, port: 993);
  return (host: text.substring(0, colon), port: port);
}

/// [message] as a list entry, or null if the server gave no UID for it (then
/// it could never be told apart later). Kept apart from the network so it can
/// be tested on its own.
MailMessage? mailMessageFrom(MimeMessage message) {
  final uid = message.uid;
  if (uid == null) return null;
  final sender = message.from?.firstOrNull;
  final name = sender?.personalName?.trim() ?? '';
  final address = sender?.email.trim() ?? '';
  final subject = message.envelope?.subject ?? message.decodeSubject() ?? '';
  final sent = message.envelope?.date ?? message.decodeDate();
  return MailMessage(
    uid: uid,
    from: name.isNotEmpty ? name : (address.isNotEmpty ? address : '?'),
    subject: subject.trim(),
    date: sent?.toLocal(),
    unread: !message.isSeen,
    starred: message.isFlagged,
  );
}

/// [message] (fetched whole) as what the reader shows, given its list [entry]
/// for who, when and what. The plain text part if there is one and actually
/// reads as prose, else the message's HTML (for a rich view) with its own
/// text kept too, for quoting and as the fallback; tidied and cut at
/// [mailTextLimit]. Kept apart from the network so it can be tested on its own.
MailBody mailBodyFrom(
  MimeMessage message,
  MailMessage entry, {
  bool markedRead = true,
}) {
  String raw = '';
  String? html;
  String? htmlWithImages;
  try {
    final String? plainPart = message.decodeTextPlainPart();
    final String? htmlPart = message.decodeTextHtmlPart();
    // The unstripped markup SHOW IMAGES is built from, whichever part it
    // came from below.
    String? richSource;
    if (htmlPart != null && htmlPart.trim().isNotEmpty) {
      richSource = htmlPart;
      html = stripImagesFromHtml(htmlPart).trim();
    }
    if (plainPart != null &&
        plainPart.trim().isNotEmpty &&
        !looksLikeHtml(plainPart)) {
      raw = plainPart;
    } else if (htmlPart != null && htmlPart.trim().isNotEmpty) {
      raw = plainTextFromHtml(htmlPart);
    } else if (plainPart != null && plainPart.trim().isNotEmpty) {
      // The "plain" part is itself markup (a sloppy sender): show it rich too.
      richSource = plainPart;
      html = stripImagesFromHtml(plainPart).trim();
      raw = plainTextFromHtml(plainPart);
    }
    if (richSource != null &&
        RegExp(r'<img\b', caseSensitive: false).hasMatch(richSource)) {
      htmlWithImages = resolveCidImages(
        richSource,
        _inlineImageDataUris(message),
      ).trim();
    }
  } on Object {
    raw = '';
    html = null;
    htmlWithImages = null;
  }
  final tidy = tidyMailText(raw);
  return MailBody(
    uid: entry.uid,
    from: entry.from,
    fromAddress: message.from?.firstOrNull?.email.trim() ?? '',
    to: _participantsFrom(message.to),
    cc: _participantsFrom(message.cc),
    subject: entry.subject,
    date: entry.date,
    text: tidy.text,
    html: html,
    htmlWithImages: htmlWithImages,
    truncated: tidy.truncated,
    attachments: _attachmentsFrom(message),
    markedRead: markedRead,
  );
}

/// A `cid` (lower-cased, angle brackets stripped) to a `data:` URI, for every
/// inline part of [message] that has one and decodes to real bytes. Never
/// throws: a part that fails to decode is left out, not fatal to the rest.
Map<String, String> _inlineImageDataUris(MimeMessage message) {
  final Map<String, String> result = <String, String>{};
  try {
    for (final ContentInfo info in message.findContentInfo(
      disposition: ContentDisposition.inline,
    )) {
      final String id = (info.cid ?? '').replaceAll(RegExp('[<>]'), '');
      if (id.isEmpty) continue;
      try {
        final Uint8List? bytes = message
            .getPart(info.fetchId)
            ?.decodeContentBinary();
        if (bytes == null || bytes.isEmpty) continue;
        final String mimeType =
            info.mediaType?.text ?? 'application/octet-stream';
        result[id] = 'data:$mimeType;base64,${base64Encode(bytes)}';
      } on Object {
        continue;
      }
    }
  } on Object {
    // Nothing usable; the html shown just has no images left to reveal.
  }
  return result;
}

/// [message]'s attachments, whole, in the order the server gave them. Never
/// throws: an attachment that fails to decode is left out, not fatal to the
/// rest of the message.
List<MailAttachment> _attachmentsFrom(MimeMessage message) {
  final List<MailAttachment> result = <MailAttachment>[];
  try {
    final List<ContentInfo> infos = message.findContentInfo(
      disposition: ContentDisposition.attachment,
    );
    for (var i = 0; i < infos.length; i++) {
      try {
        final ContentInfo info = infos[i];
        final Uint8List? bytes = message
            .getPart(info.fetchId)
            ?.decodeContentBinary();
        if (bytes == null) continue;
        final String? fileName = info.fileName?.trim();
        result.add(
          MailAttachment(
            name: fileName != null && fileName.isNotEmpty
                ? fileName
                : 'attachment-${i + 1}',
            sizeBytes: bytes.length,
            mimeType: info.mediaType?.text ?? 'application/octet-stream',
            bytes: bytes,
          ),
        );
      } on Object {
        continue;
      }
    }
  } on Object {
    // No attachments usable; an empty list is a perfectly good answer.
  }
  return result;
}
