import 'dart:math' as math;

import 'package:android_tile_launcher/model/alpha_grouping.dart';
import 'package:android_tile_launcher/ui/haptics.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// The jump index's own persistent "you are here" marker (see [JumpIndex]'s
/// `activeIndex`), so a test can find and measure it.
const Key jumpIndexActiveMarkerKey = ValueKey<String>('jump-index-active');

/// [items] filed under their initial the way a Swedish phone book does (A to Z,
/// then Å Ä Ö, `#` last: `model/alpha_grouping.dart`), a big letter above each
/// group and a jump index down the right edge. Shared by the app drawer and
/// the contact picker, so both read alike. [rowBuilder] draws one item.
class GroupedList<T> extends StatefulWidget {
  const GroupedList({
    super.key,
    required this.items,
    required this.label,
    required this.rowBuilder,
  });

  final List<T> items;

  /// What an item is filed by (an app's name, a contact's name).
  final String Function(T item) label;
  final Widget Function(BuildContext context, T item) rowBuilder;

  @override
  State<GroupedList<T>> createState() => _GroupedListState<T>();
}

class _GroupedListState<T> extends State<GroupedList<T>> {
  final ScrollController _scrollController = ScrollController();

  /// The group currently at the top of the list, from an ordinary scroll
  /// (not just a drag on the index itself) — drives the index's own
  /// persistent marker. `0` until the first scroll notification, the same
  /// group a fresh list opens on.
  int _activeIndex = 0;

  /// The groups as of the last build, for [_onScroll] to weigh scroll
  /// position against — a scroll notification can arrive between builds.
  List<InitialGroup<T>> _groups = <InitialGroup<T>>[];

  /// How tall a [SectionHeader] and a row actually render, as of the last
  /// build — [jumpFraction] and [groupIndexForFraction]'s weights, so the
  /// fraction they compute tracks real scroll position rather than counting
  /// every row the same regardless of how much of the list it actually
  /// takes. Measured, not guessed, so it still holds under a font-scale
  /// setting that changes both, and by a different amount.
  double _headerWeight = 1;
  double _itemWeight = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final ScrollPosition position = _scrollController.position;
    final double totalContent =
        position.maxScrollExtent + position.viewportDimension;
    if (totalContent <= 0) return;
    final int index = groupIndexForFraction(
      _groups,
      position.pixels / totalContent,
      headerWeight: _headerWeight,
      itemWeight: _itemWeight,
    );
    if (index != _activeIndex) setState(() => _activeIndex = index);
  }

  // Proportional, not a scroll-to-widget: with a long list most letters
  // haven't been built yet (ListView only builds what's near the viewport),
  // so there's no GlobalKey/context to scroll to. jumpFraction weighs each
  // group by how much of the list it actually holds, so a heavy letter (many
  // items) does not land the list on some other, lighter one. The fraction is
  // of the list's whole content height, not of the scrollable *range*
  // (`maxScrollExtent`, which is shorter by a viewport's worth) — multiplying
  // by `maxScrollExtent` instead, as an earlier version of this did, undershot
  // every jump by an amount that grew with how far down the list the target
  // letter actually was, which read as the marker drifting out of sync with
  // the list the further down the alphabet a scrub went.
  void _jumpToIndex(int index, List<InitialGroup<T>> groups) {
    if (!_scrollController.hasClients) return;
    final ScrollPosition position = _scrollController.position;
    final double fraction = jumpFraction(
      groups,
      index,
      headerWeight: _headerWeight,
      itemWeight: _itemWeight,
    );
    final double totalContent =
        position.maxScrollExtent + position.viewportDimension;
    position.jumpTo(
      (totalContent * fraction).clamp(0.0, position.maxScrollExtent),
    );
  }

  /// A single character's rendered height in [style], at the current
  /// font-scale setting — [_headerWeight] and [_itemWeight]'s unit.
  static double _lineHeight(BuildContext context, TextStyle? style) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: 'M', style: style),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: TextDirection.ltr,
    )..layout();
    final double height = painter.height;
    painter.dispose();
    return height;
  }

  void _measureWeights(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    // Mirrors SectionHeader's own padding: gutter*2 above, gutter below.
    _headerWeight =
        TileMetrics.gutter * 3 + _lineHeight(context, text.headlineMedium);
    // Mirrors an app/contact row's own padding (gutter above and below) and
    // its `minHeight: 48` floor, which is what actually renders while the
    // row's own text stays shorter than that floor.
    _itemWeight = math.max(
      48.0,
      _lineHeight(context, text.bodyMedium) + TileMetrics.gutter * 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<InitialGroup<T>> groups = groupByInitial(
      widget.items,
      widget.label,
    );
    _groups = groups;
    _measureWeights(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ListView(
            controller: _scrollController,
            children: <Widget>[
              for (final InitialGroup<T> group in groups) ...<Widget>[
                SectionHeader(initial: group.initial),
                for (final T item in group.items)
                  widget.rowBuilder(context, item),
              ],
            ],
          ),
        ),
        JumpIndex(
          key: const Key('jump-index'),
          initials: <String>[for (final InitialGroup<T> g in groups) g.initial],
          activeIndex: groups.isEmpty ? null : _activeIndex,
          onTap: (int index) => _jumpToIndex(index, groups),
        ),
      ],
    );
  }
}

/// The big letter above a group.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TileMetrics.margin,
        TileMetrics.gutter * 2,
        TileMetrics.margin,
        TileMetrics.gutter,
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(color: TileColors.textDim),
      ),
    );
  }
}

/// A–Z down the right edge: tap a letter to jump, or drag up and down the
/// strip to scrub through it — every letter a finger passes over jumps in turn,
/// with a light tick, a thin bar tracking the touch, and a wave: the letters
/// near the finger bulge out to the left and grow, and settle back when it lifts.
///
/// The letters fill the middle [usedFraction] of the height the strip is given
/// (15% empty above and below), up to [maxRowHeight] a letter, so they sit
/// clear of the corners of the screen. A short strip (a sheet with the keyboard
/// up) would make them tiny, so it uses more of its height, down to
/// [minRowHeight] a letter, and if even that does not fit, all of it.
///
/// At rest the letters keep [edgeMargin] clear of the screen's edge. While a
/// finger is down the whole strip slides [pushOut] to the left, out from under
/// the finger, and back when it lifts.
///
/// [activeIndex], when given, draws a second, persistent bordered marker
/// around that letter — where the list actually is right now, from an
/// ordinary scroll, not only the last letter a drag on the strip landed on
/// (the thin underline above, which only appears while touched). Hidden while
/// a finger is down: the touched letters themselves swing out and grow, so a
/// box drawn at their untransformed row would no longer sit around them.
class JumpIndex extends StatefulWidget {
  const JumpIndex({
    super.key,
    required this.initials,
    required this.onTap,
    this.activeIndex,
  });

  /// The tallest a letter's row is, however much room there is.
  static const double maxRowHeight = 44;

  /// How much of the height the letters take, centred: 15% clear at each end.
  static const double usedFraction = 0.7;

  /// The least a row is made before the strip stops sparing its ends.
  static const double minRowHeight = 14;

  /// How far the strip slides out from under the finger while it is touched.
  static const double pushOut = 44;

  /// The room left between the letters and the edge of the screen at rest (the
  /// touch area still reaches the edge).
  static const double edgeMargin = 12;

  /// How wide the column of letters is (the wave swings out past it, to the
  /// left); the strip is [edgeMargin] wider, on its right.
  static const double width = 24;

  /// How many letters either side of the finger take part in the wave, how far
  /// the nearest one swings out, and how much bigger it grows.
  static const int waveReach = 5;
  static const double waveSwing = 22;
  static const double waveGrowth = 1.0;

  /// How far, up or down, the letters either side of the finger are pushed
  /// apart at most, so the ones under it have room to grow.
  static const double waveSpread = 6;

  final List<String> initials;
  final ValueChanged<int> onTap;
  final int? activeIndex;

  @override
  State<JumpIndex> createState() => _JumpIndexState();
}

class _JumpIndexState extends State<JumpIndex>
    with SingleTickerProviderStateMixin {
  int? _active;

  // The letter last jumped to and ticked for, kept until the finger really
  // lifts: a tap that turns into a drag is "cancelled" and the drag starts on
  // the same letter, which must not jump and tick a second time.
  int? _reached;

  // Where along the letters the finger is, as a fractional index, so the wave
  // slides smoothly between letters rather than stepping.
  double _position = 0;

  // 0 at rest, 1 with a finger down: eases the wave in and out.
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 220),
  );

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  void _handleAt(double localY, double top, double rowHeight) {
    final int count = widget.initials.length;
    if (count == 0) return;
    final double row = (localY - top) / rowHeight;
    final int index = row.floor().clamp(0, count - 1);
    setState(() => _position = (row - 0.5).clamp(0.0, count - 1.0));
    _wave.forward();
    setState(() => _active = index);
    if (index == _reached) return;
    _reached = index;
    haptic(context, Haptic.tick);
    widget.onTap(index);
  }

  void _release() {
    _wave.reverse();
    setState(() => _active = null);
  }

  void _lift() {
    _reached = null;
    _release();
  }

  /// How much of the wave the letter at [index] takes: 1 under the finger,
  /// easing to 0 [JumpIndex.waveReach] letters away.
  double _weight(int index) {
    final double distance = (index - _position).abs();
    if (distance >= JumpIndex.waveReach) return 0;
    final double c = math.cos(distance / JumpIndex.waveReach * math.pi / 2);
    return c * c;
  }

  /// Up or down the letter at [index] is pushed apart from the finger, before
  /// the wave's strength is applied: nothing under it or at the reach's end,
  /// most about half way, and away from the finger on each side.
  double _spread(int index) {
    final double away = index - _position;
    if (away.abs() >= JumpIndex.waveReach) return 0;
    return JumpIndex.waveSpread *
        math.sin(away / JumpIndex.waveReach * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int count = widget.initials.length;
        final double rowHeight = count == 0
            ? JumpIndex.maxRowHeight
            : (constraints.maxHeight * JumpIndex.usedFraction / count).clamp(
                math.min(constraints.maxHeight / count, JumpIndex.minRowHeight),
                JumpIndex.maxRowHeight,
              );
        // Centred in what is left over.
        final double top = ((constraints.maxHeight - rowHeight * count) / 2)
            .clamp(0.0, double.infinity);
        final double fontSize = (rowHeight * 0.55).clamp(8.0, 12.0);
        return Listener(
          // Every new touch starts afresh, whatever became of the last.
          onPointerDown: (_) => _reached = null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // A scrub starts on the letter the finger landed on, not the one it
            // had reached by the time it had moved far enough to count as a drag.
            dragStartBehavior: DragStartBehavior.down,
            onTapDown: (d) => _handleAt(d.localPosition.dy, top, rowHeight),
            onTapUp: (_) => _lift(),
            onTapCancel: _release,
            onVerticalDragStart: (d) =>
                _handleAt(d.localPosition.dy, top, rowHeight),
            onVerticalDragUpdate: (d) =>
                _handleAt(d.localPosition.dy, top, rowHeight),
            onVerticalDragEnd: (_) => _lift(),
            child: SizedBox(
              width: JumpIndex.width + JumpIndex.edgeMargin,
              child: AnimatedBuilder(
                animation: _wave,
                builder: (BuildContext context, Widget? _) => Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Positioned(
                      left:
                          -JumpIndex.pushOut *
                          Curves.easeOut.transform(_wave.value),
                      right:
                          JumpIndex.pushOut *
                              Curves.easeOut.transform(_wave.value) +
                          JumpIndex.edgeMargin,
                      top: top,
                      child: Column(
                        children: <Widget>[
                          for (final (int i, String initial)
                              in widget.initials.indexed)
                            SizedBox(
                              height: rowHeight,
                              child: _Letter(
                                initial: initial,
                                fontSize: fontSize,
                                wave: _weight(i) * _wave.value,
                                spread: _spread(i) * _wave.value,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.activeIndex != null &&
                        widget.activeIndex! >= 0 &&
                        widget.activeIndex! < count &&
                        _active == null)
                      Positioned(
                        key: jumpIndexActiveMarkerKey,
                        left:
                            -JumpIndex.pushOut *
                            Curves.easeOut.transform(_wave.value),
                        right:
                            JumpIndex.pushOut *
                                Curves.easeOut.transform(_wave.value) +
                            JumpIndex.edgeMargin,
                        top: top + widget.activeIndex! * rowHeight,
                        child: IgnorePointer(
                          child: Container(
                            height: rowHeight,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: TileColors.textBright,
                                width: TileMetrics.bevel,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_active != null)
                      Positioned(
                        left:
                            -JumpIndex.pushOut *
                            Curves.easeOut.transform(_wave.value),
                        right:
                            JumpIndex.pushOut *
                                Curves.easeOut.transform(_wave.value) +
                            JumpIndex.edgeMargin,
                        top: top + _active! * rowHeight + rowHeight - 2,
                        child: Container(
                          height: 2,
                          color: TileColors.textBright,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One letter of the strip, swung out to the left, grown, pushed off its row
/// and coloured by [wave] (0 to 1).
class _Letter extends StatelessWidget {
  const _Letter({
    required this.initial,
    required this.fontSize,
    required this.wave,
    required this.spread,
  });

  final String initial;
  final double fontSize;
  final double wave;

  /// How far up (negative) or down it is pushed off its row.
  final double spread;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: Offset(-JumpIndex.waveSwing * wave, spread),
        child: Transform.scale(
          scale: 1 + JumpIndex.waveGrowth * wave,
          child: Text(
            initial,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: fontSize,
              height: 1,
              // Warms to the accent colour under the finger.
              color: Color.lerp(
                TileColors.textBright,
                TileColors.accent,
                wave * wave,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
