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

/// The SMTP server most likely to send mail as [email], to save typing it:
/// the big providers' own, else `smtp.` plus the domain. Empty when [email]
/// has no domain yet. Only ever a guess, the same way [guessImapHost] is.
String guessSmtpHost(String email) {
  final int at = email.lastIndexOf('@');
  if (at < 0 || at == email.length - 1) return '';
  final String domain = email.substring(at + 1).trim().toLowerCase();
  if (domain.isEmpty || !domain.contains('.')) return '';
  return switch (domain) {
    'gmail.com' || 'googlemail.com' => 'smtp.gmail.com',
    'outlook.com' ||
    'hotmail.com' ||
    'live.com' ||
    'msn.com' => 'smtp.office365.com',
    'icloud.com' || 'me.com' || 'mac.com' => 'smtp.mail.me.com',
    'yahoo.com' || 'ymail.com' => 'smtp.mail.yahoo.com',
    _ => 'smtp.$domain',
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

/// The most of a message's text the reader shows.
const int mailTextLimit = 20000;

/// [raw] as text for a small screen: line ends made the same, control and
/// invisible characters removed, trailing spaces trimmed, runs of blank lines
/// squeezed to one, and the whole cut at [limit] characters (at a word, where
/// there is one to be found just before it). [truncated] says it was cut.
({String text, bool truncated}) tidyMailText(
  String raw, {
  int limit = mailTextLimit,
}) {
  String text = raw
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      // Controls but for tab and newline, and zero-width and byte-order marks.
      .replaceAll(
        RegExp(
          '[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F\u200B-\u200F\u2060\uFEFF]',
        ),
        '',
      )
      .replaceAll('\u00A0', ' ')
      .split('\n')
      .map((String line) => line.trimRight())
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
  if (text.length <= limit) return (text: text, truncated: false);
  text = text.substring(0, limit);
  final int space = text.lastIndexOf(RegExp(r'\s'));
  if (space > 0 && space > limit - 200) text = text.substring(0, space);
  return (text: text.trimRight(), truncated: true);
}

/// The readable text of an HTML message: what is between the tags, with
/// paragraphs, line breaks, list items and table rows kept as lines, and
/// scripts, styles, comments and the head dropped. Not a browser: it shows what
/// was said, not how it was laid out.
String plainTextFromHtml(String html) {
  String text = html
      .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
      .replaceAll(
        RegExp(
          r'<(head|style|script|title)\b.*?</\1\s*>',
          caseSensitive: false,
          dotAll: true,
        ),
        '',
      )
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(
        RegExp(
          r'</(p|div|tr|h[1-6]|blockquote|table|ul|ol)\s*>',
          caseSensitive: false,
        ),
        '\n',
      )
      .replaceAll(RegExp(r'<li\b[^>]*>', caseSensitive: false), '\n- ')
      .replaceAll(RegExp(r'</t[dh]\s*>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<[^>]*>'), '');
  text = _decodeEntities(text);
  // Whitespace inside a line is one space; the lines are the ones made above.
  return text
      .split('\n')
      .map((String line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .join('\n');
}

const Map<String, String> _namedEntities = <String, String>{
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
  'ndash': '\u2013',
  'mdash': '\u2014',
  'hellip': '\u2026',
  'laquo': '\u00AB',
  'raquo': '\u00BB',
  'copy': '\u00A9',
  'euro': '\u20AC',
  'aring': '\u00E5',
  'Aring': '\u00C5',
  'auml': '\u00E4',
  'Auml': '\u00C4',
  'ouml': '\u00F6',
  'Ouml': '\u00D6',
  'eacute': '\u00E9',
};

String _decodeEntities(String text) => text.replaceAllMapped(
  RegExp(r'&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);'),
  (Match m) {
    final String entity = m.group(1)!;
    if (entity.startsWith('#')) {
      final int? code = entity.startsWith('#x') || entity.startsWith('#X')
          ? int.tryParse(entity.substring(2), radix: 16)
          : int.tryParse(entity.substring(1));
      if (code == null || code <= 0 || code > 0x10FFFF) return m.group(0)!;
      return String.fromCharCode(code);
    }
    return _namedEntities[entity] ?? m.group(0)!;
  },
);
