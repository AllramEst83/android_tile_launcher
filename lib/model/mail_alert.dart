import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/mail.dart';

/// How the launcher tells the user about new mail.
enum MailAlertMode {
  /// No alerts.
  off('OFF'),

  /// A check in the background about every 15 minutes (the shortest interval
  /// Android allows for background work).
  periodic('EVERY 15 MIN'),

  /// A connection to the mail server kept open all the time (IMAP IDLE, in a
  /// foreground service with its own permanent notification), so the server
  /// reports new mail the moment it arrives.
  instant('INSTANT');

  const MailAlertMode(this.label);

  final String label;
}

/// Which message a notification is about: the id the sheet knows it by (see
/// [MailMessage.uid]) and the folder it lives in, if not the inbox's own.
class MailRef {
  const MailRef({required this.uid, this.folder});

  final int uid;
  final String? folder;

  /// What a notification carries back to the app when it is tapped.
  String get payload => '$uid|${folder ?? ''}';

  /// The ref [payload] was made from, or null for anything else.
  static MailRef? fromPayload(String? payload) {
    if (payload == null) return null;
    final int bar = payload.indexOf('|');
    if (bar < 1) return null;
    final int? uid = int.tryParse(payload.substring(0, bar));
    if (uid == null) return null;
    final String folder = payload.substring(bar + 1);
    return MailRef(uid: uid, folder: folder.isEmpty ? null : folder);
  }

  @override
  bool operator ==(Object other) =>
      other is MailRef && other.uid == uid && other.folder == folder;

  @override
  int get hashCode => Object.hash(uid, folder);
}

/// One notification to show. [ref] null is the summary of the messages that
/// did not get one each: its tap just opens the mail.
class MailAlert {
  const MailAlert({required this.title, required this.body, this.ref});

  final String title;
  final String body;
  final MailRef? ref;
}

/// How far the inbox had been looked through, so the next look only reports
/// what is newer. [source] says whose ids [lastUid] is (the account, and
/// whether they are All Mail's or the inbox folder's): ids from different
/// places cannot be compared.
class MailAlertCursor {
  const MailAlertCursor({required this.source, required this.lastUid});

  final String source;
  final int lastUid;

  Map<String, Object> toJson() => <String, Object>{
    'source': source,
    'lastUid': lastUid,
  };

  static MailAlertCursor? fromJson(Object? json) {
    if (json is! Map) return null;
    final Object? source = json['source'];
    final Object? lastUid = json['lastUid'];
    if (source is! String || lastUid is! int) return null;
    return MailAlertCursor(source: source, lastUid: lastUid);
  }
}

class MailAlertPlan {
  const MailAlertPlan({required this.alerts, required this.cursor});

  final List<MailAlert> alerts;
  final MailAlertCursor cursor;
}

/// What to notify about, given a fresh look at the inbox ([listing], newest
/// first) and where the last look ended ([cursor]).
///
/// Only unread messages newer than the cursor are reported, oldest first (so
/// the newest ends up on top of the shade), at most [maxAlerts] of them with a
/// summary for the rest. The first look, or the first after the account or the
/// kind of id changed, reports nothing: it only sets the cursor, so turning
/// alerts on does not announce the whole inbox.
MailAlertPlan planMailAlerts({
  required MailMessages listing,
  required String account,
  MailAlertCursor? cursor,
  int maxAlerts = 4,
}) {
  final List<MailMessage> all = listing.messages;
  final String source =
      '$account|${all.any((MailMessage m) => m.folder != null) ? 'all' : 'inbox'}';
  int newest = 0;
  for (final MailMessage m in all) {
    if (m.serverUid > newest) newest = m.serverUid;
  }
  if (cursor == null || cursor.source != source) {
    return MailAlertPlan(
      alerts: const <MailAlert>[],
      cursor: MailAlertCursor(source: source, lastUid: newest),
    );
  }
  final List<MailMessage> fresh = <MailMessage>[
    for (final MailMessage m in all)
      if (m.unread && m.serverUid > cursor.lastUid) m,
  ]..sort((a, b) => b.serverUid.compareTo(a.serverUid));
  final List<MailMessage> shown = fresh.take(maxAlerts).toList();
  final int more = fresh.length - shown.length;
  return MailAlertPlan(
    alerts: <MailAlert>[
      if (more > 0)
        MailAlert(
          title: Messages.mailAlertMoreTitle(more),
          body: Messages.mailAlertMoreBody,
        ),
      for (final MailMessage m in shown.reversed)
        MailAlert(
          title: m.from,
          body: m.subject.isEmpty ? Messages.mailNoSubject : m.subject,
          ref: MailRef(uid: m.uid, folder: m.folder),
        ),
    ],
    cursor: MailAlertCursor(
      source: source,
      lastUid: newest > cursor.lastUid ? newest : cursor.lastUid,
    ),
  );
}
