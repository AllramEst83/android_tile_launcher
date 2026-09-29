import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key mailCountKey = ValueKey<String>('mail-count');
const Key mailHeaderKey = ValueKey<String>('mail-header');
Key mailRowKey(int index) => ValueKey<String>('mail-row-$index');

/// The mail tile's content, fitted to whatever size the tile was given: the
/// unread count as a big number on a small one; plus the newest message on a
/// medium one; plus as many of the newest messages as fit, sender and subject
/// on a line each, on a wide (or larger) one. Without an inbox to show it says
/// why, and a tap ([onTap]) is how the user sets mail up, retries, or opens the
/// inbox. `null` in the grid editor, where a tap selects the tile.
class MailTileContentView extends StatelessWidget {
  const MailTileContentView({
    super.key,
    required this.result,
    required this.ink,
    this.onTap,
  });

  final MailResult result;
  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget body = SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.gutter / 2),
        child: LayoutBuilder(
          builder: (context, constraints) => switch (result) {
            MailMessages() => _InboxView(
              inbox: result as MailMessages,
              ink: ink,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            ),
            _ => _MessageView(lines: _messageFor(result), ink: ink),
          },
        ),
      ),
    );
    final VoidCallback? tap = onTap;
    if (tap == null) return body;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tap,
      child: body,
    );
  }
}

List<String> _messageFor(MailResult result) => switch (result) {
  MailNotSetUp() => const <String>[Messages.mailTapToSetUp],
  MailUnavailable(:final String reason) => <String>[
    reason.toUpperCase(),
    Messages.mailTapToRetry,
  ],
  MailMessages() => const <String>[],
};

/// The box one line of tile text sits in, as a multiple of its type size. Set
/// here rather than left to the font, so a row's height is known from its type
/// size alone and a wrapped line sits exactly one row below the one above it.
const double _leading = 1.45;

TextStyle _text(Color ink, double size) => TextStyle(
  fontFamily: kPixelFontFamily,
  fontSize: size,
  height: _leading,
  color: ink,
);

String _subjectOf(MailMessage m) =>
    m.subject.isEmpty ? Messages.mailNoSubject : m.subject.toUpperCase();

class _MessageView extends StatelessWidget {
  const _MessageView({required this.lines, required this.ink});

  final List<String> lines;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    // An outer `FittedBox`, not a bare `Column`: a one-row-tall tile has no
    // more height than a small one whatever its width, the same "width
    // doesn't imply height" fix already applied elsewhere (the files,
    // alarm, Text TV, device, weather and agenda tiles), so this shrinks
    // the whole message rather than overflowing.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(Messages.mailTitle, style: _text(ink, 10)),
          const SizedBox(height: 6),
          for (final String line in lines)
            Text(line, style: _text(ink, 9), softWrap: true),
        ],
      ),
    );
  }
}

class _InboxView extends StatelessWidget {
  const _InboxView({
    required this.inbox,
    required this.ink,
    required this.width,
    required this.height,
  });

  final MailMessages inbox;
  final Color ink;
  final double width;
  final double height;

  static const double _compact = 120;
  static const double _wide = 260;

  /// A message on a wide tile: who it is from over what it is about, each on a
  /// line of its own, at a size that can be read at arm's length. One cramped
  /// line holding both said less than this says in two.
  static const double _sender = 11;
  static const double _subject = 10;

  /// Air between two messages, so the list reads as messages, not as lines.
  static const double _gap = 5;

  /// The width the unread marker and the subject's indent under it take, so a
  /// subject lines up with its sender's name.
  static const double _marker = 14;

  /// The count on a wide tile's header line, and the room that line needs for
  /// it: it is the tallest thing on the line.
  static const double _headerCount = 18;

  /// The count on a medium tile's own line, above the sender/subject block.
  /// Bigger than the wide header's, since here it has no `MAIL`/`UNREAD` to
  /// share a line with.
  static const double _mediumCount = 30;

  /// Air between the title and the count, and between the count block and
  /// the newest message below it, on a medium tile.
  static const double _mediumGap = 4;
  static const double _mediumNewestGap = 8;

  Widget _count(double size, Alignment alignment) => FittedBox(
    key: mailCountKey,
    fit: BoxFit.scaleDown,
    alignment: alignment,
    child: Text('${inbox.unread}', style: _text(ink, size)),
  );

  @override
  Widget build(BuildContext context) {
    // Every fixed-height row below is sized off the FONT SIZE setting's
    // scaler, not the bare type size: a `SizedBox` built from the unscaled
    // size would still hold the same physical height while the `Text`
    // inside it rendered taller, overflowing it.
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double senderLine = scaler.scale(_sender) * _leading;
    final double subjectLine = scaler.scale(_subject) * _leading;
    final double rowHeight = senderLine + subjectLine;
    final double headerHeight = scaler.scale(_headerCount) * _leading + 2;

    if (width < _compact) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _count(28, Alignment.centerLeft),
          const SizedBox(height: 4),
          Text(Messages.mailUnread, style: _text(ink, 9)),
        ],
      );
    }

    if (width < _wide) {
      final MailMessage? newest = inbox.messages.firstOrNull;
      // The title/count/unread block is shown whatever the height: measured
      // with the real scaler, not assumed, so the room left over for the
      // newest message below it is never a guess. A tile too short even for
      // that much already overflows before Phase 35 (small/flat tiles) fixes
      // it; this is only about what to add underneath it.
      final double titleLine = scaler.scale(9) * _leading;
      final double countLine = scaler.scale(_mediumCount) * _leading;
      final double unreadLine = scaler.scale(9) * _leading;
      final double headerBlock =
          titleLine + _mediumGap + countLine + unreadLine;
      final double room = height - headerBlock - _mediumNewestGap;

      final List<Widget> children = <Widget>[
        Text(Messages.mailTitle, style: _text(ink, 9)),
        const SizedBox(height: _mediumGap),
        _count(_mediumCount, Alignment.centerLeft),
        Text(Messages.mailUnread, style: _text(ink, 9)),
      ];

      if (newest != null) {
        if (room >= senderLine) {
          children.add(const SizedBox(height: _mediumNewestGap));
          children.add(
            Text(
              newest.from.toUpperCase(),
              style: _text(ink, _sender),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
          // Only as many subject lines as are left, same idea as the wide
          // list below deciding how many rows fit: a squeezed line ellipsised
          // to nothing says less than one it can actually show.
          final int subjectLines = ((room - senderLine) / subjectLine)
              .floor()
              .clamp(0, 2);
          if (subjectLines > 0) {
            children.add(
              Flexible(
                child: Text(
                  _subjectOf(newest),
                  style: _text(ink, _subject),
                  maxLines: subjectLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }
        }
      } else if (room >= subjectLine) {
        children.add(const SizedBox(height: _mediumNewestGap));
        children.add(
          Text(Messages.mailInboxEmpty, style: _text(ink, _subject)),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    }

    // Wide: the count on one header line, so the messages below have the whole
    // width of the tile to say who wrote and what about.
    final double room = height - headerHeight;
    final int fit = (room / (rowHeight + _gap)).floor().clamp(
      1,
      inbox.messages.isEmpty ? 1 : inbox.messages.length,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          key: mailHeaderKey,
          height: headerHeight,
          child: Row(
            children: <Widget>[
              Text(Messages.mailTitle, style: _text(ink, 10)),
              Expanded(child: _count(_headerCount, Alignment.centerRight)),
              const SizedBox(width: 6),
              Text(Messages.mailUnread, style: _text(ink, 9)),
            ],
          ),
        ),
        if (inbox.messages.isEmpty)
          Text(Messages.mailInboxEmpty, style: _text(ink, _subject))
        else
          for (final (int i, MailMessage m) in inbox.messages.take(fit).indexed)
            Padding(
              key: mailRowKey(i),
              padding: EdgeInsets.only(top: i == 0 ? 0 : _gap),
              child: SizedBox(
                height: rowHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      height: senderLine,
                      child: Row(
                        children: <Widget>[
                          // An unread message is marked, so the eye finds the
                          // new ones without having to read them.
                          SizedBox(
                            width: _marker,
                            child: Text(
                              m.unread ? '*' : '',
                              style: _text(ink, _sender),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              m.from.toUpperCase(),
                              style: _text(ink, _sender),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: subjectLine,
                      child: Padding(
                        padding: const EdgeInsets.only(left: _marker),
                        child: Text(
                          _subjectOf(m),
                          style: _text(ink, _subject),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
