import 'dart:math' as math;

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/todo_item.dart';
import 'package:android_tile_launcher/services/todo_list.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key todoFieldKey = ValueKey<String>('todo-field');
const Key todoAddKey = ValueKey<String>('todo-add');
const Key todoCloseKey = ValueKey<String>('todo-close');
const Key todoSelectKey = ValueKey<String>('todo-select');
const Key todoMoveKey = ValueKey<String>('todo-move');
const Key todoSelectAllKey = ValueKey<String>('todo-select-all');
const Key todoCancelKey = ValueKey<String>('todo-cancel');
const Key todoDeleteKey = ValueKey<String>('todo-delete');
const Key todoYesKey = ValueKey<String>('todo-yes');
const Key todoNoKey = ValueKey<String>('todo-no');
const Key todoEditFieldKey = ValueKey<String>('todo-edit-field');
const Key todoSaveKey = ValueKey<String>('todo-save');
const Key todoEditCancelKey = ValueKey<String>('todo-edit-cancel');
const Key todoMoveDoneKey = ValueKey<String>('todo-move-done');
Key todoCheckKey(int id) => ValueKey<String>('todo-check-$id');
Key todoTitleKey(int id) => ValueKey<String>('todo-title-$id');
Key todoHandleKey(int id) => ValueKey<String>('todo-handle-$id');

/// What a tap on the to-do tile opens: the list, to add, check off, uncheck,
/// edit (tap a title), rearrange (MOVE) and delete (SELECT, then DELETE) to-dos.
Future<void> showTodoSheet(BuildContext context, {required TodoList todos}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) {
      final MediaQueryData media = MediaQuery.of(sheetContext);
      return SizedBox(
        height: math.min(
          media.size.height * 0.92,
          media.size.height - media.padding.top - TileMetrics.margin,
        ),
        child: _TodoSheet(todos: todos),
      );
    },
  );
}

class _TodoSheet extends StatefulWidget {
  const _TodoSheet({required this.todos});

  final TodoList todos;

  @override
  State<_TodoSheet> createState() => _TodoSheetState();
}

class _TodoSheetState extends State<_TodoSheet> {
  final TextEditingController _newField = TextEditingController();
  final TextEditingController _editField = TextEditingController();
  final FocusNode _editFocus = FocusNode();

  bool _selecting = false;
  bool _moving = false;
  bool _confirming = false;
  final Set<int> _selected = <int>{};
  int? _editing;

  @override
  void dispose() {
    _newField.dispose();
    _editField.dispose();
    _editFocus.dispose();
    super.dispose();
  }

  void _add() {
    final String title = _newField.text;
    if (title.trim().isEmpty) return;
    _newField.clear();
    widget.todos.add(title);
  }

  void _startEdit(TodoItem item) {
    setState(() => _editing = item.id);
    _editField.text = item.title;
    _editFocus.requestFocus();
  }

  void _saveEdit() {
    final int? id = _editing;
    if (id == null) return;
    widget.todos.rename(id, _editField.text);
    setState(() => _editing = null);
  }

  void _endModes() => setState(() {
    _selecting = false;
    _moving = false;
    _confirming = false;
    _selected.clear();
  });

  void _deleteSelected() {
    widget.todos.remove(_selected.toList());
    _endModes();
  }

  void _reorder(int oldIndex, int to) {
    if (to == oldIndex) return;
    widget.todos.move(oldIndex, to, after: to > oldIndex);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: TileMetrics.margin,
          right: TileMetrics.margin,
          top: TileMetrics.margin,
          bottom: TileMetrics.margin + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ListenableBuilder(
          listenable: widget.todos,
          builder: (BuildContext context, Widget? _) {
            final List<TodoItem> items = widget.todos.items;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: TileMetrics.gutter),
                _topRow(text, items),
                const SizedBox(height: TileMetrics.gutter),
                if (!_selecting && !_moving) _addRow(text),
                if (_moving)
                  Text(
                    Messages.todoMoveHint,
                    style: text.bodySmall?.copyWith(
                      fontSize: 10,
                      color: TileColors.muted,
                    ),
                  ),
                if (_confirming)
                  _ask(text)
                else if (_selecting)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PadKey(
                      key: todoDeleteKey,
                      label: Messages.todoDeleteSelected(_selected.length),
                      height: 36,
                      fontSize: 11,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      onTap: _selected.isEmpty
                          ? null
                          : () => setState(() => _confirming = true),
                    ),
                  ),
                const SizedBox(height: 4),
                Container(height: 2, color: TileColors.bezel),
                Expanded(
                  child: items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            Messages.todoEmpty,
                            style: text.bodyMedium,
                          ),
                        )
                      : _moving
                      ? ReorderableListView(
                          buildDefaultDragHandles: false,
                          onReorderItem: _reorder,
                          children: <Widget>[
                            for (final (int i, TodoItem item) in items.indexed)
                              _row(text, item, i),
                          ],
                        )
                      : ListView(
                          children: <Widget>[
                            for (final (int i, TodoItem item) in items.indexed)
                              _row(text, item, i),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _topRow(TextTheme text, List<TodoItem> items) {
    if (_selecting) {
      return Row(
        children: <Widget>[
          Expanded(
            child: Text(
              Messages.todoSelectedCount(_selected.length),
              style: text.bodyMedium?.copyWith(color: TileColors.textBright),
            ),
          ),
          _small(
            todoSelectAllKey,
            Messages.todoSelectAll,
            _selected.length == items.length
                ? null
                : () => setState(
                    () => _selected
                      ..clear()
                      ..addAll(items.map((TodoItem i) => i.id)),
                  ),
          ),
          const SizedBox(width: 8),
          _small(todoCancelKey, Messages.todoCancel, _endModes),
        ],
      );
    }
    if (_moving) {
      return Row(
        children: <Widget>[
          Expanded(
            child: Text(
              Messages.todoTitle,
              style: text.bodyMedium?.copyWith(color: TileColors.textBright),
            ),
          ),
          _small(todoMoveDoneKey, Messages.todoDone, _endModes),
        ],
      );
    }
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            Messages.todoTitle,
            style: text.bodyMedium?.copyWith(color: TileColors.textBright),
          ),
        ),
        _small(
          todoSelectKey,
          Messages.todoSelect,
          items.isEmpty ? null : () => setState(() => _selecting = true),
        ),
        const SizedBox(width: 8),
        _small(
          todoMoveKey,
          Messages.todoMove,
          items.length < 2 ? null : () => setState(() => _moving = true),
        ),
        const SizedBox(width: 8),
        _small(todoCloseKey, 'X', () => Navigator.of(context).pop()),
      ],
    );
  }

  Widget _small(Key key, String label, VoidCallback? onTap) => PadKey(
    key: key,
    label: label,
    height: 36,
    fontSize: 11,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    onTap: onTap,
  );

  Widget _addRow(TextTheme text) => Row(
    children: <Widget>[
      Expanded(
        child: TextField(
          key: todoFieldKey,
          controller: _newField,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (_) => _add(),
          style: text.bodySmall?.copyWith(
            fontSize: 12,
            color: TileColors.textBright,
          ),
          cursorColor: TileColors.textBright,
          decoration: InputDecoration(
            hintText: Messages.todoAddHint,
            hintStyle: text.bodySmall?.copyWith(
              fontSize: 12,
              color: TileColors.muted,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: TileColors.bezel),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: TileColors.textBright),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      _small(todoAddKey, Messages.todoAdd, _add),
    ],
  );

  Widget _ask(TextTheme text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          Messages.todoDeleteAsk(_selected.length),
          style: text.bodySmall?.copyWith(
            fontSize: 11,
            color: TileColors.textBright,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            _small(todoYesKey, Messages.todoYes, _deleteSelected),
            const SizedBox(width: 8),
            _small(
              todoNoKey,
              Messages.todoNo,
              () => setState(() => _confirming = false),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _row(TextTheme text, TodoItem item, int index) {
    final Color colour = item.done ? TileColors.muted : TileColors.textBright;
    final bool checked = _selecting ? _selected.contains(item.id) : item.done;
    final bool editing = _editing == item.id && !_selecting && !_moving;
    final Widget box = Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: checked ? TileColors.accent : Colors.transparent,
        border: Border.all(color: TileColors.bezel, width: TileMetrics.bevel),
      ),
      child: checked && !_selecting
          ? Text(
              'X',
              style: text.bodySmall?.copyWith(
                fontSize: 10,
                color: TileColors.canvas,
              ),
            )
          : null,
    );
    return Container(
      key: ValueKey<int>(item.id),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: TileColors.bezel)),
      ),
      child: Row(
        children: <Widget>[
          InkWell(
            key: todoCheckKey(item.id),
            onTap: _moving
                ? null
                : _selecting
                ? () => setState(() {
                    if (!_selected.remove(item.id)) _selected.add(item.id);
                  })
                : () => widget.todos.setDone(item.id, !item.done),
            child: Padding(padding: const EdgeInsets.all(6), child: box),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: editing
                ? Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          key: todoEditFieldKey,
                          controller: _editField,
                          focusNode: _editFocus,
                          onSubmitted: (_) => _saveEdit(),
                          style: text.bodySmall?.copyWith(
                            fontSize: 12,
                            color: TileColors.textBright,
                          ),
                          cursorColor: TileColors.textBright,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _small(todoSaveKey, Messages.todoSave, _saveEdit),
                      const SizedBox(width: 6),
                      _small(
                        todoEditCancelKey,
                        'X',
                        () => setState(() => _editing = null),
                      ),
                    ],
                  )
                : InkWell(
                    key: todoTitleKey(item.id),
                    onTap: _moving
                        ? null
                        : _selecting
                        ? () => setState(() {
                            if (!_selected.remove(item.id)) {
                              _selected.add(item.id);
                            }
                          })
                        : () => _startEdit(item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        item.title.toUpperCase(),
                        style: text.bodySmall?.copyWith(
                          fontSize: 12,
                          color: colour,
                          decoration: item.done
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: colour,
                        ),
                      ),
                    ),
                  ),
          ),
          if (_moving)
            ReorderableDragStartListener(
              key: todoHandleKey(item.id),
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '=',
                  style: text.bodyMedium?.copyWith(color: TileColors.accent),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
