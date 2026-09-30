import 'dart:math' as math;

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/clock_format.dart';
import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/model/mail_format.dart';
import 'package:android_tile_launcher/services/attachment_download_service.dart';
import 'package:android_tile_launcher/services/contacts_repository.dart';
import 'package:android_tile_launcher/services/mail_service.dart';
import 'package:android_tile_launcher/ui/compose_sheet.dart';
import 'package:android_tile_launcher/ui/mail_filter_sheet.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

/// Keys so tests can find the parts.
Key mailMessageKey(int uid) => ValueKey<String>('mail-message-$uid');
Key mailCheckboxKey(int uid) => ValueKey<String>('mail-checkbox-$uid');
const Key mailComposeKey = ValueKey<String>('mail-compose');
const Key mailFromComposeKey = ValueKey<String>('mail-from-compose');
const Key mailReplyKey = ValueKey<String>('mail-reply');
const Key mailReplyAllKey = ValueKey<String>('mail-reply-all');
const Key mailForwardKey = ValueKey<String>('mail-forward');
const Key mailPrevKey = ValueKey<String>('mail-prev');
const Key mailNextKey = ValueKey<String>('mail-next');
const Key mailTrashKey = ValueKey<String>('mail-trash');
const Key mailTrashYesKey = ValueKey<String>('mail-trash-yes');
const Key mailTrashNoKey = ValueKey<String>('mail-trash-no');
const Key mailRefreshKey = ValueKey<String>('mail-refresh');
const Key mailForgetKey = ValueKey<String>('mail-forget');
const Key mailBackKey = ValueKey<String>('mail-back');
const Key mailMarkKey = ValueKey<String>('mail-mark');
const Key mailReaderKey = ValueKey<String>('mail-reader');
const Key mailBodyKey = ValueKey<String>('mail-body');
const Key mailForgetYesKey = ValueKey<String>('mail-forget-yes');
const Key mailForgetNoKey = ValueKey<String>('mail-forget-no');
const Key mailSelectKey = ValueKey<String>('mail-select');
const Key mailSelectAllKey = ValueKey<String>('mail-select-all');
const Key mailCancelSelectKey = ValueKey<String>('mail-cancel-select');
const Key mailBulkDeleteKey = ValueKey<String>('mail-bulk-delete');
const Key mailBulkReadKey = ValueKey<String>('mail-bulk-read');
const Key mailBulkUnreadKey = ValueKey<String>('mail-bulk-unread');
const Key mailBulkYesKey = ValueKey<String>('mail-bulk-yes');
const Key mailBulkNoKey = ValueKey<String>('mail-bulk-no');
const Key mailShowImagesKey = ValueKey<String>('mail-show-images');
const Key mailFilterKey = ValueKey<String>('mail-filter');
Key mailFilterChipKey(String field) =>
    ValueKey<String>('mail-filter-chip-$field');
Key mailDownloadKey(String name) => ValueKey<String>('mail-download-$name');

/// `RE: <subject>`, unless [subject] already reads as a reply.
String _replySubject(String subject) {
  final String trimmed = subject.trim();
  if (trimmed.toLowerCase().startsWith('re:')) return trimmed;
  return trimmed.isEmpty ? 'Re:' : 'Re: $trimmed';
}

/// `Fwd: <subject>`, unless [subject] already reads as a forward.
String _forwardSubject(String subject) {
  final String trimmed = subject.trim();
  if (trimmed.toLowerCase().startsWith('fwd:')) return trimmed;
  return trimmed.isEmpty ? 'Fwd:' : 'Fwd: $trimmed';
}

/// [body]'s own text, quoted under an "on ... wrote:" line and led by two
/// blank lines for the reply or forward itself — the compose sheet puts the
/// cursor above it, so typing starts there, not inside the quote. [signature],
/// when set, sits in that same leading space, above the quote.
String _quotedOriginal(MailBody body, {String signature = ''}) {
  final String who = body.date == null
      ? '${body.from} wrote:'
      : 'On ${formatClockDate(body.date!)} '
            '${formatClockTime(body.date!)}, ${body.from} wrote:';
  final String quoted = body.text
      .split('\n')
      .map((String line) => '> $line')
      .join('\n');
  final String sig = signature.isEmpty ? '' : '$signature\n\n';
  return '\n\n$sig$who\n$quoted';
}

DateTime _systemNow() => DateTime.now();

/// What a tap on a mail tile with an inbox opens: the newest messages, newest
/// first, unread ones marked. Tapping a message opens it in full, in a pane of
/// its own (BACK returns to the list), and marks it read, as opening a mail
/// does anywhere. In the pane, MARK AS UNREAD (or MARK AS READ, whichever the
/// message is not) and TRASH, which asks again before moving it to the server's
/// Trash (never deleting it outright); tapping the sender's own address opens
/// a reply, addressed to them with the subject prefixed `RE:`. The list also
/// has COMPOSE (a blank message), REFRESH, and FORGET ACCOUNT (which asks
/// first, then removes the account and its password from the phone).
Future<void> showMailSheet(
  BuildContext context, {
  required MailService mail,
  required AttachmentDownloadService attachmentDownload,
  required ContactsRepository contacts,
  DateTime Function() clock = _systemNow,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    // Laid out below the status bar.
    useSafeArea: true,
    builder: (BuildContext sheetContext) {
      final MediaQueryData media = MediaQuery.of(sheetContext);
      return SizedBox(
        height: math.min(
          media.size.height * 0.85,
          media.size.height - media.padding.top - TileMetrics.margin,
        ),
        child: _MailSheet(
          mail: mail,
          attachmentDownload: attachmentDownload,
          contacts: contacts,
          clock: clock,
        ),
      );
    },
  );
}

class _MailSheet extends StatefulWidget {
  const _MailSheet({
    required this.mail,
    required this.attachmentDownload,
    required this.contacts,
    required this.clock,
  });

  final MailService mail;
  final AttachmentDownloadService attachmentDownload;
  final ContactsRepository contacts;
  final DateTime Function() clock;

  @override
  State<_MailSheet> createState() => _MailSheetState();
}

class _MailSheetState extends State<_MailSheet> {
  bool _loading = true;
  MailResult? _result;
  String? _email;
  List<MailMessage> _messages = <MailMessage>[];

  // The message open in the reader pane, and what has come of opening it.
  int? _openUid;
  bool _reading = false;
  MailBody? _opened;
  String? _readError;

  /// Whether the open message's pictures are revealed (SHOW IMAGES), and
  /// which attachment names are mid-save.
  bool _showImages = false;
  final Set<String> _downloading = <String>{};

  int? _confirmingTrash;
  bool _confirmingForget = false;
  bool _busy = false;
  String? _status;

  // Bulk delete from the list, never while a message is open.
  bool _selecting = false;
  final Set<int> _selected = <int>{};
  bool _confirmingBulkTrash = false;
  bool _bulkDeleting = false;
  int _bulkDone = 0;
  int _bulkTotal = 0;

  /// What FILTER narrowed the list to; empty is no filtering at all.
  MailFilter _filter = const MailFilter();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _openUid = null;
      _opened = null;
      _confirmingTrash = null;
      _selecting = false;
      _selected.clear();
      _confirmingBulkTrash = false;
    });
    final MailAccountInfo? account = await widget.mail.account();
    // Always from the server: the sheet is for looking at what is there now.
    final MailResult result = _filter.isEmpty
        ? await widget.mail.latest(count: 20, fresh: true)
        : await widget.mail.search(_filter, count: 20);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _email = account?.email;
      _result = result;
      _messages = result is MailMessages
          ? List<MailMessage>.of(result.messages)
          : <MailMessage>[];
    });
  }

  Future<void> _openFilter() async {
    final MailFilter? next = await showMailFilterSheet(
      context,
      initial: _filter,
    );
    if (next == null || next == _filter) return;
    setState(() => _filter = next);
    await _load();
  }

  void _clearFilterField(MailFilter Function(MailFilter) without) {
    setState(() => _filter = without(_filter));
    _load();
  }

  int? get _validity {
    final MailResult? result = _result;
    return result is MailMessages ? result.validity : null;
  }

  MailMessage? _entry(int uid) {
    for (final MailMessage m in _messages) {
      if (m.uid == uid) return m;
    }
    return null;
  }

  void _setUnread(int uid, bool unread) {
    final int i = _messages.indexWhere((MailMessage m) => m.uid == uid);
    if (i >= 0) _messages[i] = _messages[i].copyWith(unread: unread);
  }

  void _dropFromList(int uid) => _messages.removeWhere((m) => m.uid == uid);

  /// Opens [m] in the pane: fetched in full and, on the server, marked read.
  Future<void> _open(MailMessage m) async {
    setState(() {
      _openUid = m.uid;
      _opened = null;
      _readError = null;
      _reading = true;
      _confirmingTrash = null;
      _status = null;
      _showImages = false;
      _downloading.clear();
    });
    final MailReadResult result = await widget.mail.read(
      m.uid,
      validity: _validity,
    );
    if (!mounted || _openUid != m.uid) return;
    setState(() {
      _reading = false;
      switch (result) {
        case MailOpened(:final MailBody body):
          _opened = body;
          if (body.markedRead) {
            _setUnread(m.uid, false);
          } else {
            _status = Messages.mailNotMarked;
          }
        case MailReadGone():
          _dropFromList(m.uid);
          _openUid = null;
          _status = Messages.mailGone;
        case MailReadNotSetUp():
          _readError = Messages.mailTapToSetUp;
        case MailReadFailed(:final String reason):
          _readError = reason.toUpperCase();
      }
    });
  }

  void _back() => setState(() {
    _openUid = null;
    _opened = null;
    _readError = null;
    _confirmingTrash = null;
    _status = null;
    _showImages = false;
    _downloading.clear();
  });

  /// Flips the open message between read and unread.
  Future<void> _toggleRead(int uid) async {
    final MailMessage? entry = _entry(uid);
    if (entry == null) return;
    // Unread now, so the wish is to read it; read now, to unread it.
    final bool makeRead = entry.unread;
    setState(() {
      _busy = true;
      _status = null;
    });
    final MailMarkResult marked = await widget.mail.mark(
      uid,
      read: makeRead,
      validity: _validity,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (marked) {
        case MailMarked(:final bool read):
          _setUnread(uid, !read);
          _status = read ? Messages.mailMarkedRead : Messages.mailMarkedUnread;
        case MailMarkGone():
          _dropFromList(uid);
          _openUid = null;
          _status = Messages.mailGone;
        case MailMarkNotSetUp():
          _status = '${Messages.failedPrefix}${Messages.mailTapToSetUp}';
        case MailMarkFailed(:final String reason):
          _status = '${Messages.failedPrefix}${reason.toUpperCase()}';
      }
    });
  }

  Future<void> _trash(int uid) async {
    setState(() {
      _busy = true;
      _confirmingTrash = null;
    });
    final MailMoveResult moved = await widget.mail.moveToTrash(
      uid,
      validity: _validity,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (moved) {
        case MailMoved():
          _dropFromList(uid);
          _openUid = null;
          _opened = null;
          _status = Messages.mailMoved;
        case MailGone():
          _dropFromList(uid);
          _openUid = null;
          _opened = null;
          _status = Messages.mailGone;
        case MailMoveNotSetUp():
          _status = '${Messages.failedPrefix}${Messages.mailTapToSetUp}';
        case MailMoveFailed(:final String reason):
          _status = '${Messages.failedPrefix}${reason.toUpperCase()}';
      }
    });
  }

  void _startSelecting() => setState(() {
    _selecting = true;
    _selected.clear();
  });

  void _cancelSelecting() => setState(() {
    _selecting = false;
    _selected.clear();
    _confirmingBulkTrash = false;
  });

  void _toggleSelected(int uid) => setState(() {
    if (!_selected.remove(uid)) _selected.add(uid);
  });

  void _selectAll() => setState(() {
    _selected
      ..clear()
      ..addAll(_messages.map((MailMessage m) => m.uid));
  });

  /// Moves every selected message to Trash, one at a time (so
  /// [_bulkTrash]'s own progress line means something), then reloads from
  /// the server — the same "look at what is actually there now" reasoning
  /// [_load] itself already uses, not just a local list edit.
  Future<void> _bulkTrash() async {
    final List<int> uids = _selected.toList();
    setState(() {
      _busy = true;
      _confirmingBulkTrash = false;
      _bulkDeleting = true;
      _bulkDone = 0;
      _bulkTotal = uids.length;
      _status = null;
    });
    int moved = 0;
    for (final int uid in uids) {
      final MailMoveResult result = await widget.mail.moveToTrash(
        uid,
        validity: _validity,
      );
      if (!mounted) return;
      switch (result) {
        case MailMoved():
        case MailGone():
          moved++;
        case MailMoveNotSetUp():
        case MailMoveFailed():
          break;
      }
      setState(() => _bulkDone++);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _bulkDeleting = false;
      _status = Messages.mailBulkMoved(moved);
    });
    await _load();
  }

  Future<void> _forget() async {
    setState(() => _busy = true);
    await widget.mail.forget();
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _revealImages() => setState(() => _showImages = true);

  /// Saves [attachment] to the phone's Downloads folder.
  Future<void> _download(MailAttachment attachment) async {
    setState(() {
      _downloading.add(attachment.name);
      _status = null;
    });
    final AttachmentSaveResult result = await widget.attachmentDownload.save(
      attachment.bytes,
      fileName: attachment.name,
      mimeType: attachment.mimeType,
    );
    if (!mounted) return;
    setState(() {
      _downloading.remove(attachment.name);
      _status = switch (result) {
        AttachmentSaveResult.saved => Messages.mailDownloaded,
        AttachmentSaveResult.refused || AttachmentSaveResult.failed =>
          '${Messages.failedPrefix}${Messages.mailDownloadFailed}',
      };
    });
  }

  /// Appended to every new message, reply and forward; empty adds nothing.
  String get _signature => SettingsScope.of(context).mailSignature;

  Future<void> _compose() => showComposeSheet(
    context,
    mail: widget.mail,
    contacts: widget.contacts,
    body: _signature.isEmpty ? null : '\n\n$_signature',
  );

  /// Opens a blank message addressed to [address]: what tapping the sender's
  /// own chip does, rather than a reply (REPLY is its own button now).
  Future<void> _composeTo(String address) => showComposeSheet(
    context,
    mail: widget.mail,
    contacts: widget.contacts,
    to: address,
    body: _signature.isEmpty ? null : '\n\n$_signature',
  );

  /// Opens a reply to [body]'s own sender: addressed to them, the subject
  /// prefixed `RE:` unless it already is one, and the original text quoted
  /// under the (empty) space for the reply itself.
  Future<void> _reply(MailBody body) => showComposeSheet(
    context,
    mail: widget.mail,
    contacts: widget.contacts,
    to: body.fromAddress,
    subject: _replySubject(body.subject),
    body: _quotedOriginal(body, signature: _signature),
  );

  /// Opens a forward of [body]: the same quoted text as a reply, but with TO
  /// left blank rather than pre-filled with the original sender.
  Future<void> _forward(MailBody body) => showComposeSheet(
    context,
    mail: widget.mail,
    contacts: widget.contacts,
    subject: _forwardSubject(body.subject),
    body: _quotedOriginal(body, signature: _signature),
  );

  /// Whether [body] had more than one recipient (besides this account),
  /// so REPLY and REPLY ALL would actually differ.
  bool _hasOtherRecipients(MailBody body) =>
      replyAllCcAddresses(body, _email).isNotEmpty;

  /// Opens a reply to everyone [body] went to: addressed to the original
  /// sender, same as REPLY, but copying every other To/Cc address too (never
  /// this account's own, never the sender twice).
  Future<void> _replyAll(MailBody body) => showComposeSheet(
    context,
    mail: widget.mail,
    contacts: widget.contacts,
    to: body.fromAddress,
    cc: replyAllCcAddresses(body, _email).join(', '),
    subject: _replySubject(body.subject),
    body: _quotedOriginal(body, signature: _signature),
  );

  /// Where the open message sits in [_messages] (newest first), for PREV/NEXT.
  int? get _openIndex {
    final int? uid = _openUid;
    if (uid == null) return null;
    final int i = _messages.indexWhere((MailMessage m) => m.uid == uid);
    return i < 0 ? null : i;
  }

  bool get _canGoPrev => (_openIndex ?? -1) > 0;
  bool get _canGoNext {
    final int? i = _openIndex;
    return i != null && i < _messages.length - 1;
  }

  Future<void> _openPrev() async {
    final int? i = _openIndex;
    if (i == null || i <= 0) return;
    await _open(_messages[i - 1]);
  }

  Future<void> _openNext() async {
    final int? i = _openIndex;
    if (i == null || i >= _messages.length - 1) return;
    await _open(_messages[i + 1]);
  }

  /// Marks every selected message read or unread, in place (no reload: unlike
  /// a trash move, marking never changes who is in the list).
  Future<void> _bulkMark(bool read) async {
    final List<int> uids = _selected.toList();
    setState(() => _busy = true);
    int marked = 0;
    for (final int uid in uids) {
      final MailMarkResult result = await widget.mail.mark(
        uid,
        read: read,
        validity: _validity,
      );
      if (!mounted) return;
      switch (result) {
        case MailMarked():
          _setUnread(uid, !read);
          marked++;
        case MailMarkGone():
          _dropFromList(uid);
        case MailMarkNotSetUp():
        case MailMarkFailed():
          break;
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _selecting = false;
      _selected.clear();
      _status = read
          ? Messages.mailBulkMarkedRead(marked)
          : Messages.mailBulkMarkedUnread(marked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final MailResult? result = _result;
    final int? open = _openUid;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // So the button row is not flush against the sheet's own top edge.
            const SizedBox(height: TileMetrics.gutter),
            Row(
              children: <Widget>[
                if (open != null) ...<Widget>[
                  _Button(
                    key: mailBackKey,
                    label: Messages.mailBack,
                    onTap: _busy ? null : _back,
                  ),
                  const Spacer(),
                ] else if (_selecting) ...<Widget>[
                  Expanded(
                    child: Text(
                      Messages.mailSelectedCount(_selected.length),
                      style: text.bodyMedium?.copyWith(
                        color: TileColors.textBright,
                      ),
                    ),
                  ),
                  _Button(
                    key: mailSelectAllKey,
                    label: Messages.mailSelectAll,
                    onTap: _busy || _selected.length == _messages.length
                        ? null
                        : _selectAll,
                  ),
                  const SizedBox(width: 8),
                  _Button(
                    key: mailCancelSelectKey,
                    label: Messages.mailCancelSelect,
                    onTap: _busy ? null : _cancelSelecting,
                  ),
                ] else ...<Widget>[
                  Text(
                    Messages.mailTitle,
                    style: text.bodyMedium?.copyWith(
                      color: TileColors.textBright,
                    ),
                  ),
                  const Spacer(),
                  _Button(
                    key: mailSelectKey,
                    label: Messages.mailSelect,
                    onTap: _busy || _loading || _messages.isEmpty
                        ? null
                        : _startSelecting,
                  ),
                  const SizedBox(width: 8),
                  _Button(
                    key: mailRefreshKey,
                    label: Messages.mailRefresh,
                    onTap: _busy || _loading ? null : _load,
                  ),
                ],
              ],
            ),
            // Its own row, under the title's: three buttons on top of it would
            // not fit a narrow phone.
            if (open == null && !_selecting) ...<Widget>[
              const SizedBox(height: TileMetrics.gutter),
              Row(
                children: <Widget>[
                  if (_email != null)
                    Expanded(
                      child: Text(
                        _email!.toUpperCase(),
                        style: text.bodySmall?.copyWith(
                          fontSize: 11,
                          color: TileColors.muted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    const Spacer(),
                  _Button(
                    key: mailFilterKey,
                    label: Messages.mailFilter,
                    onTap: _busy || _loading ? null : _openFilter,
                  ),
                  const SizedBox(width: 8),
                  _Button(
                    key: mailComposeKey,
                    label: Messages.mailCompose,
                    onTap: _busy ? null : _compose,
                  ),
                ],
              ),
              if (!_filter.isEmpty) ...<Widget>[
                const SizedBox(height: TileMetrics.gutter),
                _filterChips(),
              ],
            ],
            // READ/UNREAD/DELETE wrap onto a second line on a narrow phone,
            // rather than a fixed row that would overflow.
            if (_selecting) ...<Widget>[
              const SizedBox(height: TileMetrics.gutter),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _Button(
                    key: mailBulkReadKey,
                    label: Messages.mailReadSelected(_selected.length),
                    onTap: _busy || _selected.isEmpty
                        ? null
                        : () => _bulkMark(true),
                  ),
                  _Button(
                    key: mailBulkUnreadKey,
                    label: Messages.mailUnreadSelected(_selected.length),
                    onTap: _busy || _selected.isEmpty
                        ? null
                        : () => _bulkMark(false),
                  ),
                  _Button(
                    key: mailBulkDeleteKey,
                    label: Messages.mailDeleteSelected(_selected.length),
                    onTap: _busy || _selected.isEmpty
                        ? null
                        : () => setState(() => _confirmingBulkTrash = true),
                  ),
                ],
              ),
            ],
            // PREV/NEXT below BACK, its own row: PREV flush with the sheet's
            // own left margin, NEXT pushed to its right one, so both sit as
            // evenly clear of the sheet's edges as every row above them.
            if (open != null) ...<Widget>[
              const SizedBox(height: TileMetrics.gutter),
              Row(
                children: <Widget>[
                  _Button(
                    key: mailPrevKey,
                    label: Messages.mailPrev,
                    onTap: _busy || _reading || !_canGoPrev ? null : _openPrev,
                  ),
                  const Spacer(),
                  _Button(
                    key: mailNextKey,
                    label: Messages.mailNext,
                    onTap: _busy || _reading || !_canGoNext ? null : _openNext,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Container(height: 2, color: TileColors.bezel),
            const SizedBox(height: TileMetrics.gutter),
            if (_confirmingBulkTrash) ...<Widget>[
              _BulkTrashAsk(
                count: _selected.length,
                onYes: _bulkTrash,
                onNo: () => setState(() => _confirmingBulkTrash = false),
              ),
              const SizedBox(height: TileMetrics.gutter),
            ],
            if (_bulkDeleting) ...<Widget>[
              Text(
                Messages.mailBulkDeleting(_bulkDone, _bulkTotal),
                style: text.bodyMedium,
              ),
              const SizedBox(height: TileMetrics.gutter),
            ],
            Expanded(
              child: open != null ? _reader(text, open) : _body(text, result),
            ),
            if (open != null && _opened != null) ...<Widget>[
              const SizedBox(height: TileMetrics.gutter),
              _actions(text, open),
            ],
            if (_status != null)
              Padding(
                padding: const EdgeInsets.only(top: TileMetrics.gutter),
                child: Text(
                  _status!,
                  style: text.bodySmall?.copyWith(
                    fontSize: 13,
                    color: TileColors.accent,
                  ),
                ),
              ),
            if (open == null && !_selecting) ...<Widget>[
              const SizedBox(height: TileMetrics.gutter),
              _forgetRow(text),
            ],
          ],
        ),
      ),
    );
  }

  /// The pane: who, when, what, then the whole text, scrolling.
  Widget _reader(TextTheme text, int uid) {
    if (_reading) {
      return Text(Messages.mailOpening, style: text.bodyMedium);
    }
    final String? error = _readError;
    if (error != null) {
      return Text(error, style: text.bodyMedium);
    }
    final MailBody? body = _opened;
    if (body == null) return const SizedBox.shrink();
    final TextStyle? label = text.bodySmall?.copyWith(
      fontSize: 11,
      color: TileColors.muted,
    );
    final TextStyle? value = text.bodySmall?.copyWith(
      fontSize: 13,
      color: TileColors.textBright,
    );
    return SingleChildScrollView(
      key: mailReaderKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(Messages.mailFrom, style: label),
          if (body.fromAddress.isNotEmpty)
            _AddressChip(
              key: mailFromComposeKey,
              text: body.from,
              onTap: _busy ? null : () => _composeTo(body.fromAddress),
            )
          else
            Text(body.from.toUpperCase(), style: value),
          if (body.to.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(Messages.mailTo, style: label),
            _AddressChipRow(
              participants: body.to,
              onTap: _busy ? null : _composeTo,
            ),
          ],
          if (body.cc.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(Messages.mailCc, style: label),
            _AddressChipRow(
              participants: body.cc,
              onTap: _busy ? null : _composeTo,
            ),
          ],
          if (body.date != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(Messages.mailDate, style: label),
            Text(
              '${formatClockDate(body.date!)} ${formatClockTime(body.date!)}',
              style: text.bodySmall?.copyWith(
                fontSize: 13,
                color: TileColors.accent,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            body.subject.isEmpty
                ? Messages.mailNoSubject
                : body.subject.toUpperCase(),
            style: value,
          ),
          const SizedBox(height: 8),
          Container(height: 2, color: TileColors.bezel),
          const SizedBox(height: TileMetrics.gutter),
          if (body.htmlWithImages != null && !_showImages) ...<Widget>[
            _Button(
              key: mailShowImagesKey,
              label: Messages.mailShowImages,
              onTap: _revealImages,
            ),
            const SizedBox(height: TileMetrics.gutter),
          ],
          _bodyContent(body, text),
          if (body.truncated) ...<Widget>[
            const SizedBox(height: 8),
            Text(Messages.mailCutOff, style: label),
          ],
          if (body.attachments.isNotEmpty) ...<Widget>[
            const SizedBox(height: TileMetrics.gutter),
            Container(height: 2, color: TileColors.bezel),
            const SizedBox(height: 8),
            Text(
              Messages.mailAttachments(body.attachments.length),
              style: label,
            ),
            for (final MailAttachment attachment in body.attachments)
              _AttachmentRow(
                attachment: attachment,
                saving: _downloading.contains(attachment.name),
                onDownload: _busy ? null : () => _download(attachment),
              ),
          ],
        ],
      ),
    );
  }

  /// The whole message: rendered rich when it has real markup ([MailBody.html]),
  /// else its plain text as-is. SHOW IMAGES swaps in [MailBody.htmlWithImages].
  Widget _bodyContent(MailBody body, TextTheme text) {
    final String? html = _showImages
        ? body.htmlWithImages ?? body.html
        : body.html;
    if (html != null && html.trim().isNotEmpty) {
      return HtmlWidget(
        html,
        key: mailBodyKey,
        textStyle: text.bodySmall?.copyWith(
          fontSize: 12,
          height: 1.7,
          color: TileColors.textBright,
        ),
      );
    }
    return SelectableText(
      body.text.isEmpty ? Messages.mailNoText : body.text,
      key: mailBodyKey,
      style: text.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.7,
        color: body.text.isEmpty ? TileColors.muted : TileColors.textBright,
      ),
    );
  }

  /// MARK AS READ/UNREAD, REPLY, FORWARD and TRASH, with room between them
  /// (wrapping onto a second line on a narrow phone rather than overflowing);
  /// TRASH asks again first.
  Widget _actions(TextTheme text, int uid) {
    if (_confirmingTrash == uid) {
      return Row(
        children: <Widget>[
          Text(
            Messages.mailTrashAsk,
            style: text.bodySmall?.copyWith(
              fontSize: 11,
              color: TileColors.highlight,
            ),
          ),
          const SizedBox(width: 8),
          _Button(
            key: mailTrashYesKey,
            label: Messages.mailYes,
            onTap: _busy ? null : () => _trash(uid),
          ),
          const SizedBox(width: 8),
          _Button(
            key: mailTrashNoKey,
            label: Messages.mailNo,
            onTap: () => setState(() => _confirmingTrash = null),
          ),
        ],
      );
    }
    final bool unread = _entry(uid)?.unread ?? false;
    final MailBody? opened = _opened;
    return Wrap(
      spacing: TileMetrics.margin * 2,
      runSpacing: TileMetrics.gutter,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _Button(
          key: mailMarkKey,
          label: unread ? Messages.mailMarkRead : Messages.mailMarkUnread,
          onTap: _busy ? null : () => _toggleRead(uid),
        ),
        _Button(
          key: mailReplyKey,
          label: Messages.mailReply,
          onTap: _busy || opened == null ? null : () => _reply(opened),
        ),
        if (opened != null && _hasOtherRecipients(opened))
          _Button(
            key: mailReplyAllKey,
            label: Messages.mailReplyAll,
            onTap: _busy ? null : () => _replyAll(opened),
          ),
        _Button(
          key: mailForwardKey,
          label: Messages.mailForward,
          onTap: _busy || opened == null ? null : () => _forward(opened),
        ),
        _Button(
          key: mailTrashKey,
          label: Messages.mailTrash,
          onTap: _busy ? null : () => setState(() => _confirmingTrash = uid),
        ),
      ],
    );
  }

  /// One removable chip per filter field that is set, above the list and
  /// below the account/COMPOSE row.
  Widget _filterChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        if (_filter.text.isNotEmpty)
          _FilterChip(
            key: mailFilterChipKey('text'),
            label: Messages.mailFilterTextChip(_filter.text),
            onRemove: () => _clearFilterField((f) => f.withoutText()),
          ),
        if (_filter.from.isNotEmpty)
          _FilterChip(
            key: mailFilterChipKey('from'),
            label: Messages.mailFilterFromChip(_filter.from),
            onRemove: () => _clearFilterField((f) => f.withoutFrom()),
          ),
        if (_filter.to.isNotEmpty)
          _FilterChip(
            key: mailFilterChipKey('to'),
            label: Messages.mailFilterToChip(_filter.to),
            onRemove: () => _clearFilterField((f) => f.withoutTo()),
          ),
        if (_filter.olderThan != null)
          _FilterChip(
            key: mailFilterChipKey('olderThan'),
            label: Messages.mailFilterOlderThanChip(
              _filter.olderThan!.amount,
              _filter.olderThan!.unit.label,
            ),
            onRemove: () => _clearFilterField((f) => f.withoutOlderThan()),
          ),
      ],
    );
  }

  Widget _body(TextTheme text, MailResult? result) {
    if (_loading) {
      return Text(Messages.contactsLoading, style: text.bodyMedium);
    }
    switch (result) {
      case MailMessages():
        if (_messages.isEmpty) {
          return Text(
            _filter.isEmpty ? Messages.mailInboxEmpty : Messages.mailNoMatches,
            style: text.bodyMedium,
          );
        }
        final DateTime now = widget.clock();
        return ListView(
          children: <Widget>[
            for (final MailMessage m in _messages) _row(text, m, now),
          ],
        );
      case MailNotSetUp():
        return Text(Messages.mailTapToSetUp, style: text.bodyMedium);
      case MailUnavailable(:final String reason):
        return Text(reason.toUpperCase(), style: text.bodyMedium);
      case null:
        return const SizedBox.shrink();
    }
  }

  Widget _row(TextTheme text, MailMessage m, DateTime now) {
    final Color bright = m.unread ? TileColors.textBright : TileColors.muted;
    final bool selected = _selected.contains(m.uid);
    return InkWell(
      key: mailMessageKey(m.uid),
      onTap: _busy
          ? null
          : _selecting
          ? () => _toggleSelected(m.uid)
          : () => _open(m),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: TileColors.bezel)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_selecting) ...<Widget>[
              _Checkbox(key: mailCheckboxKey(m.uid), checked: selected),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${m.unread ? '* ' : ''}${m.from.toUpperCase()}',
                          style: text.bodySmall?.copyWith(
                            fontSize: 13,
                            color: bright,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatMailDate(m.date, now),
                        style: text.bodySmall?.copyWith(
                          fontSize: 11,
                          color: TileColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.subject.isEmpty
                        ? Messages.mailNoSubject
                        : m.subject.toUpperCase(),
                    style: text.bodySmall?.copyWith(
                      fontSize: 11,
                      color: bright,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _forgetRow(TextTheme text) {
    if (!_confirmingForget) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _Button(
          key: mailForgetKey,
          label: Messages.mailForget,
          onTap: _busy ? null : () => setState(() => _confirmingForget = true),
        ),
      );
    }
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            Messages.mailForgetAsk,
            style: text.bodySmall?.copyWith(
              fontSize: 11,
              color: TileColors.highlight,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _Button(
          key: mailForgetYesKey,
          label: Messages.mailYes,
          onTap: _busy ? null : _forget,
        ),
        const SizedBox(width: 8),
        _Button(
          key: mailForgetNoKey,
          label: Messages.mailNo,
          onTap: () => setState(() => _confirmingForget = false),
        ),
      ],
    );
  }
}

/// One address as a small bordered chip — the badge look From, To and Cc all
/// share. A `null` [onTap] leaves it inert rather than hiding the border, so
/// a busy reader still reads the same.
class _AddressChip extends StatelessWidget {
  const _AddressChip({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: TileColors.accent,
            width: TileMetrics.bevel,
          ),
        ),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontSize: 13, color: TileColors.accent),
        ),
      ),
    );
  }
}

/// One applied filter, with its own X to clear just that one.
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

/// Every address on a To or Cc line, each its own chip, wrapping onto as many
/// lines as a narrow phone needs. Tapping one composes a fresh message to it,
/// the same as tapping the From chip does.
class _AddressChipRow extends StatelessWidget {
  const _AddressChipRow({required this.participants, required this.onTap});

  final List<MailParticipant> participants;
  final void Function(String address)? onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (final MailParticipant p in participants)
          _AddressChip(
            text: p.label,
            onTap: onTap == null ? null : () => onTap!(p.address),
          ),
      ],
    );
  }
}

/// One attachment: its name and size, with its own DOWNLOAD button.
class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({
    required this.attachment,
    required this.saving,
    required this.onDownload,
  });

  final MailAttachment attachment;
  final bool saving;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  attachment.name.toUpperCase(),
                  style: text.bodySmall?.copyWith(
                    fontSize: 12,
                    color: TileColors.textBright,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formatAttachmentSize(attachment.sizeBytes),
                  style: text.bodySmall?.copyWith(
                    fontSize: 10,
                    color: TileColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Button(
            key: mailDownloadKey(attachment.name),
            label: saving ? Messages.mailDownloading : Messages.mailDownload,
            onTap: saving ? null : onDownload,
          ),
        ],
      ),
    );
  }
}

/// A small bordered text button in the launcher's own look; a `null` [onTap]
/// greys it.
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: colour, width: TileMetrics.bevel),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontSize: 11, color: colour),
        ),
      ),
    );
  }
}

/// A small bordered square, filled when [checked] — the same flat,
/// no-glyph look the size grid picker's own cells use, rather than a
/// platform checkbox that would look like a different app's control.
class _Checkbox extends StatelessWidget {
  const _Checkbox({super.key, required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: checked ? TileColors.accent : Colors.transparent,
        border: Border.all(color: TileColors.bezel, width: TileMetrics.bevel),
      ),
    );
  }
}

/// The ask before a bulk delete — the list's own version of the single
/// message's TRASH confirm.
class _BulkTrashAsk extends StatelessWidget {
  const _BulkTrashAsk({
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          Messages.mailBulkTrashAsk(count),
          style: text.bodySmall?.copyWith(
            fontSize: 11,
            color: TileColors.highlight,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            _Button(key: mailBulkYesKey, label: Messages.mailYes, onTap: onYes),
            const SizedBox(width: 8),
            _Button(key: mailBulkNoKey, label: Messages.mailNo, onTap: onNo),
          ],
        ),
      ],
    );
  }
}
