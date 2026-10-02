import 'package:android_tile_launcher/model/mail.dart';

const int _version = 1;

/// [listing] as JSON, headers only (never a body), to keep between runs. The
/// [account] it was read for goes with it, so another account never shows it.
Map<String, Object?> mailListingToJson(
  MailMessages listing, {
  required String account,
}) => <String, Object?>{
  'v': _version,
  'account': account,
  'total': listing.total,
  'unread': listing.unread,
  'validity': listing.validity,
  'nextOffset': listing.nextOffset,
  'messages': <Object?>[for (final m in listing.messages) _messageToJson(m)],
  'starred': <Object?>[for (final m in listing.starred) _messageToJson(m)],
};

/// The listing [json] holds, or null if it is not one this version wrote or
/// was kept for another [account]. Anything malformed inside is skipped, not
/// fatal: a cache is only ever a head start.
MailMessages? mailListingFromJson(Object? json, {required String account}) {
  if (json is! Map || json['v'] != _version || json['account'] != account) {
    return null;
  }
  final Object? total = json['total'];
  final Object? unread = json['unread'];
  if (total is! int || unread is! int) return null;
  final Object? validity = json['validity'];
  final Object? next = json['nextOffset'];
  return MailMessages(
    _messagesFrom(json['messages']),
    total: total,
    unread: unread,
    validity: validity is int ? validity : null,
    starred: _messagesFrom(json['starred']),
    nextOffset: next is int ? next : null,
  );
}

Map<String, Object?> _messageToJson(MailMessage m) => <String, Object?>{
  'uid': m.uid,
  'from': m.from,
  'subject': m.subject,
  'date': m.date?.millisecondsSinceEpoch,
  'unread': m.unread,
  'starred': m.starred,
  'to': m.to,
  'folder': m.folder,
};

List<MailMessage> _messagesFrom(Object? json) {
  if (json is! List) return const <MailMessage>[];
  return <MailMessage>[for (final Object? entry in json) ?_messageFrom(entry)];
}

MailMessage? _messageFrom(Object? json) {
  if (json is! Map) return null;
  final Object? uid = json['uid'];
  final Object? from = json['from'];
  final Object? subject = json['subject'];
  if (uid is! int || from is! String || subject is! String) return null;
  final Object? date = json['date'];
  final Object? to = json['to'];
  final Object? folder = json['folder'];
  return MailMessage(
    uid: uid,
    from: from,
    subject: subject,
    date: date is int ? DateTime.fromMillisecondsSinceEpoch(date) : null,
    unread: json['unread'] == true,
    starred: json['starred'] == true,
    to: to is String ? to : '',
    folder: folder is String ? folder : null,
  );
}
