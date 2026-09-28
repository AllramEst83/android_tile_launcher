import 'package:android_tile_launcher/model/clock_format.dart';

/// The IMAP server most likely to belong to [email], to save typing it: the
/// big providers' own, else `imap.` plus the domain. Empty when [email] has no
/// domain yet. Only ever a suggestion; the user can change it.
String guessImapHost(String email) {
  final int at = email.lastIndexOf('@');
  if (at < 0 || at == email.length - 1) return '';
  final String domain = email.substring(at + 1).trim().toLowerCase();
  if (domain.isEmpty || !domain.contains('.')) return '';
  return switch (domain) {
    'gmail.com' || 'googlemail.com' => 'imap.gmail.com',
    'outlook.com' ||
    'hotmail.com' ||
    'live.com' ||
    'msn.com' => 'outlook.office365.com',
    'icloud.com' || 'me.com' || 'mac.com' => 'imap.mail.me.com',
    'yahoo.com' || 'ymail.com' => 'imap.mail.yahoo.com',
    _ => 'imap.$domain',
  };
}

/// When a message was sent, short: `14:32` if today, else `28 SEP`; empty when
/// the date is unknown.
String formatMailDate(DateTime? sent, DateTime now) {
  if (sent == null) return '';
  final bool today =
      sent.year == now.year && sent.month == now.month && sent.day == now.day;
  if (today) return formatClockTime(sent);
  // `FRI 27 SEP` without the weekday.
  return formatClockDate(sent).substring(4);
}
