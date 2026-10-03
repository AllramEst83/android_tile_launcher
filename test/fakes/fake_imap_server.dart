import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A message the [FakeImapServer] holds. [subject] is written as it would be on
/// the wire (so a test can use an encoded word); [name] null means the sender
/// has no display name.
class FakeImapMessage {
  const FakeImapMessage({
    required this.uid,
    required this.subject,
    required this.date,
    required this.address,
    this.name,
    this.seen = false,
    this.text,
    this.html,
    this.raw,
    this.size,
  });

  final int uid;
  final String subject;
  final String date;
  final String address;
  final String? name;
  final bool seen;

  /// The plain text and/or HTML body of the message when it is fetched whole.
  /// Both make a `multipart/alternative`; neither makes an empty text message.
  final String? text;
  final String? html;

  /// The whole message exactly as it goes on the wire, instead of one built
  /// from the fields above (for attachments and other odd shapes).
  final String? raw;

  /// What `RFC822.SIZE` says, instead of the real length of the message.
  final int? size;

  /// The message as sent: headers, a blank line and the body.
  String rfc822() {
    final custom = raw;
    if (custom != null) return custom;
    final subjectText = subject.length >= 2 && subject.startsWith('"')
        ? subject.substring(1, subject.length - 1)
        : (subject == 'NIL' ? '' : subject);
    final from = name == null ? address : '$name <$address>';
    final head =
        'From: $from\r\n'
        'To: kay@example.com\r\n'
        'Subject: $subjectText\r\n'
        'Date: $date\r\n'
        'Message-ID: <$uid@example.com>\r\n'
        'MIME-Version: 1.0\r\n';
    final plain = text;
    final markup = html;
    if (plain != null && markup != null) {
      return '${head}Content-Type: multipart/alternative; boundary="b1"\r\n\r\n'
          '--b1\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n$plain\r\n'
          '--b1\r\nContent-Type: text/html; charset=utf-8\r\n\r\n$markup\r\n'
          '--b1--\r\n';
    }
    if (markup != null) {
      return '${head}Content-Type: text/html; charset=utf-8\r\n\r\n$markup\r\n';
    }
    return '${head}Content-Type: text/plain; charset=utf-8\r\n\r\n${plain ?? ''}\r\n';
  }
}

/// A small IMAP server on a local port, just enough for `ImapMailService` to
/// log in, open the inbox, fetch envelopes and move a message to Trash. It
/// answers like a real one (untagged data, then a tagged status) so the real
/// client library is what the test exercises, and it records every command it
/// was sent.
class FakeImapServer {
  FakeImapServer({
    required this.user,
    required this.password,
    List<FakeImapMessage> messages = const [],
  }) : inbox = List.of(messages) {
    for (final message in messages) {
      if (message.seen) seen.add(message.uid);
    }
  }

  final String user;
  final String password;

  /// The inbox as it is now: a move takes a message out of it.
  final List<FakeImapMessage> inbox;

  /// What has been moved to the Trash folder, in order.
  final List<FakeImapMessage> trash = [];

  /// Every command line received, tag removed, with the password blanked.
  final List<String> received = [];

  /// How many clients have connected.
  int connections = 0;

  /// Set to make the next SELECT fail with a server error.
  bool failSelect = false;

  /// What the server says it can do. Real ones differ: Gmail has `MOVE`, an
  /// older server may only have `UIDPLUS`.
  String capabilities = 'IMAP4rev1 MOVE UIDPLUS IDLE';

  /// Folders besides INBOX and Trash, as `LIST` reports them (the server's own
  /// spelling of the name); `CREATE`, `RENAME` and `DELETE` change it.
  final List<String> extraFolders = [];

  /// Whether a folder flagged `\All` (Gmail's All Mail) exists.
  bool hasAllMail = false;

  /// What a Gmail `X-GM-RAW` search for starred / unread inbox mail replies
  /// (`searchResults` answers the plain `in:inbox` one); null falls back to
  /// `searchResults`.
  Set<int>? starredResults;
  Set<int>? unreadResults;

  /// The socket and tag of an `IDLE` in progress, if any.
  Socket? _idleSocket;
  String? _idleTag;

  /// Tells a client that is idling that a message arrived.
  void pushNewMessage() {
    _idleSocket?.write('* ${inbox.length + 1} EXISTS\r\n');
  }

  /// Whether a client is idling now.
  bool get idling => _idleTag != null;

  /// Set to make the server refuse `X-GM-RAW` searches.
  bool rejectGmailRaw = false;

  /// Whether a folder flagged `\Trash` exists.
  bool hasTrash = true;

  /// The name of the Trash folder, as `LIST` reports it.
  String trashName = '[Gmail]/Trash';

  /// The inbox's `UIDVALIDITY`.
  int uidValidity = 1;

  /// The uids that carry `\Seen` now: it starts from the messages given, and a
  /// `STORE` changes it.
  final Set<int> seen = {};

  /// The uids that carry `\Flagged` (starred).
  final Set<int> flagged = {};

  /// Set to make the next `STORE` of `\Seen` fail with a server error.
  bool failStoreSeen = false;

  /// Uids marked `\Deleted` by a `STORE`, until an `EXPUNGE` removes them.
  final Set<int> _deleted = {};

  /// What `UID SEARCH` replies with, regardless of the criteria given.
  Set<int> searchResults = {};

  late final ServerSocket _server;
  final List<Socket> _sockets = [];

  int get port => _server.port;

  Future<void> start() async {
    _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_serve);
  }

  Future<void> stop() async {
    for (final socket in _sockets) {
      socket.destroy();
    }
    await _server.close();
  }

  void _serve(Socket socket) {
    connections++;
    _sockets.add(socket);
    socket.write('* OK IMAP4rev1 ready\r\n');
    socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => _handle(socket, line));
  }

  void _handle(Socket socket, String line) {
    if (line == 'DONE' && _idleTag != null) {
      received.add('DONE');
      socket.write('$_idleTag OK IDLE terminated\r\n');
      _idleTag = null;
      _idleSocket = null;
      return;
    }
    final space = line.indexOf(' ');
    if (space < 0) return;
    final tag = line.substring(0, space);
    final rest = line.substring(space + 1);
    final words = rest.split(' ');
    final word = words.first.toUpperCase();
    received.add(word == 'LOGIN' ? 'LOGIN' : rest);

    switch (word) {
      case 'CAPABILITY':
        socket.write('* CAPABILITY $capabilities\r\n$tag OK done\r\n');
      case 'LOGIN':
        final ok = rest.contains('"$user"') && rest.contains('"$password"');
        socket.write(
          ok
              ? '$tag OK [CAPABILITY $capabilities] logged in\r\n'
              : '$tag NO [AUTHENTICATIONFAILED] Invalid credentials\r\n',
        );
      case 'LIST':
        socket.write(
          '* LIST (\\HasNoChildren) "/" "INBOX"\r\n'
          '${hasTrash ? '* LIST (\\HasNoChildren \\Trash) "/" "$trashName"\r\n' : ''}'
          '${hasAllMail ? '* LIST (\\HasNoChildren \\All) "/" "[Gmail]/All Mail"\r\n' : ''}'
          '${extraFolders.map((f) => '* LIST (\\HasNoChildren) "/" "$f"\r\n').join()}'
          '$tag OK LIST completed\r\n',
        );
      case 'IDLE':
        _idleTag = tag;
        _idleSocket = socket;
        socket.write('+ idling\r\n');
      case 'CREATE':
        extraFolders.add(_quoted(rest).first);
        socket.write('$tag OK CREATE completed\r\n');
      case 'RENAME':
        final names = _quoted(rest);
        final at = extraFolders.indexOf(names.first);
        if (at >= 0) extraFolders[at] = names.last;
        socket.write('$tag OK RENAME completed\r\n');
      case 'DELETE':
        extraFolders.remove(_quoted(rest).first);
        socket.write('$tag OK DELETE completed\r\n');
      case 'SELECT':
        if (failSelect) {
          socket.write('$tag NO [SERVERBUG] inbox is on fire\r\n');
          return;
        }
        socket.write(
          '* ${inbox.length} EXISTS\r\n'
          '* 0 RECENT\r\n'
          '* OK [UIDVALIDITY $uidValidity] ok\r\n'
          '* FLAGS (\\Seen \\Answered \\Deleted)\r\n'
          '$tag OK [READ-WRITE] SELECT completed\r\n',
        );
      case 'STATUS':
        final unseen = inbox.where((m) => !seen.contains(m.uid)).length;
        socket.write(
          '* STATUS "INBOX" (UNSEEN $unseen)\r\n$tag OK STATUS completed\r\n',
        );
      case 'FETCH':
        final range = words[1].split(':');
        final from = int.parse(range.first);
        final to = range.last == '*' ? inbox.length : int.parse(range.last);
        final out = StringBuffer();
        for (var seq = from; seq <= to && seq <= inbox.length; seq++) {
          out.write(_fetchLine(seq, inbox[seq - 1]));
        }
        socket.write('$out$tag OK FETCH completed\r\n');
      case 'UID':
        _handleUid(socket, tag, words);
      case 'LOGOUT':
        socket.write('* BYE bye\r\n$tag OK LOGOUT completed\r\n');
        unawaited(socket.close());
      default:
        socket.write('$tag BAD unknown command\r\n');
    }
  }

  /// The arguments of a command line, quotes removed (the client quotes a
  /// name only when it has to).
  List<String> _quoted(String line) => [
    for (final m in RegExp(r'"([^"]*)"|(\S+)').allMatches(line).skip(1))
      m.group(1) ?? m.group(2)!,
  ];

  /// A sequence set (`101`, `101,102` or `101:103`) as the uids it names, in
  /// order — enough for what a search result's `UID FETCH` sends, without
  /// implementing the full grammar (`*` as an open end is not needed here).
  List<int> _parseSequenceSet(String text) {
    final ids = <int>[];
    for (final part in text.split(',')) {
      final colon = part.indexOf(':');
      if (colon < 0) {
        final id = int.tryParse(part);
        if (id != null) ids.add(id);
        continue;
      }
      final start = int.tryParse(part.substring(0, colon));
      final end = int.tryParse(part.substring(colon + 1));
      if (start == null || end == null) continue;
      for (var i = start; i <= end; i++) {
        ids.add(i);
      }
    }
    return ids;
  }

  /// `UID FETCH|MOVE|COPY|STORE|EXPUNGE <uid> ...`.
  void _handleUid(Socket socket, String tag, List<String> words) {
    final uid = int.tryParse(words[2]);
    final index = inbox.indexWhere((m) => m.uid == uid);
    switch (words[1].toUpperCase()) {
      case 'FETCH':
        final items = words.skip(3).join(' ').toUpperCase();
        final out = StringBuffer();
        for (final id in _parseSequenceSet(words[2])) {
          final i = inbox.indexWhere((m) => m.uid == id);
          if (i < 0) continue;
          final message = inbox[i];
          final flags = 'FLAGS (${_flagList(id)})';
          out.write('* ${i + 1} FETCH (UID $id');
          if (items.contains('FLAGS')) out.write(' $flags');
          if (items.contains('RFC822.SIZE')) {
            out.write(
              ' RFC822.SIZE ${message.size ?? utf8.encode(message.rfc822()).length}',
            );
          }
          if (items.contains('ENVELOPE')) out.write(' ${_envelope(message)}');
          if (items.contains('BODY.PEEK[]') || items.contains('BODY[]')) {
            final whole = message.rfc822();
            // A literal: its length in bytes, then exactly that many.
            out.write(' BODY[] {${utf8.encode(whole).length}}\r\n$whole');
          }
          out.write(')\r\n');
        }
        socket.write('$out$tag OK UID FETCH completed\r\n');
      case 'MOVE':
        if (index < 0) {
          socket.write('$tag OK UID MOVE completed\r\n');
          return;
        }
        trash.add(inbox.removeAt(index));
        socket.write(
          '* OK [COPYUID $uidValidity $uid ${trash.length}] moved\r\n'
          '* ${index + 1} EXPUNGE\r\n'
          '$tag OK UID MOVE completed\r\n',
        );
      case 'COPY':
        if (index >= 0) trash.add(inbox[index]);
        socket.write('$tag OK UID COPY completed\r\n');
      case 'STORE':
        final flags = words.skip(4).join(' ');
        if (flags.contains(r'\Seen')) {
          if (failStoreSeen) {
            socket.write('$tag NO [SERVERBUG] cannot set flags\r\n');
            return;
          }
          final adding = words[3].startsWith('+');
          if (uid != null && index >= 0) {
            adding ? seen.add(uid) : seen.remove(uid);
          }
        } else if (flags.contains(r'\Flagged')) {
          final adding = words[3].startsWith('+');
          if (uid != null && index >= 0) {
            adding ? flagged.add(uid) : flagged.remove(uid);
          }
        } else if (uid != null && index >= 0) {
          _deleted.add(uid);
        }
        socket.write('$tag OK UID STORE completed\r\n');
      case 'EXPUNGE':
        // Only what was asked for, as a real UIDPLUS server does.
        if (index >= 0 && _deleted.remove(uid)) {
          inbox.removeAt(index);
          socket.write('* ${index + 1} EXPUNGE\r\n');
        }
        socket.write('$tag OK UID EXPUNGE completed\r\n');
      case 'SEARCH':
        // Whatever `searchResults` is set to, regardless of the actual
        // criteria — a test checks those separately, via `received`.
        final criteria = words.skip(2).join(' ');
        if (criteria.contains('X-GM-RAW') && rejectGmailRaw) {
          socket.write('$tag BAD X-GM-RAW is not for you\r\n');
          return;
        }
        final chosen = criteria.contains('is:starred')
            ? starredResults ?? searchResults
            : criteria.contains('is:unread')
            ? unreadResults ?? searchResults
            : searchResults;
        final ids = chosen.toList()..sort();
        socket.write(
          '* SEARCH ${ids.join(' ')}\r\n$tag OK UID SEARCH completed\r\n',
        );
      default:
        socket.write('$tag BAD unknown command\r\n');
    }
  }

  String _flagList(int uid) => [
    if (seen.contains(uid)) r'\Seen',
    if (flagged.contains(uid)) r'\Flagged',
  ].join(' ');

  String _envelope(FakeImapMessage m) {
    final at = m.address.split('@');
    final person =
        '(${m.name == null ? 'NIL' : '"${m.name}"'} NIL "${at[0]}" "${at[1]}")';
    return 'ENVELOPE ("${m.date}" ${m.subject} ($person) ($person) ($person) '
        'NIL NIL NIL NIL "<${m.uid}@example.com>")';
  }

  String _fetchLine(int seq, FakeImapMessage m) {
    return '* $seq FETCH (UID ${m.uid} '
        'FLAGS (${_flagList(m.uid)}) '
        '${_envelope(m)})\r\n';
  }
}
