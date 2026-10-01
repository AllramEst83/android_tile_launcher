import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/file_filter.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key filesFilterCloseKey = ValueKey<String>('files-filter-close');
const Key filesFilterTextKey = ValueKey<String>('files-filter-text');
Key filesFilterTypeKey(FileTypeGroup type) =>
    ValueKey<String>('files-filter-type-${type.name}');
const Key filesFilterOlderThanAmountKey = ValueKey<String>(
  'files-filter-older-amount',
);
Key filesFilterUnitKey(FileAgeUnit unit) =>
    ValueKey<String>('files-filter-unit-${unit.name}');
Key filesFilterDirectionKey(FileAgeDirection direction) =>
    ValueKey<String>('files-filter-direction-${direction.name}');
const Key filesFilterApplyKey = ValueKey<String>('files-filter-apply');
const Key filesFilterClearKey = ValueKey<String>('files-filter-clear');

/// The pane FILTER opens: free text (the name), a TYPE group, and a MODIFIED
/// cutoff (a number, a unit, and an OLDER THAN/NEWER THAN toggle) — the same
/// shape `showMailFilterSheet` offers. Opened with whatever filter is already
/// applied, so reopening shows what is currently in effect. APPLY returns the
/// filter built from what is typed and chosen; CLEAR ALL returns an empty
/// one; the X returns null (no change, whatever was applied stays applied).
Future<FileFilter?> showFilesFilterSheet(
  BuildContext context, {
  required FileFilter initial,
}) {
  return showModalBottomSheet<FileFilter?>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _FilesFilterSheet(initial: initial),
    ),
  );
}

class _FilesFilterSheet extends StatefulWidget {
  const _FilesFilterSheet({required this.initial});

  final FileFilter initial;

  @override
  State<_FilesFilterSheet> createState() => _FilesFilterSheetState();
}

class _FilesFilterSheetState extends State<_FilesFilterSheet> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial.text,
  );
  late final TextEditingController _amount = TextEditingController(
    text: widget.initial.age == null ? '' : '${widget.initial.age!.amount}',
  );
  late FileTypeGroup? _type = widget.initial.type;
  late FileAgeUnit _unit = widget.initial.age?.unit ?? FileAgeUnit.days;
  late FileAgeDirection _direction =
      widget.initial.age?.direction ?? FileAgeDirection.older;

  @override
  void dispose() {
    _text.dispose();
    _amount.dispose();
    super.dispose();
  }

  FileFilter _build() {
    final int? amount = int.tryParse(_amount.text.trim());
    return FileFilter(
      text: _text.text.trim(),
      type: _type,
      age: amount == null || amount <= 0
          ? null
          : FileAgeFilter(amount, _unit, _direction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TileMetrics.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      Messages.filesFilterTitle,
                      style: text.bodyMedium?.copyWith(
                        color: TileColors.textBright,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: PadKey(
                      key: filesFilterCloseKey,
                      label: 'X',
                      height: 32,
                      fontSize: 12,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(height: 2, color: TileColors.bezel),
              const SizedBox(height: TileMetrics.margin),
              Text(
                Messages.filesFilterText,
                style: text.bodySmall?.copyWith(
                  fontSize: 8,
                  color: TileColors.muted,
                ),
              ),
              TextField(
                key: filesFilterTextKey,
                controller: _text,
                style: text.bodySmall?.copyWith(
                  fontSize: 12,
                  color: TileColors.textBright,
                ),
                cursorColor: TileColors.textBright,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: TileColors.bezel),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: TileColors.textBright),
                  ),
                ),
              ),
              const SizedBox(height: TileMetrics.gutter),
              Text(
                Messages.filesFilterType,
                style: text.bodySmall?.copyWith(
                  fontSize: 8,
                  color: TileColors.muted,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: <Widget>[
                  for (final FileTypeGroup type in FileTypeGroup.values)
                    PadKey(
                      key: filesFilterTypeKey(type),
                      label: type.label,
                      selected: _type == type,
                      height: 32,
                      fontSize: 10,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      onTap: () =>
                          setState(() => _type = _type == type ? null : type),
                    ),
                ],
              ),
              const SizedBox(height: TileMetrics.gutter),
              Row(
                children: <Widget>[
                  for (final FileAgeDirection direction
                      in FileAgeDirection.values) ...<Widget>[
                    if (direction != FileAgeDirection.values.first)
                      const SizedBox(width: 4),
                    PadKey(
                      key: filesFilterDirectionKey(direction),
                      label: direction == FileAgeDirection.older
                          ? Messages.filesFilterOlderThan
                          : Messages.filesFilterNewerThan,
                      selected: _direction == direction,
                      height: 32,
                      fontSize: 10,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      onTap: () => setState(() => _direction = direction),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 56,
                    child: TextField(
                      key: filesFilterOlderThanAmountKey,
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      style: text.bodySmall?.copyWith(
                        fontSize: 12,
                        color: TileColors.textBright,
                      ),
                      cursorColor: TileColors.textBright,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
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
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: <Widget>[
                          for (final FileAgeUnit unit in FileAgeUnit.values)
                            PadKey(
                              key: filesFilterUnitKey(unit),
                              label: unit.label,
                              selected: _unit == unit,
                              height: 32,
                              fontSize: 10,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              onTap: () => setState(() => _unit = unit),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TileMetrics.gutter),
              Row(
                children: <Widget>[
                  Expanded(
                    child: PadKey(
                      key: filesFilterClearKey,
                      label: Messages.filesFilterClear,
                      height: 44,
                      fontSize: 12,
                      onTap: () => Navigator.pop(context, const FileFilter()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PadKey(
                      key: filesFilterApplyKey,
                      label: Messages.filesFilterApply,
                      height: 44,
                      fontSize: 12,
                      onTap: () => Navigator.pop(context, _build()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
