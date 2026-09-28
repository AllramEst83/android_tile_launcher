import 'package:android_tile_launcher/model/alpha_grouping.dart';
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
/// whole strip to scrub through it — every row a finger passes over jumps in
/// turn, with a thin bar tracking the touch so a fast scrub still shows where
/// it is. Rows are [maxRowHeight] tall, or less when the strip has less room
/// than that (a sheet with the keyboard up), so every letter always fits.
class JumpIndex extends StatefulWidget {
  const JumpIndex({super.key, required this.initials, required this.onTap});

  static const double maxRowHeight = 20;

  final List<String> initials;
  final ValueChanged<int> onTap;

  @override
  State<JumpIndex> createState() => _JumpIndexState();
}

class _JumpIndexState extends State<JumpIndex> {
  int? _active;

  void _handleAt(double localY, double rowHeight) {
    final int index = (localY / rowHeight).floor().clamp(
      0,
      widget.initials.length - 1,
    );
    if (index == _active) return;
    setState(() => _active = index);
    widget.onTap(index);
  }

  void _release() => setState(() => _active = null);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double rowHeight = widget.initials.isEmpty
            ? JumpIndex.maxRowHeight
            : (constraints.maxHeight / widget.initials.length).clamp(
                0.0,
                JumpIndex.maxRowHeight,
              );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _handleAt(d.localPosition.dy, rowHeight),
          onTapUp: (_) => _release(),
          onTapCancel: _release,
          onVerticalDragStart: (d) => _handleAt(d.localPosition.dy, rowHeight),
          onVerticalDragUpdate: (d) => _handleAt(d.localPosition.dy, rowHeight),
          onVerticalDragEnd: (_) => _release(),
          child: SizedBox(
            width: 20,
            child: Stack(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    for (final (int i, String initial)
                        in widget.initials.indexed)
                      SizedBox(
                        height: rowHeight,
                        child: Center(
                          child: Text(
                            initial,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontSize: rowHeight < 14 ? 8 : 10,
                                  height: 1,
                                  color: i == _active
                                      ? C64.white
                                      : TileColors.textBright,
                                  fontWeight: i == _active
                                      ? FontWeight.bold
                                      : null,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (_active != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: _active! * rowHeight + rowHeight - 2,
                    child: Container(height: 2, color: TileColors.textBright),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
