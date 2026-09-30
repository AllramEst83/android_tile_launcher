/// One message in the inbox, as far as a list needs it: no body.
class MailMessage {
  const MailMessage({
    required this.uid,
    required this.from,
    required this.subject,
    this.date,
    this.unread = false,
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

  MailMessage copyWith({bool? unread}) => MailMessage(
    uid: uid,
    from: from,
    subject: subject,
    date: date,
    unread: unread ?? this.unread,
  );
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
  });

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

/// One message in full, as far as this launcher shows one: who, when, what,
/// and its text (plain text, or the readable part of an HTML-only message).
/// Attachments and pictures are counted, never downloaded to the screen.
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
    this.date,
    this.truncated = false,
    this.attachments = 0,
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

  /// Whether [text] was cut short because the message is very long.
  final bool truncated;

  /// How many attachments the message carries.
  final int attachments;

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
