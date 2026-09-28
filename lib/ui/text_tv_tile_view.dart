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
          Text(line, style: _text(ink, 9), softWrap: true),
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

  /// Under this a tile has room for the name and the page number, no more.
  static const double _compact = 120;

  /// Headline type, and the box one line of it sits in. Big enough to read at
  /// arm's length: a headline nobody can read is worth no tile space at all.
  static const double _headline = 11;
  static const double _lineHeight = _headline * _leading;

  /// Air between two headlines, so the list reads as separate stories rather
  /// than one block of text.
  static const double _gap = 5;
  static const double _headerHeight = 22;

  /// The most lines the headline at [index] may wrap to: the lead story, the
  /// one the page leads with, gets an extra one over the rest.
  int _cap(int index) => index == 0 ? 3 : 2;

  /// How many lines [text] actually needs to read in full at [width], up to
  /// [cap]: a short headline costs one line, so the tile fits more of them; a
  /// long one wraps rather than being cut, as far as there is room for.
  int _linesNeeded(BuildContext context, String text, int cap) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: _text(ink, _headline)),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    final int lines = painter.computeLineMetrics().length;
    painter.dispose();
    return lines.clamp(1, cap);
  }

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
    final double room = height - _headerHeight;
    final List<Widget> rows = <Widget>[];
    double used = 0;
    for (final (int i, String line) in headlines.indexed) {
      if (i == 0 && room <= 0) break;
      final int wanted = _linesNeeded(context, line.toUpperCase(), _cap(i));
      // The lead story is shown even on a tile too short for all its lines,
      // with however many of them fit; every later one is all or nothing.
      final int lines = i == 0
          ? (room / _lineHeight).floor().clamp(1, wanted)
          : wanted;
      final double needed = lines * _lineHeight + (i == 0 ? 0 : _gap);
      if (i > 0 && used + needed > room) break;
      rows.add(
        Padding(
          key: textTvHeadlineKey(i),
          padding: EdgeInsets.only(top: i == 0 ? 0 : _gap),
          child: SizedBox(
            height: lines * _lineHeight,
            child: Text(
              line.toUpperCase(),
              style: _text(ink, _headline),
              maxLines: lines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
      used += needed;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: _headerHeight,
          child: Row(
            children: <Widget>[
              Text(Messages.textTvTitle, style: _text(ink, 10)),
              const Spacer(),
              Text('${page.number}', style: _text(ink, 10)),
            ],
          ),
        ),
        ...rows,
      ],
    );
  }
}
