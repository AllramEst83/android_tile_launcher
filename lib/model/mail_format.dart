import 'package:android_tile_launcher/model/clock_format.dart';
import 'package:android_tile_launcher/model/mail.dart';

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

/// [raw] split into addresses on a comma, semicolon or newline (whatever a
/// To/Cc field is typed with), trimmed and with the empty pieces a trailing
/// separator leaves behind dropped. Order is kept; duplicates are not removed
/// (the server does not mind, and a compose field should show what was typed).
List<String> parseAddressList(String raw) => raw
    // A stray zero-width space (the compose fields' own invisible
    // placeholder for an otherwise-empty chip field) is never part of an
    // address.
    .replaceAll('​', '')
    .split(RegExp(r'[,;\n]'))
    .map((String part) => part.trim())
    .where((String part) => part.isNotEmpty)
    .toList();

/// Whether [text] looks like a finished email address — something, an `@`,
/// something, a dot, something — just enough to tell a completed address
/// from one still being typed, for the compose fields' chip-as-you-type
/// behaviour. Not full RFC validation: the server is the real judge of
/// whether it exists.
bool looksLikeCompleteEmail(String text) =>
    RegExp(r'^[^\s@,;]+@[^\s@,;]+\.[^\s@,;]+$').hasMatch(text.trim());

/// The Cc line for "reply all": every address [body] was sent To or Cc'd to,
/// except [selfEmail] (the account reading it) and [body]'s own sender (who
/// becomes the reply's To, not its Cc, the same as a plain REPLY). Order is
/// kept, case-insensitive duplicates dropped.
List<String> replyAllCcAddresses(MailBody body, String? selfEmail) {
  final String self = (selfEmail ?? '').trim().toLowerCase();
  final String sender = body.fromAddress.trim().toLowerCase();
  final List<String> result = <String>[];
  final Set<String> seen = <String>{};
  for (final MailParticipant p in <MailParticipant>[...body.to, ...body.cc]) {
    final String address = p.address.trim();
    final String key = address.toLowerCase();
    if (address.isEmpty || key == self || key == sender || !seen.add(key)) {
      continue;
    }
    result.add(address);
  }
  return result;
}

/// Whether [text] looks like HTML markup rather than plain prose: some
/// senders' mail clients fill the "plain text" alternative with the markup
/// itself by mistake, and that should still be shown as a rich view rather
/// than as literal angle brackets. Only the first part is checked; a message
/// can be large and this only needs a hint, not a proof.
bool looksLikeHtml(String text) {
  final String sample = text.length > 2000 ? text.substring(0, 2000) : text;
  return RegExp(
    r'<(!doctype\s+html|html[\s>]|body[\s>]|div[\s>]|table[\s>]|p[\s>]|br\s*/?>|span[\s>]|a\s)',
    caseSensitive: false,
  ).hasMatch(sample);
}

/// [html] with every `<img>` tag removed, for the default view: an `<img>`
/// left in would fetch a remote file (or reveal an inline one) behind the
/// scenes just to render the message. SHOW IMAGES shows
/// [MailBody.htmlWithImages] instead.
String stripImagesFromHtml(String html) =>
    html.replaceAll(RegExp(r'<img\b[^>]*>', caseSensitive: false), '');

/// [html] with every `cid:xxx` image source in [dataUriByCid] (keyed by the
/// content id, lower-cased, angle brackets stripped) replaced by its data
/// URI; a `cid:` this message never attached, and every remote
/// `http(s)://` image, is left exactly as the sender wrote it — a remote one
/// is fetched by whatever renders the html, once SHOW IMAGES is tapped.
String resolveCidImages(String html, Map<String, String> dataUriByCid) {
  if (dataUriByCid.isEmpty) return html;
  return html.replaceAllMapped(RegExp('''cid:([^"'\\s>]+)'''), (Match m) {
    final String id = m.group(1)!.toLowerCase();
    return dataUriByCid[id] ?? m.group(0)!;
  });
}

/// A file size for a person to read: bytes under a kilobyte as-is, otherwise
/// KB or MB to one decimal place.
String formatAttachmentSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
