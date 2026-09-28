import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/styled_text.dart';
import 'package:android_tile_launcher/model/text_tv_page.dart';
import 'package:android_tile_launcher/model/tv_layout.dart';
import 'package:android_tile_launcher/services/text_tv_repository.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tv_row.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key textTvCloseKey = ValueKey<String>('text-tv-close');
const Key textTvRefreshKey = ValueKey<String>('text-tv-refresh');
const Key textTvNumberKey = ValueKey<String>('text-tv-number');
const Key textTvPrevKey = ValueKey<String>('text-tv-prev');
const Key textTvNextKey = ValueKey<String>('text-tv-next');
const Key textTvPartPrevKey = ValueKey<String>('text-tv-part-prev');
const Key textTvPartNextKey = ValueKey<String>('text-tv-part-next');
const Key textTvRetryKey = ValueKey<String>('text-tv-retry');
const Key textTvDeleteKey = ValueKey<String>('text-tv-delete');
const Key textTvKeypadCloseKey = ValueKey<String>('text-tv-keypad-close');
Key textTvDigitKey(int digit) => ValueKey<String>('text-tv-digit-$digit');
Key textTvChipKey(int page) => ValueKey<String>('text-tv-chip-$page');

/// The pages people actually open, one tap away.
const List<(int, String)> textTvShortcuts = <(int, String)>[
  (100, 'NYHETER'),
  (101, 'INRIKES'),
  (104, 'UTRIKES'),
  (300, 'SPORT'),
  (400, 'VÄDER'),
  (700, 'INNEHÅLL'),
];

/// Text TV pages run from 100 to 899.
const int textTvFirstPage = 100;
const int textTvLastPage = 899;

/// Opens the Text TV viewer over the whole screen, like an app: [start]'s page
/// under a close button, with previous/next page, a number pad, shortcuts to
/// the pages people read, tappable page links, and swipes between the parts of
/// a page. The system back button steps back through the pages read, then
/// closes.
Future<void> showTextTv(
  BuildContext context, {
  required TextTvRepository repository,
  int start = textTvFirstPage,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (BuildContext context) =>
          TextTvScreen(repository: repository, start: start),
    ),
  );
}

class TextTvScreen extends StatefulWidget {
  const TextTvScreen({
    super.key,
    required this.repository,
    this.start = textTvFirstPage,
  });

  final TextTvRepository repository;
  final int start;

  @override
  State<TextTvScreen> createState() => _TextTvScreenState();
}

class _TextTvScreenState extends State<TextTvScreen> {
  late int _number = widget.start;
  int _part = 0;
  TextTvResult? _result;
  bool _loading = true;

  // The pages left behind, most recent last: what back returns to.
  final List<int> _history = <int>[];

  bool _keypad = false;
  String _typed = '';

  // Only the answer to the latest request counts; a slow one that was
  // overtaken by a newer tap must not replace it.
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load(_number);
  }

  Future<void> _load(int number, {bool fresh = false}) async {
    final int request = ++_request;
    setState(() {
      _number = number;
      _part = 0;
      _loading = true;
      _keypad = false;
      _typed = '';
    });
    final TextTvResult result = await widget.repository.page(
      number,
      fresh: fresh,
    );
    if (!mounted || request != _request) return;
    setState(() {
      _loading = false;
      _result = result;
    });
  }

  /// Goes to [number], remembering the page it leaves so back can return.
  void _open(int number) {
    if (number < textTvFirstPage || number > textTvLastPage) return;
    if (number == _number && !_loading && _result is TextTvShown) return;
    if (number != _number) _history.add(_number);
    _load(number);
  }

  void _back() {
    if (_keypad) {
      setState(() {
        _keypad = false;
        _typed = '';
      });
    } else if (_history.isNotEmpty) {
      _load(_history.removeLast());
    }
  }

  TextTvPage? get _page {
    final TextTvResult? result = _result;
    return result is TextTvShown ? result.page : null;
  }

  int? get _previous {
    final int number = _page?.previous ?? _number - 1;
    return number >= textTvFirstPage && number <= textTvLastPage
        ? number
        : null;
  }

  int? get _next {
    final int number = _page?.next ?? _number + 1;
    return number >= textTvFirstPage && number <= textTvLastPage
        ? number
        : null;
  }

  int get _parts => _page?.parts.length ?? 1;

  void _setPart(int part) {
    if (part < 0 || part >= _parts) return;
    setState(() => _part = part);
  }

  // A swipe left reads on (the next part, or past the last, the next page); a
  // swipe right goes back a part (or, from the first, to the previous page).
  void _swiped(double velocity) {
    if (velocity.abs() < 200) return;
    if (velocity < 0) {
      if (_part < _parts - 1) {
        _setPart(_part + 1);
      } else if (_next case final int next) {
        _open(next);
      }
    } else {
      if (_part > 0) {
        _setPart(_part - 1);
      } else if (_previous case final int previous) {
        _open(previous);
      }
    }
  }

  void _digit(int digit) {
    // A page number starts with 1 to 8.
    if (_typed.isEmpty && (digit < 1 || digit > 8)) return;
    final String typed = '$_typed$digit';
    if (typed.length == 3) {
      _open(int.parse(typed));
      return;
    }
    setState(() => _typed = typed);
  }

  void _deleteDigit() {
    if (_typed.isEmpty) return;
    setState(() => _typed = _typed.substring(0, _typed.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _history.isEmpty && !_keypad,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: TileColors.canvas,
        body: Column(
          children: <Widget>[
            _TopBar(
              onClose: () => Navigator.of(context).pop(),
              onRefresh: _loading ? null : () => _load(_number, fresh: true),
            ),
            Expanded(
              child: ColoredBox(
                color: C64.black,
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragEnd: (DragEndDetails d) =>
                            _swiped(d.primaryVelocity ?? 0),
                        child: _PageArea(
                          number: _number,
                          part: _part,
                          loading: _loading,
                          result: _result,
                          onLink: (String command) {
                            final int? page = int.tryParse(command);
                            if (page != null) _open(page);
                          },
                          onRetry: () => _load(_number, fresh: true),
                        ),
                      ),
                    ),
                    if (_parts > 1)
                      _PartBar(
                        part: _part,
                        parts: _parts,
                        onPrevious: _part > 0
                            ? () => _setPart(_part - 1)
                            : null,
                        onNext: _part < _parts - 1
                            ? () => _setPart(_part + 1)
                            : null,
                      ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(TileMetrics.gutter),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        _Button(
                          key: textTvPrevKey,
                          label: '<',
                          onTap: _previous == null
                              ? null
                              : () => _open(_previous!),
                        ),
                        const SizedBox(width: TileMetrics.gutter),
                        Expanded(
                          child: _NumberBox(
                            key: textTvNumberKey,
                            text: _keypad
                                ? _typed.padRight(3, '-')
                                : '$_number',
                            active: _keypad,
                            onTap: () => setState(() {
                              _keypad = !_keypad;
                              _typed = '';
                            }),
                          ),
                        ),
                        const SizedBox(width: TileMetrics.gutter),
                        _Button(
                          key: textTvNextKey,
                          label: '>',
                          onTap: _next == null ? null : () => _open(_next!),
                        ),
                      ],
                    ),
                    const SizedBox(height: TileMetrics.gutter),
                    if (_keypad)
                      _Keypad(
                        onDigit: _digit,
                        onDelete: _deleteDigit,
                        onClose: _back,
                      )
                    else
                      _Shortcuts(current: _number, onOpen: _open),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle _text(double size, Color colour) =>
    TextStyle(fontFamily: kPixelFontFamily, fontSize: size, color: colour);

/// The bar above the page: close on the left, where a thumb reaches back from,
/// the name, and REFRESH.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose, required this.onRefresh});

  final VoidCallback onClose;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.gutter),
        child: Row(
          children: <Widget>[
            _Button(key: textTvCloseKey, label: 'X', onTap: onClose),
            const SizedBox(width: TileMetrics.margin),
            Expanded(
              child: Text(
                Messages.textTvTitle,
                style: _text(14, TileColors.textBright),
              ),
            ),
            _Button(
              key: textTvRefreshKey,
              label: Messages.textTvRefresh,
              onTap: onRefresh,
            ),
          ],
        ),
      ),
    );
  }
}

/// The page itself, on its own black screen: coloured rows, or a word about why
/// there are none.
class _PageArea extends StatelessWidget {
  const _PageArea({
    required this.number,
    required this.part,
    required this.loading,
    required this.result,
    required this.onLink,
    required this.onRetry,
  });

  final int number;
  final int part;
  final bool loading;
  final TextTvResult? result;
  final ValueChanged<String> onLink;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final TextTvResult? shown = result;
        final Widget content;
        if (loading || shown == null) {
          content = _Message(lines: const <String>[Messages.textTvLoading]);
        } else {
          content = switch (shown) {
            TextTvShown(:final TextTvPage page) => _Grid(
              page: page,
              part: part,
              onLink: onLink,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            ),
            TextTvNotBroadcast(:final int number) => _Message(
              lines: <String>[Messages.textTvPageNotBroadcast(number)],
            ),
            TextTvFailed(:final String reason) => _Message(
              lines: <String>[reason.toUpperCase()],
              retry: onRetry,
            ),
          };
        }
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.lines, this.retry});

  final List<String> lines;
  final VoidCallback? retry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TileMetrics.margin * 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final String line in lines)
            Text(
              line,
              style: _text(10, C64.white),
              textAlign: TextAlign.center,
            ),
          if (retry != null) ...<Widget>[
            const SizedBox(height: TileMetrics.margin),
            _Button(
              key: textTvRetryKey,
              label: Messages.textTvTryAgain,
              onTap: retry,
            ),
          ],
        ],
      ),
    );
  }
}

/// The 40-column grid of one part of a page, drawn edge to edge with the text
/// centred between equal margins.
class _Grid extends StatelessWidget {
  const _Grid({
    required this.page,
    required this.part,
    required this.onLink,
    required this.width,
    required this.height,
  });

  final TextTvPage page;
  final int part;
  final ValueChanged<String> onLink;

  /// The room the page has, so its rows can be made tall enough to fill it.
  final double width;
  final double height;

  /// No row is drawn taller than this many cells: on a very tall screen the
  /// page stops growing and is centred instead.
  static const double _tallestRow = 3;

  @override
  Widget build(BuildContext context) {
    final int index = part.clamp(0, page.parts.length - 1);
    // The coloured version when the site sent one, else the plain text on the
    // same grid.
    final List<List<StyledRun>> rows =
        page.styledParts?[index] ??
        <List<StyledRun>>[
          for (final String line in page.parts[index])
            <StyledRun>[StyledRun(line.padRight(40))],
        ];
    final ({int left, int right}) gutters = tvGutters(rows, columns: 40);
    // Press Start 2P is a monospaced pixel face: every cell one square em. The
    // line height gives the rows their natural teletext proportions.
    const TextStyle style = TextStyle(
      fontFamily: kPixelFontFamily,
      fontSize: 8,
      height: 1.6,
    );

    // Spread the rows over the height there is: a headline row counts for two.
    // A screen too short for the natural row height scrolls instead.
    final double cell = tvCellWidth(width);
    final int units = rows.fold(
      0,
      (int sum, List<StyledRun> row) =>
          sum + (row.any((StyledRun r) => r.tall) ? 2 : 1),
    );
    final double rowHeight = units == 0
        ? cell * 1.6
        : (height / units).clamp(cell * 1.6, cell * _tallestRow);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final List<StyledRun> row in rows)
          TvRow(
            runs: row,
            columns: 40,
            style: style,
            gutterLeft: gutters.left,
            rowHeight: rowHeight,
            onRun: onLink,
          ),
      ],
    );
  }
}

/// `[<] PART 2/3 [>]` under a page that has several.
class _PartBar extends StatelessWidget {
  const _PartBar({
    required this.part,
    required this.parts,
    required this.onPrevious,
    required this.onNext,
  });

  final int part;
  final int parts;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TileMetrics.gutter),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _Button(key: textTvPartPrevKey, label: '<', onTap: onPrevious),
          const SizedBox(width: TileMetrics.margin),
          Text(
            '${Messages.textTvPart} ${part + 1}/$parts',
            style: _text(10, C64.white),
          ),
          const SizedBox(width: TileMetrics.margin),
          _Button(key: textTvPartNextKey, label: '>', onTap: onNext),
        ],
      ),
    );
  }
}

/// A bordered text button in the launcher's own look; a `null` [onTap] greys it.
class _Button extends StatelessWidget {
  const _Button({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color colour = onTap == null
        ? TileColors.textDim
        : TileColors.textBright;
    return InkWell(
      onTap: onTap,
      child: Container(
        // Big enough for a thumb, and to stay where a thumb expects it.
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: colour, width: TileMetrics.bevel),
        ),
        child: Text(label, style: _text(12, colour)),
      ),
    );
  }
}

/// The current page number, big; tap it to type another with the number pad.
class _NumberBox extends StatelessWidget {
  const _NumberBox({
    super.key,
    required this.text,
    required this.active,
    required this.onTap,
  });

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: active ? C64.yellow : TileColors.bezel,
            width: TileMetrics.bevel,
          ),
        ),
        child: Text(
          text,
          style: _text(20, active ? C64.yellow : TileColors.textBright),
        ),
      ),
    );
  }
}

/// Shortcuts to the pages people read, scrolling sideways.
class _Shortcuts extends StatelessWidget {
  const _Shortcuts({required this.current, required this.onOpen});

  final int current;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (final (int page, String name) in textTvShortcuts) ...<Widget>[
            InkWell(
              key: textTvChipKey(page),
              onTap: () => onOpen(page),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: page == current ? C64.yellow : TileColors.bezel,
                    width: TileMetrics.bevel,
                  ),
                ),
                child: Text(
                  '$page $name',
                  style: _text(
                    10,
                    page == current ? C64.yellow : TileColors.textBright,
                  ),
                ),
              ),
            ),
            const SizedBox(width: TileMetrics.gutter),
          ],
        ],
      ),
    );
  }
}

/// A number pad, like a remote's: 1 to 9, then DEL, 0, and a key that puts it
/// away. The third digit opens the page.
class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onDelete,
    required this.onClose,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    Widget key(Key key, String label, VoidCallback onTap) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: _Button(key: key, label: label, onTap: onTap),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final int row in <int>[0, 1, 2])
          Row(
            children: <Widget>[
              for (final int digit in <int>[
                row * 3 + 1,
                row * 3 + 2,
                row * 3 + 3,
              ])
                key(textTvDigitKey(digit), '$digit', () => onDigit(digit)),
            ],
          ),
        Row(
          children: <Widget>[
            key(textTvDeleteKey, 'DEL', onDelete),
            key(textTvDigitKey(0), '0', () => onDigit(0)),
            key(textTvKeypadCloseKey, 'X', onClose),
          ],
        ),
      ],
    );
  }
}
