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
