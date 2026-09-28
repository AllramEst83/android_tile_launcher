import 'dart:math' as math;

import 'package:android_tile_launcher/model/alpha_grouping.dart';
import 'package:android_tile_launcher/ui/haptics.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Proportional, not a scroll-to-widget: with a long list most letters
  // haven't been built yet (ListView only builds what's near the viewport),
  // so there's no GlobalKey/context to scroll to. A fraction of
  // maxScrollExtent works everywhere and tracks a drag 1:1.
  void _jumpToIndex(int index, int count) {
    if (!_scrollController.hasClients) return;
    final ScrollPosition position = _scrollController.position;
    final double fraction = count <= 1 ? 0 : index / (count - 1);
    position.jumpTo(
      (position.maxScrollExtent * fraction).clamp(
        0.0,
        position.maxScrollExtent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<InitialGroup<T>> groups = groupByInitial(
      widget.items,
      widget.label,
    );
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
          onTap: (int index) => _jumpToIndex(index, groups.length),
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
/// The letters are spread over the whole height the strip is given, so a tall
/// screen gets a tall strip, up to [maxRowHeight] a letter (a list with only a
/// few initials sits in the middle rather than being stretched silly); a short
/// strip (a sheet with the keyboard up) squeezes them so every letter fits.
class JumpIndex extends StatefulWidget {
  const JumpIndex({super.key, required this.initials, required this.onTap});

  /// The tallest a letter's row is, however much room there is.
  static const double maxRowHeight = 44;

  /// How wide the strip is (the wave swings out past it, to the left).
  static const double width = 24;

  /// How many letters either side of the finger take part in the wave, how far
  /// the nearest one swings out, and how much bigger it grows.
  static const int waveReach = 4;
  static const double waveSwing = 16;
  static const double waveGrowth = 0.7;

  final List<String> initials;
  final ValueChanged<int> onTap;

  @override
  State<JumpIndex> createState() => _JumpIndexState();
}

class _JumpIndexState extends State<JumpIndex>
    with SingleTickerProviderStateMixin {
  int? _active;

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
    if (index == _active) return;
    setState(() => _active = index);
    haptic(context, Haptic.tick);
    widget.onTap(index);
  }

  void _release() {
    _wave.reverse();
    setState(() => _active = null);
  }

  /// How much of the wave the letter at [index] takes: 1 under the finger,
  /// easing to 0 [JumpIndex.waveReach] letters away.
  double _weight(int index) {
    final double distance = (index - _position).abs();
    if (distance >= JumpIndex.waveReach) return 0;
    final double c = math.cos(distance / JumpIndex.waveReach * math.pi / 2);
    return c * c;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int count = widget.initials.length;
        final double rowHeight = count == 0
            ? JumpIndex.maxRowHeight
            : (constraints.maxHeight / count).clamp(
                0.0,
                JumpIndex.maxRowHeight,
              );
        // Centred in what is left over.
        final double top = ((constraints.maxHeight - rowHeight * count) / 2)
            .clamp(0.0, double.infinity);
        final double fontSize = (rowHeight * 0.55).clamp(8.0, 12.0);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _handleAt(d.localPosition.dy, top, rowHeight),
          onTapUp: (_) => _release(),
          onTapCancel: _release,
          onVerticalDragStart: (d) =>
              _handleAt(d.localPosition.dy, top, rowHeight),
          onVerticalDragUpdate: (d) =>
              _handleAt(d.localPosition.dy, top, rowHeight),
          onVerticalDragEnd: (_) => _release(),
          child: SizedBox(
            width: JumpIndex.width,
            child: AnimatedBuilder(
              animation: _wave,
              builder: (BuildContext context, Widget? _) => Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: 0,
                    right: 0,
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
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_active != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: top + _active! * rowHeight + rowHeight - 2,
                      child: Container(height: 2, color: TileColors.textBright),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One letter of the strip, swung out to the left and grown by [wave] (0 to 1).
class _Letter extends StatelessWidget {
  const _Letter({
    required this.initial,
    required this.fontSize,
    required this.wave,
  });

  final String initial;
  final double fontSize;
  final double wave;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: Offset(-JumpIndex.waveSwing * wave, 0),
        child: Transform.scale(
          scale: 1 + JumpIndex.waveGrowth * wave,
          child: Text(
            initial,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: fontSize,
              height: 1,
              color: TileColors.textBright,
            ),
          ),
        ),
      ),
    );
  }
}
