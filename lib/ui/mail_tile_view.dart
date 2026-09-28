import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key mailCountKey = ValueKey<String>('mail-count');
Key mailRowKey(int index) => ValueKey<String>('mail-row-$index');

/// The mail tile's content, fitted to whatever size the tile was given: the
/// unread count as a big number on a small one; plus the newest message on a
/// medium one; plus as many of the newest messages as fit, one line each, on a
/// wide (or larger) one. Without an inbox to show it says why, and a tap
/// ([onTap]) is how the user sets mail up, retries, or opens the inbox. `null`
/// in the grid editor, where a tap selects the tile.
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

TextStyle _text(Color ink, double size) =>
    TextStyle(fontFamily: kPixelFontFamily, fontSize: size, color: ink);

String _subjectOf(MailMessage m) =>
    m.subject.isEmpty ? Messages.mailNoSubject : m.subject.toUpperCase();

class _MessageView extends StatelessWidget {
  const _MessageView({required this.lines, required this.ink});

  final List<String> lines;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(Messages.mailTitle, style: _text(ink, 10)),
        const SizedBox(height: 6),
        for (final String line in lines)
          Text(line, style: _text(ink, 8), softWrap: true),
      ],
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
  static const double _rowHeight = 16;
  static const double _headerHeight = 22;

  @override
  Widget build(BuildContext context) {
    final Widget count = FittedBox(
      key: mailCountKey,
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        '${inbox.unread}',
        style: _text(ink, width < _compact ? 28 : 32),
      ),
    );

    if (width < _compact) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          count,
          const SizedBox(height: 4),
          Text(Messages.mailUnread, style: _text(ink, 8)),
        ],
      );
    }

    if (width < _wide) {
      final MailMessage? newest = inbox.messages.firstOrNull;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(Messages.mailTitle, style: _text(ink, 8)),
          const SizedBox(height: 4),
          count,
          Text(Messages.mailUnread, style: _text(ink, 8)),
          if (newest != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              newest.from.toUpperCase(),
              style: _text(ink, 8),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Flexible(
              child: Text(
                _subjectOf(newest),
                style: _text(ink, 8),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...<Widget>[
            const SizedBox(height: 8),
            Text(Messages.mailInboxEmpty, style: _text(ink, 8)),
          ],
        ],
      );
    }

    // Wide: the count down the left, the newest messages down the right.
    final int fit = ((height - _headerHeight) / _rowHeight).floor().clamp(
      1,
      inbox.messages.isEmpty ? 1 : inbox.messages.length,
    );
    return Row(
      children: <Widget>[
        SizedBox(
          width: 84,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(Messages.mailTitle, style: _text(ink, 8)),
              const SizedBox(height: 4),
              count,
              Text(Messages.mailUnread, style: _text(ink, 8)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: inbox.messages.isEmpty
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text(Messages.mailInboxEmpty, style: _text(ink, 8)),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (final (int i, MailMessage m)
                        in inbox.messages.take(fit).indexed)
                      SizedBox(
                        key: mailRowKey(i),
                        height: _rowHeight,
                        child: Row(
                          children: <Widget>[
                            // An unread message is marked and bright; a read
                            // one is not, so the eye finds the new ones.
                            SizedBox(
                              width: 14,
                              child: Text(
                                m.unread ? '*' : '',
                                style: _text(ink, 8),
                              ),
                            ),
                            SizedBox(
                              width: 88,
                              child: Text(
                                m.from.toUpperCase(),
                                style: _text(ink, 8),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _subjectOf(m),
                                style: _text(ink, 8),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
