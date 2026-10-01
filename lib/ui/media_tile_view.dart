import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/media_snapshot.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Key so tests can find the "now playing" body.
const Key mediaNowKey = ValueKey<String>('media-now');

/// The Now Playing tile's content, fitted to whatever size the tile was
/// given: a small tile shows the title and artist; a medium one adds whether
/// it is playing or paused; a wide (or larger) one puts the album art beside
/// them, when the session has any. With nothing to show it says why, and a
/// tap ([onTap]) is how the user fixes it (allows notification access) or
/// retries, or opens the full pane. `null` in the grid editor, where a tap
/// selects the tile instead.
class MediaTileContentView extends StatelessWidget {
  const MediaTileContentView({
    super.key,
    required this.snapshot,
    required this.ink,
    this.onTap,
  });

  final MediaSnapshot snapshot;
  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget body = SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.gutter / 2),
        child: LayoutBuilder(
          builder: (context, constraints) => switch (snapshot) {
            final MediaPlaying media => _NowPlayingView(
              media: media,
              ink: ink,
              width: constraints.maxWidth,
            ),
            _ => _MessageView(lines: _messageFor(snapshot), ink: ink),
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

List<String> _messageFor(MediaSnapshot snapshot) => switch (snapshot) {
  MediaNone() => const <String>[Messages.mediaNothingPlaying],
  MediaNeedsNotificationAccess() => const <String>[Messages.mediaTapToAllow],
  MediaUnavailable(:final String reason) => <String>[
    reason.toUpperCase(),
    Messages.mediaTapToRetry,
  ],
  MediaPlaying() => const <String>[],
};

/// The box one line of tile text sits in, as a multiple of its type size —
/// same convention as the mail, Text TV and weather tiles.
const double _leading = 1.45;

TextStyle _text(Color ink, double size) => TextStyle(
  fontFamily: kPixelFontFamily,
  fontSize: size,
  height: _leading,
  color: ink,
);

class _MessageView extends StatelessWidget {
  const _MessageView({required this.lines, required this.ink});

  final List<String> lines;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    // An outer `FittedBox`, not a bare `Column`: a one-row-tall tile has no
    // more height than a small one whatever its width, the same fix already
    // applied to every other message-shaped tile.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(Messages.mediaTitle, style: _text(ink, 10)),
          const SizedBox(height: 6),
          for (final String line in lines)
            Text(line, style: _text(ink, 8), softWrap: true),
        ],
      ),
    );
  }
}

class _NowPlayingView extends StatelessWidget {
  const _NowPlayingView({
    required this.media,
    required this.ink,
    required this.width,
  });

  final MediaPlaying media;
  final Color ink;
  final double width;

  static const double _compact = 140;
  static const double _wide = 260;

  @override
  Widget build(BuildContext context) {
    final Widget text = _TextBlock(
      media: media,
      ink: ink,
      compact: width < _compact,
    );
    if (width < _wide || media.artwork == null) return text;
    return Row(
      key: mediaNowKey,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        ClipRect(
          child: Image.memory(
            media.artwork!,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            // A session's art can be any format a music app chose to send;
            // nothing here can fix a bad decode, so it just disappears
            // rather than crashing the tile.
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox(width: 56, height: 56),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: text),
      ],
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({
    required this.media,
    required this.ink,
    required this.compact,
  });

  final MediaPlaying media;
  final Color ink;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        key: mediaNowKey,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            media.title.toUpperCase(),
            style: _text(ink, 10),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            media.artist.toUpperCase(),
            style: _text(ink, 8),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
    return Column(
      key: mediaNowKey,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(Messages.mediaTitle, style: _text(ink, 8)),
        const SizedBox(height: 6),
        Flexible(
          child: Text(
            media.title.toUpperCase(),
            style: _text(ink, 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          media.artist.toUpperCase(),
          style: _text(ink, 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(media.isPlaying ? '[PLAYING]' : '[PAUSED]', style: _text(ink, 8)),
      ],
    );
  }
}
