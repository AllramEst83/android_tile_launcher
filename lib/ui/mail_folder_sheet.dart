import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/services/mail_service.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
Key mailFolderChoiceKey(String name) => ValueKey<String>('mail-folder-$name');
Key mailFolderRenameKey(String name) =>
    ValueKey<String>('mail-folder-rename-$name');
Key mailFolderDeleteKey(String name) =>
    ValueKey<String>('mail-folder-delete-$name');
const Key mailFolderNewKey = ValueKey<String>('mail-folder-new');
const Key mailFolderManageKey = ValueKey<String>('mail-folder-manage');
const Key mailFolderFieldKey = ValueKey<String>('mail-folder-field');
const Key mailFolderSaveKey = ValueKey<String>('mail-folder-save');
const Key mailFolderCancelKey = ValueKey<String>('mail-folder-cancel');
const Key mailFolderYesKey = ValueKey<String>('mail-folder-yes');
const Key mailFolderNoKey = ValueKey<String>('mail-folder-no');

/// The account's folders to pick from, and, under MANAGE, to create, rename
/// and delete (only the ones the user made). Completes with the folder
/// tapped, or null if the sheet was dismissed. The inbox is always offered,
/// even when the server listed no folders. [onChanged] is told the new list
/// after every change, so the caller's copy stays right even if the sheet is
/// then dismissed.
Future<MailFolder?> showMailFolderSheet(
  BuildContext context, {
  required MailService mail,
  required List<MailFolder> folders,
  required MailFolder current,
  required void Function(List<MailFolder> folders) onChanged,
}) {
  return showModalBottomSheet<MailFolder>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
      ),
      child: _FolderSheet(
        mail: mail,
        folders: folders,
        current: current,
        onChanged: onChanged,
      ),
    ),
  );
}

/// What the sheet is asking the user for right now, if anything.
enum _Mode { pick, create, rename, delete }

class _FolderSheet extends StatefulWidget {
  const _FolderSheet({
    required this.mail,
    required this.folders,
    required this.current,
    required this.onChanged,
  });

  final MailService mail;
  final List<MailFolder> folders;
  final MailFolder current;
  final void Function(List<MailFolder> folders) onChanged;

  @override
  State<_FolderSheet> createState() => _FolderSheetState();
}

class _FolderSheetState extends State<_FolderSheet> {
  final TextEditingController _field = TextEditingController();
  late List<MailFolder> _folders = widget.folders;
  bool _manage = false;
  bool _busy = false;
  _Mode _mode = _Mode.pick;
  MailFolder? _target;
  String? _status;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  List<MailFolder> get _shown =>
      _folders.any((MailFolder f) => f.kind == MailFolderKind.inbox)
      ? _folders
      : <MailFolder>[
          const MailFolder(
            name: '',
            label: 'INBOX',
            kind: MailFolderKind.inbox,
          ),
          ..._folders,
        ];

  void _ask(_Mode mode, {MailFolder? target}) {
    setState(() {
      _mode = mode;
      _target = target;
      _status = null;
      _field.text = mode == _Mode.rename ? target!.label : '';
    });
  }

  void _back() => setState(() {
    _mode = _Mode.pick;
    _target = null;
  });

  /// Runs [change], and on success reads the folders again.
  Future<void> _run(Future<MailFolderResult> Function() change) async {
    setState(() {
      _busy = true;
      _status = Messages.mailFolderWorking;
    });
    final MailFolderResult result = await change();
    if (!mounted) return;
    switch (result) {
      case MailFolderDone():
        final List<MailFolder> fresh = await widget.mail.folders();
        if (!mounted) return;
        widget.onChanged(fresh);
        setState(() {
          _folders = fresh;
          _busy = false;
          _mode = _Mode.pick;
          _target = null;
          _status = null;
        });
      case MailFolderNotSetUp():
        setState(() {
          _busy = false;
          _status = '${Messages.failedPrefix}${Messages.mailTapToSetUp}';
        });
      case MailFolderFailed(:final String reason):
        setState(() {
          _busy = false;
          _status = '${Messages.failedPrefix}${reason.toUpperCase()}';
        });
    }
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: TileMetrics.gutter),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    Messages.mailFolders,
                    style: text.bodyMedium?.copyWith(
                      color: TileColors.textBright,
                    ),
                  ),
                ),
                _small(
                  mailFolderNewKey,
                  Messages.mailFolderNew,
                  _busy ? null : () => _ask(_Mode.create),
                ),
                const SizedBox(width: 8),
                _small(
                  mailFolderManageKey,
                  _manage ? Messages.mailFolderDone : Messages.mailFolderManage,
                  _busy
                      ? null
                      : () => setState(() {
                          _manage = !_manage;
                          _mode = _Mode.pick;
                          _status = null;
                        }),
                  selected: _manage,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(height: 2, color: TileColors.bezel),
            if (_mode == _Mode.create || _mode == _Mode.rename) _nameRow(text),
            if (_mode == _Mode.delete) _deleteAsk(text),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.only(top: TileMetrics.gutter),
                child: Text(
                  _status!,
                  style: text.bodySmall?.copyWith(
                    fontSize: 12,
                    color: TileColors.accent,
                  ),
                ),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  for (final MailFolder f in _shown) _row(text, f),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _small(
    Key key,
    String label,
    VoidCallback? onTap, {
    bool selected = false,
  }) => PadKey(
    key: key,
    label: label,
    height: 36,
    fontSize: 11,
    selected: selected,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    onTap: onTap,
  );

  /// The name being typed for a new folder or a renamed one.
  Widget _nameRow(TextTheme text) {
    final bool renaming = _mode == _Mode.rename;
    return Padding(
      padding: const EdgeInsets.only(top: TileMetrics.gutter),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              key: mailFolderFieldKey,
              controller: _field,
              autofocus: true,
              enabled: !_busy,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _submitName(),
              style: text.bodySmall?.copyWith(
                fontSize: 12,
                color: TileColors.textBright,
              ),
              cursorColor: TileColors.textBright,
              decoration: InputDecoration(
                hintText: Messages.mailFolderName,
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
          _small(
            mailFolderSaveKey,
            renaming ? Messages.mailFolderSave : Messages.mailFolderCreate,
            _busy ? null : _submitName,
          ),
          const SizedBox(width: 8),
          _small(mailFolderCancelKey, 'X', _busy ? null : _back),
        ],
      ),
    );
  }

  void _submitName() {
    final String name = _field.text;
    final MailFolder? target = _target;
    if (_mode == _Mode.rename && target != null) {
      _run(() => widget.mail.renameFolder(target.name, name));
    } else {
      _run(() => widget.mail.createFolder(name));
    }
  }

  Widget _deleteAsk(TextTheme text) {
    final MailFolder target = _target!;
    return Padding(
      padding: const EdgeInsets.only(top: TileMetrics.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            Messages.mailFolderDeleteAsk(target.label),
            style: text.bodySmall?.copyWith(
              fontSize: 11,
              color: TileColors.highlight,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              _small(
                mailFolderYesKey,
                Messages.mailYes,
                _busy
                    ? null
                    : () => _run(() => widget.mail.deleteFolder(target.name)),
              ),
              const SizedBox(width: 8),
              _small(mailFolderNoKey, Messages.mailNo, _busy ? null : _back),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(TextTheme text, MailFolder f) {
    final bool here = f.name == widget.current.name;
    final Widget label = Text(
      '${here ? '> ' : '  '}${f.label}',
      style: text.bodySmall?.copyWith(
        fontSize: 12,
        color: here ? TileColors.highlight : TileColors.textBright,
      ),
    );
    return Container(
      padding: EdgeInsets.symmetric(vertical: _manage && f.isCustom ? 4 : 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: TileColors.bezel)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: InkWell(
              key: mailFolderChoiceKey(f.name),
              onTap: _busy ? null : () => Navigator.of(context).pop(f),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: label,
              ),
            ),
          ),
          // Only a folder the user made can be changed.
          if (_manage && f.isCustom) ...<Widget>[
            _small(
              mailFolderRenameKey(f.name),
              Messages.mailFolderRename,
              _busy ? null : () => _ask(_Mode.rename, target: f),
            ),
            const SizedBox(width: 8),
            _small(
              mailFolderDeleteKey(f.name),
              Messages.mailFolderDelete,
              _busy ? null : () => _ask(_Mode.delete, target: f),
            ),
          ],
        ],
      ),
    );
  }
}
