import 'dart:math' as math;

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/model/mail_format.dart';
import 'package:android_tile_launcher/services/mail_service.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
Key mailMessageKey(int uid) => ValueKey<String>('mail-message-$uid');
const Key mailTrashKey = ValueKey<String>('mail-trash');
const Key mailTrashYesKey = ValueKey<String>('mail-trash-yes');
const Key mailTrashNoKey = ValueKey<String>('mail-trash-no');
const Key mailRefreshKey = ValueKey<String>('mail-refresh');
const Key mailForgetKey = ValueKey<String>('mail-forget');
const Key mailForgetYesKey = ValueKey<String>('mail-forget-yes');
const Key mailForgetNoKey = ValueKey<String>('mail-forget-no');

DateTime _systemNow() => DateTime.now();

/// What a tap on a mail tile with an inbox opens: the newest messages, newest
/// first, unread ones marked. Tapping a message offers TRASH, which asks again
/// before moving it to the server's Trash (never deleting it outright). Also
/// REFRESH, and FORGET ACCOUNT (which asks first, then removes the account and
/// its password from the phone).
Future<void> showMailSheet(
  BuildContext context, {
  required MailService mail,
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
        child: _MailSheet(mail: mail, clock: clock),
      );
    },
  );
}

class _MailSheet extends StatefulWidget {
  const _MailSheet({required this.mail, required this.clock});

  final MailService mail;
  final DateTime Function() clock;

  @override
  State<_MailSheet> createState() => _MailSheetState();
}

class _MailSheetState extends State<_MailSheet> {
  bool _loading = true;
  MailResult? _result;
  String? _email;
  List<MailMessage> _messages = <MailMessage>[];

  int? _selected;
  int? _confirmingTrash;
  bool _confirmingForget = false;
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _selected = null;
      _confirmingTrash = null;
    });
    final MailAccountInfo? account = await widget.mail.account();
    // Always from the server: the sheet is for looking at what is there now.
    final MailResult result = await widget.mail.latest(count: 20, fresh: true);
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

  Future<void> _trash(int uid) async {
    final MailResult? result = _result;
    setState(() {
      _busy = true;
      _confirmingTrash = null;
    });
    final MailMoveResult moved = await widget.mail.moveToTrash(
      uid,
      validity: result is MailMessages ? result.validity : null,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (moved) {
        case MailMoved():
          _messages.removeWhere((MailMessage m) => m.uid == uid);
          _selected = null;
          _status = Messages.mailMoved;
        case MailGone():
          _messages.removeWhere((MailMessage m) => m.uid == uid);
          _selected = null;
          _status = Messages.mailGone;
        case MailMoveNotSetUp():
          _status = '${Messages.failedPrefix}${Messages.mailTapToSetUp}';
        case MailMoveFailed(:final String reason):
          _status = '${Messages.failedPrefix}${reason.toUpperCase()}';
      }
    });
  }

  Future<void> _forget() async {
    setState(() => _busy = true);
    await widget.mail.forget();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final MailResult? result = _result;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  Messages.mailTitle,
                  style: text.bodyMedium?.copyWith(
                    color: TileColors.textBright,
                  ),
                ),
                const Spacer(),
                _Button(
                  key: mailRefreshKey,
                  label: Messages.mailRefresh,
                  onTap: _busy || _loading ? null : _load,
                ),
              ],
            ),
            if (_email != null)
              Text(
                _email!.toUpperCase(),
                style: text.bodySmall?.copyWith(
                  fontSize: 8,
                  color: C64.lightGrey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Container(height: 2, color: TileColors.bezel),
            const SizedBox(height: TileMetrics.gutter),
            Expanded(child: _body(text, result)),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.only(top: TileMetrics.gutter),
                child: Text(
                  _status!,
                  style: text.bodySmall?.copyWith(
                    fontSize: 10,
                    color: C64.cyan,
                  ),
                ),
              ),
            const SizedBox(height: TileMetrics.gutter),
            _forgetRow(text),
          ],
        ),
      ),
    );
  }

  Widget _body(TextTheme text, MailResult? result) {
    if (_loading) {
      return Text(Messages.contactsLoading, style: text.bodyMedium);
    }
    switch (result) {
      case MailMessages():
        if (_messages.isEmpty) {
          return Text(Messages.mailInboxEmpty, style: text.bodyMedium);
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
    final bool selected = _selected == m.uid;
    final Color bright = m.unread ? TileColors.textBright : C64.lightGrey;
    return InkWell(
      key: mailMessageKey(m.uid),
      onTap: _busy
          ? null
          : () => setState(() {
              _selected = selected ? null : m.uid;
              _confirmingTrash = null;
              _status = null;
            }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: TileColors.bezel)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${m.unread ? '* ' : ''}${m.from.toUpperCase()}',
                    style: text.bodySmall?.copyWith(
                      fontSize: 10,
                      color: bright,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatMailDate(m.date, now),
                  style: text.bodySmall?.copyWith(fontSize: 8, color: C64.cyan),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              m.subject.isEmpty
                  ? Messages.mailNoSubject
                  : m.subject.toUpperCase(),
              style: text.bodySmall?.copyWith(fontSize: 8, color: bright),
              maxLines: selected ? 4 : 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (selected) ...<Widget>[
              const SizedBox(height: 8),
              if (_confirmingTrash == m.uid)
                Row(
                  children: <Widget>[
                    Text(
                      Messages.mailTrashAsk,
                      style: text.bodySmall?.copyWith(
                        fontSize: 8,
                        color: C64.yellow,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Button(
                      key: mailTrashYesKey,
                      label: Messages.mailYes,
                      onTap: _busy ? null : () => _trash(m.uid),
                    ),
                    const SizedBox(width: 8),
                    _Button(
                      key: mailTrashNoKey,
                      label: Messages.mailNo,
                      onTap: () => setState(() => _confirmingTrash = null),
                    ),
                  ],
                )
              else
                _Button(
                  key: mailTrashKey,
                  label: Messages.mailTrash,
                  onTap: _busy
                      ? null
                      : () => setState(() => _confirmingTrash = m.uid),
                ),
            ],
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
            style: text.bodySmall?.copyWith(fontSize: 8, color: C64.yellow),
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
              ?.copyWith(fontSize: 8, color: colour),
        ),
      ),
    );
  }
}
