import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/services/mail_service.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key composeToKey = ValueKey<String>('compose-to');
const Key composeSubjectKey = ValueKey<String>('compose-subject');
const Key composeBodyKey = ValueKey<String>('compose-body');
const Key composeSendKey = ValueKey<String>('compose-send');

/// What COMPOSE on the mail sheet opens (blank), or what tapping the sender's
/// address in an open message opens (addressed to them, subject prefixed
/// `RE:`, [body] the original text quoted below): to, subject and the message
/// text, SEND on the account already set up. Closes on its own once the
/// server accepts it.
Future<void> showComposeSheet(
  BuildContext context, {
  required MailService mail,
  String? to,
  String? subject,
  String? body,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    // Laid out below the status bar, so the keyboard cannot push it under it.
    useSafeArea: true,
    builder: (BuildContext sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _ComposeSheet(mail: mail, to: to, subject: subject, body: body),
    ),
  );
}

class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet({required this.mail, this.to, this.subject, this.body});

  final MailService mail;
  final String? to;
  final String? subject;
  final String? body;

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  late final TextEditingController _to = TextEditingController(
    text: widget.to ?? '',
  );
  late final TextEditingController _subject = TextEditingController(
    text: widget.subject ?? '',
  );
  // The cursor starts above a quoted reply, not at its end, so typing goes
  // where the reply belongs.
  late final TextEditingController _body = TextEditingController(
    text: widget.body ?? '',
  )..selection = const TextSelection.collapsed(offset: 0);

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _to.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    final String to = _to.text.trim();
    if (to.isEmpty) {
      setState(() => _error = Messages.mailSendNeedsTo);
      return;
    }
    final String text = _body.text.trim();
    if (text.isEmpty) {
      setState(() => _error = Messages.mailSendNeedsText);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final MailSendResult result = await widget.mail.send(
      to: to,
      subject: _subject.text.trim(),
      text: text,
    );
    if (!mounted) return;
    switch (result) {
      case MailSent():
        Navigator.pop(context);
      case MailSendNotSetUp():
        setState(() {
          _busy = false;
          _error = Messages.mailTapToSetUp;
        });
      case MailSendFailed(:final String reason):
        setState(() {
          _busy = false;
          _error = reason.toUpperCase();
        });
    }
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
              Text(
                Messages.mailComposeTitle,
                style: text.bodyMedium?.copyWith(color: TileColors.textBright),
              ),
              const SizedBox(height: 4),
              Container(height: 2, color: TileColors.bezel),
              const SizedBox(height: TileMetrics.margin),
              _Field(
                fieldKey: composeToKey,
                label: Messages.mailTo,
                controller: _to,
                keyboardType: TextInputType.emailAddress,
              ),
              _Field(
                fieldKey: composeSubjectKey,
                label: Messages.mailSubject,
                controller: _subject,
              ),
              _Field(
                fieldKey: composeBodyKey,
                label: Messages.mailBody,
                controller: _body,
                maxLines: 6,
              ),
              const SizedBox(height: TileMetrics.gutter),
              InkWell(
                key: composeSendKey,
                onTap: _busy ? null : _send,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _busy ? TileColors.textDim : TileColors.textBright,
                      width: TileMetrics.bevel,
                    ),
                  ),
                  child: Text(
                    _busy ? Messages.mailSending : Messages.mailSend,
                    style: text.bodySmall?.copyWith(
                      fontSize: 10,
                      color: _busy ? TileColors.textDim : TileColors.textBright,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: TileMetrics.margin),
                Text(
                  _error!,
                  style: text.bodySmall?.copyWith(
                    fontSize: 10,
                    color: TileColors.danger,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One text field: a small muted label over an underline-bordered
/// `TextField`, the same shape [mail_setup_sheet]'s own fields take.
class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: TileMetrics.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: text.bodySmall?.copyWith(
              fontSize: 8,
              color: TileColors.muted,
            ),
          ),
          TextField(
            key: fieldKey,
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
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
        ],
      ),
    );
  }
}
