import 'dart:async';

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/byte_format.dart';
import 'package:android_tile_launcher/model/file_entry.dart';
import 'package:android_tile_launcher/model/file_filter.dart';
import 'package:android_tile_launcher/model/file_format.dart';
import 'package:android_tile_launcher/services/files_service.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/ui/file_icons.dart';
import 'package:android_tile_launcher/ui/files_filter_sheet.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key filesAllowKey = ValueKey<String>('files-allow');
const Key filesCloseKey = ValueKey<String>('files-close');
const Key filesAskKey = ValueKey<String>('files-ask');
const Key filesYesKey = ValueKey<String>('files-yes');
const Key filesNoKey = ValueKey<String>('files-no');
Key filesRowKey(String path) => ValueKey<String>('files-row-$path');
Key filesDeleteKey(String path) => ValueKey<String>('files-delete-$path');
Key filesCrumbKey(String? path) =>
    ValueKey<String>('files-crumb-${path ?? 'root'}');
const Key filesSearchKey = ValueKey<String>('files-search');
const Key filesFilterKey = ValueKey<String>('files-filter');
Key filesFilterChipKey(String field) =>
    ValueKey<String>('files-filter-chip-$field');
Key filesSortHeaderKey(FileSortKey key) =>
    ValueKey<String>('files-sort-${key.name}');
const Key filesSelectKey = ValueKey<String>('files-select');
const Key filesSelectAllKey = ValueKey<String>('files-select-all');
const Key filesCancelSelectKey = ValueKey<String>('files-cancel-select');
Key filesCheckboxKey(String path) => ValueKey<String>('files-checkbox-$path');
const Key filesBulkDeleteKey = ValueKey<String>('files-bulk-delete');
const Key filesBulkYesKey = ValueKey<String>('files-bulk-yes');
const Key filesBulkNoKey = ValueKey<String>('files-bulk-no');

const double _modifiedColumnWidth = 60;
const double _sizeColumnWidth = 56;
const double _actionsColumnWidth = 36;
const double _checkboxColumnWidth = 26;

/// What a tap on the files tile opens: every storage volume on the phone
/// (internal, an SD card, …), browsed one level at a time like an ordinary
/// file tree in a sortable, filterable grid, each entry deletable (one at a
/// time or in bulk) — the way Android's own Files app works, once "all files
/// access" is granted.
Future<void> showFilesSheet(
  BuildContext context, {
  required FilesService service,
  required SettingsState settings,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    // Laid out below the status bar.
    useSafeArea: true,
    builder: (BuildContext sheetContext) =>
        _FilesSheet(service: service, settings: settings),
  );
}

class _FilesSheetState extends State<_FilesSheet> {
  bool _loading = true;
  bool _hasAccess = false;

  /// `null` path is the top-level list of storage volumes; otherwise the
  /// absolute path of the folder currently open. The chain from the root to
  /// the level currently open (inclusive), so the breadcrumb can jump back
  /// several levels in one tap rather than one `< BACK` at a time.
  String? _path;
  final List<({String? path, String name})> _crumbs =
      <({String? path, String name})>[(path: null, name: Messages.filesRoot)];

  FilesResult? _result;
  FileEntry? _pendingDelete;
  String? _error;
  String? _status;

  FileFilter _filter = const FileFilter();
  late final TextEditingController _search;

  late FileSortKey _sortKey;
  late bool _sortAscending;

  bool _selecting = false;
  final Set<String> _selected = <String>{};
  bool _confirmingBulkDelete = false;
  bool _bulkDeleting = false;
  int _bulkDone = 0;
  int _bulkTotal = 0;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
    _sortKey = widget.settings.settings.fileSortKey;
    _sortAscending = widget.settings.settings.fileSortAscending;
    unawaited(_init());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final bool has = await widget.service.hasAccess();
    if (!mounted) return;
    setState(() {
      _hasAccess = has;
      _loading = false;
    });
    if (has) unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _result = null);
    final String? path = _path;
    final FilesResult result = path == null
        ? await widget.service.roots()
        : await widget.service.list(path);
    if (!mounted) return;
    setState(() {
      _result = result;
      if (result is FilesNoAccess) _hasAccess = false;
    });
  }

  Future<void> _allow() async {
    final AccessResult result = await widget.service.requestAccess();
    if (!mounted) return;
    switch (result) {
      case AccessGranted():
        setState(() {
          _hasAccess = true;
          _error = null;
        });
        unawaited(_load());
      case AccessDenied():
        break;
    }
  }

  void _open(FileEntry entry) {
    if (!entry.isDirectory) return;
    setState(() {
      _crumbs.add((path: entry.path, name: entry.name.toUpperCase()));
      _path = entry.path;
      _pendingDelete = null;
      _selecting = false;
      _selected.clear();
    });
    unawaited(_load());
  }

  void _crumbTap(int index) {
    if (index == _crumbs.length - 1) return;
    setState(() {
      _crumbs.removeRange(index + 1, _crumbs.length);
      _path = _crumbs.last.path;
      _pendingDelete = null;
      _selecting = false;
      _selected.clear();
    });
    unawaited(_load());
  }

  void _askDelete(FileEntry entry) => setState(() => _pendingDelete = entry);

  void _cancelDelete() => setState(() => _pendingDelete = null);

  Future<void> _confirmDelete() async {
    final FileEntry entry = _pendingDelete!;
    setState(() => _pendingDelete = null);
    final DeleteResult result = await widget.service.delete(entry.path);
    if (!mounted) return;
    if (result is DeleteFailed) {
      setState(() => _error = Messages.filesDeleteFailed);
    }
    unawaited(_load());
  }

  void _startSelecting() => setState(() {
    _selecting = true;
    _selected.clear();
  });

  void _cancelSelecting() => setState(() {
    _selecting = false;
    _selected.clear();
    _confirmingBulkDelete = false;
  });

  void _toggleSelected(String path) => setState(() {
    if (!_selected.remove(path)) _selected.add(path);
  });

  void _selectAll(List<FileEntry> entries) => setState(() {
    _selected
      ..clear()
      ..addAll(entries.map((FileEntry e) => e.path));
  });

  Future<void> _bulkDelete() async {
    final List<String> paths = _selected.toList();
    setState(() {
      _confirmingBulkDelete = false;
      _bulkDeleting = true;
      _bulkDone = 0;
      _bulkTotal = paths.length;
      _error = null;
      _status = null;
    });
    int deleted = 0;
    for (final String path in paths) {
      final DeleteResult result = await widget.service.delete(path);
      if (!mounted) return;
      if (result is DeleteSucceeded) deleted++;
      setState(() => _bulkDone++);
    }
    if (!mounted) return;
    setState(() {
      _bulkDeleting = false;
      _selecting = false;
      _selected.clear();
      _status = Messages.filesBulkDeleted(deleted);
    });
    await _load();
  }

  void _tapSort(FileSortKey key) {
    setState(() {
      if (_sortKey == key) {
        _sortAscending = !_sortAscending;
      } else {
        _sortKey = key;
        // NAME reads naturally A-Z; MODIFIED and SIZE read naturally
        // biggest/newest first.
        _sortAscending = key == FileSortKey.name;
      }
    });
    unawaited(
      widget.settings.update(
        widget.settings.settings.copyWith(
          fileSortKey: _sortKey,
          fileSortAscending: _sortAscending,
        ),
      ),
    );
  }

  void _onSearchChanged(String value) => setState(() {
    _filter = FileFilter(text: value, type: _filter.type, age: _filter.age);
  });

  Future<void> _openFilter() async {
    final FileFilter? next = await showFilesFilterSheet(
      context,
      initial: _filter,
    );
    if (next == null) return;
    setState(() {
      _filter = next;
      _search.text = next.text;
    });
  }

  void _clearFilterField(FileFilter Function(FileFilter) without) {
    setState(() {
      _filter = without(_filter);
      _search.text = _filter.text;
    });
  }

  List<FileEntry> _visible(List<FileEntry> raw) {
    final List<FileEntry> filtered = applyFileFilter(
      raw,
      _filter,
      now: DateTime.now(),
    );
    return sortFiles(filtered, key: _sortKey, ascending: _sortAscending);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // So the title row is not flush against the sheet's own top edge.
            const SizedBox(height: TileMetrics.gutter),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _selecting
                        ? Messages.filesSelectedCount(_selected.length)
                        : Messages.filesTitle,
                    style: text.bodyMedium,
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: PadKey(
                    key: filesCloseKey,
                    label: 'X',
                    height: 32,
                    fontSize: 12,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TileMetrics.margin),
            if (_error != null) ...<Widget>[
              Text(
                _error!,
                style: text.bodySmall?.copyWith(color: TileColors.accent),
              ),
              const SizedBox(height: TileMetrics.gutter),
            ],
            if (_status != null) ...<Widget>[
              Text(
                _status!,
                style: text.bodySmall?.copyWith(color: TileColors.highlight),
              ),
              const SizedBox(height: TileMetrics.gutter),
            ],
            Flexible(child: _body(text)),
          ],
        ),
      ),
    );
  }

  Widget _body(TextTheme text) {
    if (_loading) {
      return Text(Messages.filesLoading, style: text.bodyMedium);
    }
    if (!_hasAccess) {
      return PadKey(
        key: filesAllowKey,
        label: Messages.filesTapToAllow,
        height: 48,
        fontSize: 12,
        onTap: _allow,
      );
    }
    final FileEntry? pending = _pendingDelete;
    if (pending != null) {
      return _DeleteAsk(
        entry: pending,
        onYes: _confirmDelete,
        onNo: _cancelDelete,
      );
    }
    if (_confirmingBulkDelete) {
      return _BulkDeleteAsk(
        count: _selected.length,
        onYes: _bulkDelete,
        onNo: () => setState(() => _confirmingBulkDelete = false),
      );
    }
    final FilesResult? result = _result;
    if (result == null) {
      return Text(Messages.filesLoading, style: text.bodyMedium);
    }
    return switch (result) {
      FilesListed(:final List<FileEntry> entries) => _listing(text, entries),
      FilesNoAccess() => PadKey(
        key: filesAllowKey,
        label: Messages.filesTapToAllow,
        height: 48,
        fontSize: 12,
        onTap: _allow,
      ),
      FilesUnavailable(:final String reason) => Text(
        reason.toUpperCase(),
        style: text.bodyMedium,
      ),
    };
  }

  Widget _listing(TextTheme text, List<FileEntry> raw) {
    final List<FileEntry> visible = _visible(raw);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_crumbs.length > 1) ...<Widget>[
          _breadcrumb(text),
          const SizedBox(height: TileMetrics.gutter),
        ],
        if (_bulkDeleting) ...<Widget>[
          Text(
            Messages.filesBulkDeleting(_bulkDone, _bulkTotal),
            style: text.bodyMedium,
          ),
          const SizedBox(height: TileMetrics.gutter),
        ] else if (_selecting) ...<Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              PadKey(
                key: filesSelectAllKey,
                label: Messages.filesSelectAll,
                height: 32,
                fontSize: 10,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                onTap: _selected.length == visible.length
                    ? null
                    : () => _selectAll(visible),
              ),
              PadKey(
                key: filesCancelSelectKey,
                label: Messages.filesCancelSelect,
                height: 32,
                fontSize: 10,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                onTap: _cancelSelecting,
              ),
              PadKey(
                key: filesBulkDeleteKey,
                label: Messages.filesDeleteSelected(_selected.length),
                height: 32,
                fontSize: 10,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                onTap: _selected.isEmpty
                    ? null
                    : () => setState(() => _confirmingBulkDelete = true),
              ),
            ],
          ),
          const SizedBox(height: TileMetrics.gutter),
        ] else ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: filesSearchKey,
                  controller: _search,
                  onChanged: _onSearchChanged,
                  style: text.bodySmall?.copyWith(
                    fontSize: 11,
                    color: TileColors.textBright,
                  ),
                  cursorColor: TileColors.textBright,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: Messages.filesSearch,
                    hintStyle: text.bodySmall?.copyWith(
                      fontSize: 11,
                      color: TileColors.muted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
              PadKey(
                key: filesFilterKey,
                label: Messages.filesFilter,
                height: 32,
                fontSize: 10,
                selected: !_filter.isEmpty,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                onTap: _openFilter,
              ),
              if (_path != null) ...<Widget>[
                const SizedBox(width: 8),
                PadKey(
                  key: filesSelectKey,
                  label: Messages.filesSelect,
                  height: 32,
                  fontSize: 10,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  onTap: raw.isEmpty ? null : _startSelecting,
                ),
              ],
            ],
          ),
          if (!_filter.isEmpty) ...<Widget>[
            const SizedBox(height: TileMetrics.gutter),
            _filterChips(),
          ],
          const SizedBox(height: TileMetrics.gutter),
        ],
        if (visible.isEmpty)
          Text(
            raw.isEmpty ? Messages.filesEmpty : Messages.filesNoMatches,
            style: text.bodyMedium,
          )
        else ...<Widget>[
          _columnHeader(text),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                for (final FileEntry entry in visible)
                  _FileRow(
                    entry: entry,
                    selecting: _selecting,
                    selected: _selected.contains(entry.path),
                    onOpen: () => _open(entry),
                    onToggleSelect: () => _toggleSelected(entry.path),
                    // Deleting a whole storage volume makes no sense; only
                    // offered once inside one, and not while bulk-selecting.
                    onDelete: _path == null || _selecting
                        ? null
                        : () => _askDelete(entry),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _breadcrumb(TextTheme text) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (final (int i, ({String? path, String name}) crumb)
              in _crumbs.indexed) ...<Widget>[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '>',
                  style: text.bodySmall?.copyWith(color: TileColors.muted),
                ),
              ),
            InkWell(
              key: filesCrumbKey(crumb.path),
              onTap: () => _crumbTap(i),
              child: Text(
                crumb.name,
                style: text.bodySmall?.copyWith(
                  fontSize: 11,
                  color: i == _crumbs.length - 1
                      ? TileColors.textBright
                      : TileColors.muted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _columnHeader(TextTheme text) {
    TextStyle? styleFor(FileSortKey key) => text.bodySmall?.copyWith(
      fontSize: 9,
      color: _sortKey == key ? TileColors.textBright : TileColors.muted,
    );
    String labelFor(FileSortKey key) {
      final String arrow = _sortAscending ? '▲' : '▼';
      return _sortKey == key ? '${key.label} $arrow' : key.label;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          if (_selecting) const SizedBox(width: _checkboxColumnWidth + 8),
          const SizedBox(width: 16 + 8), // the icon's own column
          Expanded(
            child: InkWell(
              key: filesSortHeaderKey(FileSortKey.name),
              onTap: () => _tapSort(FileSortKey.name),
              child: Text(
                labelFor(FileSortKey.name),
                style: styleFor(FileSortKey.name),
              ),
            ),
          ),
          SizedBox(
            width: _modifiedColumnWidth,
            child: InkWell(
              key: filesSortHeaderKey(FileSortKey.modified),
              onTap: () => _tapSort(FileSortKey.modified),
              child: Text(
                labelFor(FileSortKey.modified),
                style: styleFor(FileSortKey.modified),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          SizedBox(
            width: _sizeColumnWidth,
            child: InkWell(
              key: filesSortHeaderKey(FileSortKey.size),
              onTap: () => _tapSort(FileSortKey.size),
              child: Text(
                labelFor(FileSortKey.size),
                style: styleFor(FileSortKey.size),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          if (!_selecting) const SizedBox(width: _actionsColumnWidth),
        ],
      ),
    );
  }

  Widget _filterChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        if (_filter.text.isNotEmpty)
          _FilterChip(
            key: filesFilterChipKey('text'),
            label: Messages.filesFilterTextChip(_filter.text),
            onRemove: () =>
                _clearFilterField((FileFilter f) => f.withoutText()),
          ),
        if (_filter.type != null)
          _FilterChip(
            key: filesFilterChipKey('type'),
            label: Messages.filesFilterTypeChip(_filter.type!.label),
            onRemove: () =>
                _clearFilterField((FileFilter f) => f.withoutType()),
          ),
        if (_filter.age != null)
          _FilterChip(
            key: filesFilterChipKey('age'),
            label: Messages.filesFilterAgeChip(
              _filter.age!.direction == FileAgeDirection.older,
              _filter.age!.amount,
              _filter.age!.unit.label,
            ),
            onRemove: () => _clearFilterField((FileFilter f) => f.withoutAge()),
          ),
      ],
    );
  }
}

class _FilesSheet extends StatefulWidget {
  const _FilesSheet({required this.service, required this.settings});

  final FilesService service;
  final SettingsState settings;

  @override
  State<_FilesSheet> createState() => _FilesSheetState();
}

class _DeleteAsk extends StatelessWidget {
  const _DeleteAsk({
    required this.entry,
    required this.onYes,
    required this.onNo,
  });

  final FileEntry entry;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          Messages.filesDeleteAsk(entry.name.toUpperCase()),
          key: filesAskKey,
          style: text.bodyMedium?.copyWith(color: TileColors.highlight),
        ),
        const SizedBox(height: TileMetrics.gutter),
        Row(
          children: <Widget>[
            Expanded(
              child: PadKey(
                key: filesYesKey,
                label: Messages.mailYes,
                height: 44,
                fontSize: 12,
                onTap: onYes,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: PadKey(
                key: filesNoKey,
                label: Messages.mailNo,
                height: 44,
                fontSize: 12,
                onTap: onNo,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The ask before a bulk delete — the list's own version of the single
/// entry's DELETE confirm.
class _BulkDeleteAsk extends StatelessWidget {
  const _BulkDeleteAsk({
    required this.count,
    required this.onYes,
    required this.onNo,
  });

  final int count;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          Messages.filesBulkTrashAsk(count),
          style: text.bodyMedium?.copyWith(color: TileColors.highlight),
        ),
        const SizedBox(height: TileMetrics.gutter),
        Row(
          children: <Widget>[
            Expanded(
              child: PadKey(
                key: filesBulkYesKey,
                label: Messages.mailYes,
                height: 44,
                fontSize: 12,
                onTap: onYes,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: PadKey(
                key: filesBulkNoKey,
                label: Messages.mailNo,
                height: 44,
                fontSize: 12,
                onTap: onNo,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A removable chip for one applied filter field, the same shape mail's own
/// filter chips take.
class _FilterChip extends StatelessWidget {
  const _FilterChip({super.key, required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontSize: 11, color: TileColors.accent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: TileColors.accent, width: TileMetrics.bevel),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: style),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            child: Text('X', style: style),
          ),
        ],
      ),
    );
  }
}

/// A checkbox-shaped selection mark, the same look mail's own bulk-select
/// rows use.
class _FileCheckbox extends StatelessWidget {
  const _FileCheckbox({super.key, required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: checked ? TileColors.accent : Colors.transparent,
        border: Border.all(color: TileColors.bezel, width: TileMetrics.bevel),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.entry,
    required this.selecting,
    required this.selected,
    required this.onOpen,
    required this.onToggleSelect,
    this.onDelete,
  });

  final FileEntry entry;
  final bool selecting;
  final bool selected;
  final VoidCallback onOpen;
  final VoidCallback onToggleSelect;

  /// `null` hides the delete control entirely — a storage volume itself
  /// (the top-level list) is not something to offer deleting, and bulk
  /// selection uses its own DELETE button instead.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle nameStyle =
        text.bodySmall?.copyWith(fontSize: 11, color: TileColors.textBright) ??
        const TextStyle(fontSize: 11);
    final TextStyle metaStyle =
        text.bodySmall?.copyWith(fontSize: 9, color: TileColors.muted) ??
        const TextStyle(fontSize: 9);
    final VoidCallback? delete = onDelete;
    return Padding(
      key: filesRowKey(entry.path),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: selecting
            ? onToggleSelect
            : entry.isDirectory
            ? onOpen
            : null,
        child: Row(
          children: <Widget>[
            if (selecting) ...<Widget>[
              _FileCheckbox(
                key: filesCheckboxKey(entry.path),
                checked: selected,
              ),
              const SizedBox(width: 8),
            ],
            entry.isDirectory
                ? FolderIcon(size: 16, color: TileColors.textBright)
                : DocumentIcon(size: 16, color: TileColors.muted),
            const SizedBox(width: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => Text(
                  _fitName(
                    entry.name.toUpperCase(),
                    constraints.maxWidth,
                    nameStyle,
                  ),
                  maxLines: 1,
                  style: nameStyle,
                ),
              ),
            ),
            SizedBox(
              width: _modifiedColumnWidth,
              child: Text(
                formatFileDate(entry.modified, DateTime.now()),
                textAlign: TextAlign.right,
                style: metaStyle,
              ),
            ),
            SizedBox(
              width: _sizeColumnWidth,
              child: Text(
                entry.isDirectory
                    ? (entry.itemCount == null
                          ? ''
                          : Messages.filesItemCount(entry.itemCount!))
                    : formatBytes(entry.sizeBytes),
                textAlign: TextAlign.right,
                style: metaStyle,
              ),
            ),
            if (!selecting)
              SizedBox(
                width: _actionsColumnWidth,
                child: delete == null
                    ? null
                    : Align(
                        alignment: Alignment.centerRight,
                        child: Semantics(
                          button: true,
                          label: Messages.filesDelete,
                          child: SizedBox(
                            key: filesDeleteKey(entry.path),
                            width: 28,
                            height: 28,
                            child: InkWell(
                              onTap: delete,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: TileColors.accent,
                                    width: TileMetrics.bevel,
                                  ),
                                ),
                                child: Center(
                                  child: TrashIcon(
                                    size: 16,
                                    color: TileColors.accent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

/// [name] as-is if it fits [maxWidth] at [style], else shortened in the
/// middle — a prefix, `...`, then a suffix long enough to keep the extension
/// readable (`THISSAHDSJ...DSDSDSA.MP4`, not a plain end-ellipsis that would
/// hide it). Measured with the real [style] via [TextPainter] rather than
/// assumed, since a fixed character budget would be wrong the moment the
/// FONT SIZE setting changes it.
String _fitName(String name, double maxWidth, TextStyle style) {
  double widthOf(String s) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  if (widthOf(name) <= maxWidth) return name;

  final int dot = name.lastIndexOf('.');
  final bool hasExtension = dot > 0 && dot < name.length - 1;
  final String stem = hasExtension ? name.substring(0, dot) : name;
  final String extension = hasExtension ? name.substring(dot) : '';

  for (int keep = (stem.length / 2).floor(); keep > 0; keep--) {
    final String candidate =
        '${stem.substring(0, keep)}...${stem.substring(stem.length - keep)}'
        '$extension';
    if (widthOf(candidate) <= maxWidth) return candidate;
  }
  // Even one character either side does not fit; give up the prefix first.
  return '...$extension';
}
