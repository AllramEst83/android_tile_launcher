import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/text_tv_headlines.dart';
import 'package:android_tile_launcher/model/text_tv_page.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
Key textTvHeadlineKey(int index) => ValueKey<String>('text-tv-headline-$index');

/// The Text TV tile's content, fitted to whatever size the tile was given: the
/// name and the headline page's number on a small tile, plus as many of its
/// headlines as fit on a larger one. A tap ([onTap]) opens the full-screen
/// viewer, whatever the tile is showing (a failed read is retried there).
/// `null` in the grid editor, where a tap selects the tile.
class TextTvTileContentView extends StatelessWidget {
  const TextTvTileContentView({
    super.key,
    required this.result,
    required this.ink,
    this.onTap,
  });

  final TextTvResult result;
  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget body = SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.gutter / 2),
        child: LayoutBuilder(
          builder: (context, constraints) => switch (result) {
            TextTvShown(:final TextTvPage page) => _Headlines(
              page: page,
              ink: ink,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            ),
            TextTvNotBroadcast() => _Plain(
              lines: const <String>[Messages.textTvNotBroadcast],
              ink: ink,
            ),
            TextTvFailed(:final String reason) => _Plain(
              lines: <String>[reason.toUpperCase(), Messages.textTvTapToOpen],
              ink: ink,
            ),
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

TextStyle _text(Color ink, double size) =>
    TextStyle(fontFamily: kPixelFontFamily, fontSize: size, color: ink);

class _Plain extends StatelessWidget {
  const _Plain({required this.lines, required this.ink});

  final List<String> lines;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(Messages.textTvTitle, style: _text(ink, 10)),
        const SizedBox(height: 6),
        for (final String line in lines)
          Text(line, style: _text(ink, 8), softWrap: true),
      ],
    );
  }
}

class _Headlines extends StatelessWidget {
  const _Headlines({
    required this.page,
    required this.ink,
    required this.width,
    required this.height,
  });

  final TextTvPage page;
  final Color ink;
  final double width;
  final double height;

  static const double _compact = 120;
  static const double _lineHeight = 16;
  static const double _headerHeight = 24;

  @override
  Widget build(BuildContext context) {
    if (width < _compact) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(Messages.textTvTitle, style: _text(ink, 8)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('${page.number}', style: _text(ink, 20)),
          ),
        ],
      );
    }
    final List<String> headlines = textTvHeadlines(page);
    final int fit = ((height - _headerHeight) / _lineHeight).floor().clamp(
      0,
      headlines.length,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: _headerHeight,
          child: Row(
            children: <Widget>[
              Text(Messages.textTvTitle, style: _text(ink, 10)),
              const Spacer(),
              Text('${page.number}', style: _text(ink, 8)),
            ],
          ),
        ),
        for (final (int i, String line) in headlines.take(fit).indexed)
          SizedBox(
            key: textTvHeadlineKey(i),
            height: _lineHeight,
            child: Text(
              line.toUpperCase(),
              style: _text(ink, 8),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
