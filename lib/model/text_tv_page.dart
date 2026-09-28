import 'package:android_tile_launcher/model/styled_text.dart';

/// One page of Swedish Text TV as plain text. A page can be several [parts]
/// (sub-pages), each a grid of up to [TextTv.columns] characters per line.
class TextTvPage {
  const TextTvPage({
    required this.number,
    required this.parts,
    this.styledParts,
    this.previous,
    this.next,
  });

  final int number;

  /// Sub-pages in reading order; each is its lines, right-trimmed.
  final List<List<String>> parts;

  /// The same sub-pages with their colours, every row exactly
  /// [TextTv.columns] wide (not trimmed: a coloured bar runs to the edge).
  /// Null when the site sent no colours or they could not be read, in which
  /// case [parts] is all there is. When set it has as many parts as [parts].
  final List<List<List<StyledRun>>>? styledParts;

  /// Neighbouring page numbers, when the service says what they are.
  final int? previous;
  final int? next;
}

/// What the Text TV tile and viewer get back for a page: the page, or why
/// there is none to show. A failure carries a short, printable sentence.
sealed class TextTvResult {
  const TextTvResult();
}

class TextTvShown extends TextTvResult {
  const TextTvShown(this.page);

  final TextTvPage page;
}

/// The number is valid but not in broadcast.
class TextTvNotBroadcast extends TextTvResult {
  const TextTvNotBroadcast(this.number);

  final int number;
}

class TextTvFailed extends TextTvResult {
  const TextTvFailed(this.reason);

  final String reason;
}
