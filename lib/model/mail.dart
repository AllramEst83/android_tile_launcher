import 'dart:typed_data';

/// One message in the inbox, as far as a list needs it: no body.
class MailMessage {
  const MailMessage({
    required this.uid,
    required this.from,
    required this.subject,
    this.date,
    this.unread = false,
    this.starred = false,
    this.to = '',
    this.folder,
  });

  /// The server's id for it, which never changes and is never reused, unlike
  /// its position in the inbox. What a later move to Trash must go by.
  final int uid;

  /// Who sent it: the display name if there is one, else the address. Never
  /// empty.
  final String from;

  /// May be empty; the list shows `(no subject)` then.
  final String subject;

  /// When it was sent, in local time; null if the header was missing or
  /// unreadable.
  final DateTime? date;
  final bool unread;

  /// Whether it carries the server's `\Flagged` flag (Gmail's star).
  final bool starred;

  /// Who it was sent to (the first address: the name if there is one, else the
  /// address), for the Sent and Drafts folders; empty if unknown.
  final String to;

  /// The folder this message lives in when that is not the one being looked at
  /// (an archived starred message shown among the inbox's), else null. Such a
  /// message's [uid] is the server's id made negative, so it can never be
  /// mistaken for an inbox message with the same number; [serverUid] undoes
  /// that.
  final String? folder;

  /// The id to give the server, whichever folder it is in.
  int get serverUid => uid.abs();

  MailMessage copyWith({bool? unread, bool? starred}) => MailMessage(
    uid: uid,
    from: from,
    subject: subject,
    date: date,
    unread: unread ?? this.unread,
    starred: starred ?? this.starred,
    to: to,
    folder: folder,
  );
}

/// What a folder is for, as far as the sheet treats folders differently.
enum MailFolderKind {
  inbox,
  starred,
  sent,
  drafts,
  allMail,
  spam,
  trash,
  other,
}

/// One folder on the account. [name] is the server's own path for it, what
/// every call that takes a folder is given; [label] is what the picker shows.
class MailFolder {
  const MailFolder({
    required this.name,
    required this.label,
    this.kind = MailFolderKind.other,
  });

  final String name;
  final String label;
  final MailFolderKind kind;

  /// Whether DELETE (a move to Trash) means anything here.
  bool get canTrash =>
      kind != MailFolderKind.trash && kind != MailFolderKind.spam;
}

/// [messages] with the starred ones first, each group keeping its order
/// (newest first, as the service hands them over).
List<MailMessage> starredFirst(List<MailMessage> messages) => <MailMessage>[
  ...messages.where((MailMessage m) => m.starred),
  ...messages.where((MailMessage m) => !m.starred),
];

/// A unit an age cutoff counts in.
enum MailAgeUnit {
  days('DAYS'),
  weeks('WEEKS'),
  months('MONTHS'),
  years('YEARS');

  const MailAgeUnit(this.label);

  final String label;
}

/// Which side of the cutoff an age filter keeps.
enum MailAgeDirection { older, newer }

/// How far back or forward an age filter reaches, e.g. 3 weeks, and which
/// side of that cutoff it keeps.
class MailAgeFilter {
  const MailAgeFilter(this.amount, this.unit, this.direction);

  final int amount;
  final MailAgeUnit unit;
  final MailAgeDirection direction;

  /// The cutoff date, given [now]: with [MailAgeDirection.older] a message
  /// sent before this passes the filter; with [MailAgeDirection.newer] one
  /// sent at or after it does.
  DateTime cutoff(DateTime now) => switch (unit) {
    MailAgeUnit.days => now.subtract(Duration(days: amount)),
    MailAgeUnit.weeks => now.subtract(Duration(days: amount * 7)),
    MailAgeUnit.months => DateTime(now.year, now.month - amount, now.day),
    MailAgeUnit.years => DateTime(now.year - amount, now.month, now.day),
  };

  @override
  bool operator ==(Object other) =>
      other is MailAgeFilter &&
      other.amount == amount &&
      other.unit == unit &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(amount, unit, direction);

  @override
  String toString() => 'MailAgeFilter($amount ${unit.label} ${direction.name})';
}

/// A filter over the inbox listing: free text (matches the subject or the
/// body), the sender's address, the recipient's address, and/or an age
/// cutoff (older or newer than a given amount). Every field that is set
/// narrows the results further (AND); [isEmpty] means no filtering — the
/// plain inbox listing.
class MailFilter {
  const MailFilter({this.text = '', this.from = '', this.to = '', this.age});

  final String text;
  final String from;
  final String to;
  final MailAgeFilter? age;

  bool get isEmpty => text.isEmpty && from.isEmpty && to.isEmpty && age == null;

  MailFilter withoutText() => MailFilter(from: from, to: to, age: age);
  MailFilter withoutFrom() => MailFilter(text: text, to: to, age: age);
  MailFilter withoutTo() => MailFilter(text: text, from: from, age: age);
  MailFilter withoutAge() => MailFilter(text: text, from: from, to: to);

  @override
  bool operator ==(Object other) =>
      other is MailFilter &&
      other.text == text &&
      other.from == from &&
      other.to == to &&
      other.age == age;

  @override
  int get hashCode => Object.hash(text, from, to, age);

  @override
  String toString() =>
      'MailFilter(text: $text, from: $from, to: $to, age: $age)';
}

sealed class MailResult {
  const MailResult();
}

/// The newest [messages] first, at most as many as were asked for. [total] is
/// how many the whole inbox holds and [unread] how many of those are unseen.
class MailMessages extends MailResult {
  const MailMessages(
    this.messages, {
    required this.total,
    required this.unread,
    this.validity,
    this.starred = const <MailMessage>[],
    this.nextOffset,
  });

  /// Starred messages from anywhere on the account, asked for with the inbox
  /// listing (an archived one is not in the inbox itself). Never repeated in
  /// [messages].
  final List<MailMessage> starred;

  /// Where the next page starts, to ask for with `offset`; null when this was
  /// the last.
  final int? nextOffset;

  final List<MailMessage> messages;
  final int total;
  final int unread;

  /// The server's `UIDVALIDITY` for the inbox: the ids in [messages] mean these
  /// messages only while it stays the same. Hand it back to `moveToTrash`.
  final int? validity;
}

/// No account has been set up yet: the tile offers to set one up.
class MailNotSetUp extends MailResult {
  const MailNotSetUp();
}

/// The server could not be reached or refused us; [reason] is short and
/// printable and never contains the password.
class MailUnavailable extends MailResult {
  const MailUnavailable(this.reason);

  final String reason;
}

/// Who the launcher reads mail as. Never the password.
class MailAccountInfo {
  const MailAccountInfo({required this.email, required this.host});

  final String email;
  final String host;
}

sealed class MailMoveResult {
  const MailMoveResult();
}

/// The message is now in [folder] (the server's own name for its Trash).
class MailMoved extends MailMoveResult {
  const MailMoved(this.folder);

  final String folder;
}

/// There is no such message in the inbox any more: moved or deleted elsewhere.
class MailGone extends MailMoveResult {
  const MailGone();
}

class MailMoveNotSetUp extends MailMoveResult {
  const MailMoveNotSetUp();
}

/// Nothing was changed; [reason] is short and printable.
class MailMoveFailed extends MailMoveResult {
  const MailMoveFailed(this.reason);

  final String reason;
}

/// One address on a message's To or Cc line: a display name (may be empty)
/// and the address itself (never empty — an entry with no address is left
/// out by whoever builds the list).
class MailParticipant {
  const MailParticipant({required this.address, this.name = ''});

  final String name;
  final String address;

  /// What a chip shows: the name if there is one, else the bare address.
  String get label => name.isNotEmpty ? name : address;
}

/// One file attached to a message, held whole: this launcher fetches a
/// message's full body to read it at all, so the bytes are already at hand
/// once the reader is open — a DOWNLOAD button costs no extra trip to the
/// server.
class MailAttachment {
  const MailAttachment({
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    required this.bytes,
  });

  /// Never empty: an attachment with no name from the sender is given one.
  final String name;
  final int sizeBytes;

  /// What to save it as, e.g. `image/png`; `application/octet-stream` when
  /// the message did not say.
  final String mimeType;
  final Uint8List bytes;
}

/// One message in full, as far as this launcher shows one: who, when, what,
/// and its text (plain text, or the readable part of an HTML-only message).
class MailBody {
  const MailBody({
    required this.uid,
    required this.from,
    this.fromAddress = '',
    this.to = const <MailParticipant>[],
    this.cc = const <MailParticipant>[],
    required this.subject,
    required this.text,
    this.html,
    this.htmlWithImages,
    this.date,
    this.truncated = false,
    this.attachments = const <MailAttachment>[],
    this.markedRead = true,
  });

  final int uid;
  final String from;

  /// The sender's own address, for REPLY/FORWARD to address and for tapping
  /// the sender to compose a fresh message (never shown itself: [from] is
  /// what the reader shows). Empty if the message gave none.
  final String fromAddress;

  /// Who the message was addressed to and copied to, in the order the
  /// message itself gave them. Either may be empty.
  final List<MailParticipant> to;
  final List<MailParticipant> cc;

  final String subject;
  final DateTime? date;

  /// Never empty: a message with nothing to show says so in [text]'s place
  /// on the screen, not here. Always plain text, even when [html] is set (for
  /// quoting a reply/forward, and as the reader's fallback).
  final String text;

  /// The message's own markup, images stripped, for a rich view; null when
  /// the message was plain text to begin with (then [text] is shown as-is).
  final String? html;

  /// [html] with its pictures put back — inline ones as data URIs, remote
  /// ones left as the `<img>` tag the sender wrote — for SHOW IMAGES. Null
  /// when [html] is null or had no pictures to begin with (then there is
  /// nothing for the button to reveal).
  final String? htmlWithImages;

  /// Whether [text] was cut short because the message is very long.
  final bool truncated;

  /// The message's attachments, whole (see [MailAttachment]).
  final List<MailAttachment> attachments;

  /// Whether opening it marked it read on the server (it should; when that one
  /// step failed the message is still shown, and this is false).
  final bool markedRead;
}

sealed class MailReadResult {
  const MailReadResult();
}

/// The message, opened. Opening it has marked it read (see [MailBody.markedRead]).
class MailOpened extends MailReadResult {
  const MailOpened(this.body);

  final MailBody body;
}

/// There is no such message in the inbox any more.
class MailReadGone extends MailReadResult {
  const MailReadGone();
}

class MailReadNotSetUp extends MailReadResult {
  const MailReadNotSetUp();
}

/// The message could not be opened and nothing was changed; [reason] is short
/// and printable.
class MailReadFailed extends MailReadResult {
  const MailReadFailed(this.reason);

  final String reason;
}

sealed class MailMarkResult {
  const MailMarkResult();
}

/// The message is now [read] (or unread) on the server.
class MailMarked extends MailMarkResult {
  const MailMarked({required this.read});

  final bool read;
}

class MailMarkGone extends MailMarkResult {
  const MailMarkGone();
}

class MailMarkNotSetUp extends MailMarkResult {
  const MailMarkNotSetUp();
}

/// Nothing was changed; [reason] is short and printable.
class MailMarkFailed extends MailMarkResult {
  const MailMarkFailed(this.reason);

  final String reason;
}

sealed class MailSendResult {
  const MailSendResult();
}

/// The server accepted the message for delivery.
class MailSent extends MailSendResult {
  const MailSent();
}

/// No account has been set up yet: there is nothing to send as.
class MailSendNotSetUp extends MailSendResult {
  const MailSendNotSetUp();
}

/// Nothing was sent; [reason] is short and printable and never contains the
/// password.
class MailSendFailed extends MailSendResult {
  const MailSendFailed(this.reason);

  final String reason;
}

sealed class MailStarResult {
  const MailStarResult();
}

/// The message is now [starred] (or not) on the server.
class MailStarred extends MailStarResult {
  const MailStarred({required this.starred});

  final bool starred;
}

class MailStarGone extends MailStarResult {
  const MailStarGone();
}

class MailStarNotSetUp extends MailStarResult {
  const MailStarNotSetUp();
}

/// Nothing was changed; [reason] is short and printable.
class MailStarFailed extends MailStarResult {
  const MailStarFailed(this.reason);

  final String reason;
}
