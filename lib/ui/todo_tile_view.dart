import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/todo_item.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key todoMoreKey = ValueKey<String>('todo-tile-more');
Key todoTileRowKey(int id) => ValueKey<String>('todo-tile-row-$id');

/// The to-do tile's content: its name and as many to-dos as the tile has room
/// for, a done one with a checked box and a struck-through title. What does
/// not fit is counted in a `+N` on the last line. A tap ([onTap]) opens the
/// list; `null` in the grid editor, where a tap selects the tile.
class TodoTileContentView extends StatelessWidget {
  const TodoTileContentView({
    super.key,
    required this.items,
    required this.ink,
    this.onTap,
  });

  final List<TodoItem> items;
  final Color ink;
  final VoidCallback? onTap;

  static const double _header = 10;
  static const double _row = 9;
  static const double _rowHeight = 16;

  @override
  Widget build(BuildContext context) {
    final Widget body = SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.gutter / 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Rows are sized for the text at the user's font scale.
            final double k = MediaQuery.textScalerOf(context).scale(1);
            final double headerHeight = 18 * k;
            final double rowHeight = _rowHeight * k;
            final int lines =
                ((constraints.maxHeight - headerHeight) / rowHeight).floor();
            // A tile with no room for even a line is just its name.
            final ({int shown, int hidden}) fit = todoFit(items.length, lines);
            final bool room = lines >= 1;
            // Never scrolls: only absorbs a tile too short for even its name.
            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: headerHeight,
                    child: Text(
                      Messages.todoTitle,
                      style: _text(_header),
                      maxLines: 1,
                    ),
                  ),
                  if (room && items.isEmpty)
                    Text(Messages.todoEmpty, style: _text(_row))
                  else if (room) ...<Widget>[
                    for (final TodoItem item in items.take(fit.shown))
                      SizedBox(
                        key: todoTileRowKey(item.id),
                        height: rowHeight,
                        child: Row(
                          children: <Widget>[
                            Text(
                              item.done ? '[X] ' : '[ ] ',
                              style: _text(_row),
                            ),
                            Expanded(
                              child: Text(
                                item.title.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _text(_row).copyWith(
                                  decoration: item.done
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (fit.hidden > 0)
                      SizedBox(
                        height: rowHeight,
                        child: Text(
                          Messages.todoMore(fit.hidden),
                          key: todoMoreKey,
                          style: _text(_row),
                        ),
                      ),
                  ],
                ],
              ),
            );
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

  TextStyle _text(double size) =>
      TextStyle(fontFamily: kPixelFontFamily, fontSize: size, color: ink);
}
