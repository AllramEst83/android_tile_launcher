import 'dart:async';

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/byte_format.dart';
import 'package:android_tile_launcher/model/file_entry.dart';
import 'package:android_tile_launcher/services/files_service.dart';
import 'package:android_tile_launcher/ui/file_icons.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key filesChooseKey = ValueKey<String>('files-choose');
const Key filesChangeFolderKey = ValueKey<String>('files-change-folder');
const Key filesBackKey = ValueKey<String>('files-back');
const Key filesCloseKey = ValueKey<String>('files-close');
const Key filesAskKey = ValueKey<String>('files-ask');
const Key filesYesKey = ValueKey<String>('files-yes');
const Key filesNoKey = ValueKey<String>('files-no');
Key filesRowKey(String path) => ValueKey<String>('files-row-$path');
Key filesDeleteKey(String path) => ValueKey<String>('files-delete-$path');

/// What a tap on the files tile opens: one folder the user picked through
/// Android's own folder picker (never broader access than that), browsed one
/// level at a time, each entry deletable directly.
Future<void> showFilesSheet(
  BuildContext context, {
  required FilesService service,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    // Laid out below the status bar.
    useSafeArea: true,
    builder: (BuildContext sheetContext) => _FilesSheet(service: service),
  );
}

class _FilesSheet extends StatefulWidget {
  const _FilesSheet({required this.service});

  final FilesService service;

  @override
  State<_FilesSheet> createState() => _FilesSheetState();
}

class _FilesSheetState extends State<_FilesSheet> {
  bool _loading = true;
  bool _hasFolder = false;

  /// The folder names entered so far, root first; joined with `/` this is
  /// the `path` [FilesService.list] and [FilesService.delete] take.
  final List<String> _stack = <String>[];
  FilesResult? _result;
  FileEntry? _pendingDelete;
  String? _error;

  String get _path => _stack.join('/');

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    final bool has = await widget.service.hasFolder();
    if (!mounted) return;
    setState(() {
      _hasFolder = has;
      _loading = false;
    });
    if (has) unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _result = null);
    final FilesResult result = await widget.service.list(_path);
    if (!mounted) return;
    setState(() {
      _result = result;
      if (result is FilesNoFolder) _hasFolder = false;
    });
  }

  Future<void> _pick() async {
    final PickFolderResult result = await widget.service.pickFolder();
    if (!mounted) return;
    switch (result) {
      case FolderPicked():
        setState(() {
          _hasFolder = true;
          _stack.clear();
          _error = null;
        });
        unawaited(_load());
      case FolderPickCancelled():
        break;
      case FolderPickFailed(:final String reason):
        setState(() => _error = reason.toUpperCase());
    }
  }

  Future<void> _changeFolder() async {
    await widget.service.forgetFolder();
    if (!mounted) return;
    setState(() {
      _hasFolder = false;
      _stack.clear();
      _result = null;
      _error = null;
    });
  }

  void _open(FileEntry entry) {
    if (!entry.isDirectory) return;
    setState(() {
      _stack.add(entry.name);
      _pendingDelete = null;
    });
    unawaited(_load());
  }

  void _back() {
    setState(() {
      _stack.removeLast();
      _pendingDelete = null;
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
                  child: Text(Messages.filesTitle, style: text.bodyMedium),
                ),
                if (_hasFolder) ...<Widget>[
                  PadKey(
                    key: filesChangeFolderKey,
                    label: Messages.filesChangeFolder,
                    height: 32,
                    fontSize: 10,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onTap: _changeFolder,
                  ),
                  const SizedBox(width: TileMetrics.gutter),
                ],
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
    if (!_hasFolder) {
      return PadKey(
        key: filesChooseKey,
        label: Messages.filesTapToChoose,
        height: 48,
        fontSize: 12,
        onTap: _pick,
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
    final FilesResult? result = _result;
    if (result == null) {
      return Text(Messages.filesLoading, style: text.bodyMedium);
    }
    return switch (result) {
      FilesListed(:final List<FileEntry> entries) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (_stack.isNotEmpty) ...<Widget>[
            SizedBox(
              width: 80,
              child: PadKey(
                key: filesBackKey,
                label: Messages.filesBack,
                height: 32,
                fontSize: 10,
                onTap: _back,
              ),
            ),
            const SizedBox(height: TileMetrics.gutter),
          ],
          if (entries.isEmpty)
            Text(Messages.filesEmpty, style: text.bodyMedium)
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  for (final FileEntry entry in entries)
                    _FileRow(
                      entry: entry,
                      onOpen: () => _open(entry),
                      onDelete: () => _askDelete(entry),
                    ),
                ],
              ),
            ),
        ],
      ),
      FilesNoFolder() => Text(
        Messages.filesTapToChoose,
        style: text.bodyMedium,
      ),
      FilesUnavailable(:final String reason) => Text(
        reason.toUpperCase(),
        style: text.bodyMedium,
      ),
    };
  }
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

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.entry,
    required this.onOpen,
    required this.onDelete,
  });

  final FileEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle nameStyle =
        text.bodySmall?.copyWith(fontSize: 11, color: TileColors.textBright) ??
        const TextStyle(fontSize: 11);
    return Padding(
      key: filesRowKey(entry.path),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: entry.isDirectory ? onOpen : null,
        child: Row(
          children: <Widget>[
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
            if (!entry.isDirectory) ...<Widget>[
              const SizedBox(width: 8),
              Text(
                formatBytes(entry.sizeBytes),
                style: text.bodySmall?.copyWith(
                  fontSize: 9,
                  color: TileColors.muted,
                ),
              ),
            ],
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: Messages.filesDelete,
              child: SizedBox(
                key: filesDeleteKey(entry.path),
                width: 28,
                height: 28,
                child: InkWell(
                  onTap: onDelete,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: TileColors.accent,
                        width: TileMetrics.bevel,
                      ),
                    ),
                    child: Center(
                      child: TrashIcon(size: 16, color: TileColors.accent),
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
