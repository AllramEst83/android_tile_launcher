import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/contact.dart';
import 'package:android_tile_launcher/services/contacts_service.dart';
import 'package:android_tile_launcher/services/phone_service.dart';
import 'package:android_tile_launcher/services/sms_service.dart';
import 'package:android_tile_launcher/services/tile_services.dart';
import 'package:android_tile_launcher/services/whatsapp_service.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key contactCallKey = ValueKey<String>('contact-call');
const Key contactSmsKey = ValueKey<String>('contact-sms');
const Key contactWhatsAppKey = ValueKey<String>('contact-whatsapp');
const Key contactSendKey = ValueKey<String>('contact-send');
const Key contactMessageKey = ValueKey<String>('contact-message');
Key contactNumberKey(int index) => ValueKey<String>('contact-number-$index');

/// What a tap on a contact tile opens: the person's numbers and CALL, SMS and
/// WHATSAPP. Nothing happens from the tile tap itself; every action needs its
/// own tap here, and a text also needs to be typed and sent. Opening the sheet
/// is what asks for contacts access, if that has not been given.
Future<void> showContactSheet(
  BuildContext context, {
  required TileServices services,
  required String contactKey,
  required String name,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => Padding(
      // Keep the message field above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _ContactSheet(
        services: services,
        contactKey: contactKey,
        name: name,
      ),
    ),
  );
}

class _ContactSheet extends StatefulWidget {
  const _ContactSheet({
    required this.services,
    required this.contactKey,
    required this.name,
  });

  final TileServices services;
  final String contactKey;
  final String name;

  @override
  State<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<_ContactSheet> {
  final TextEditingController _message = TextEditingController();

  bool _loading = true;
  Contact? _contact;
  String? _problem;
  int _selected = 0;
  bool _composing = false;
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final ContactsResult result = await widget.services.contacts.all();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case ContactsRead(:final List<Contact> contacts):
          _contact = findContact(
            contacts,
            key: widget.contactKey,
            name: widget.name,
          );
          if (_contact == null) {
            _problem = Messages.contactGone;
          } else {
            // Start on the number most likely to take a text.
            _selected = _contact!.numbers.indexOf(_contact!.preferredNumber);
          }
        case ContactsDenied(:final bool permanent):
          _problem = permanent
              ? Messages.contactsAllowInSettings
              : Messages.contactsNotAllowed;
        case ContactsUnavailable(:final String reason):
          _problem = reason.toUpperCase();
        case ContactsNoAccess():
          _problem = Messages.contactsNotAllowed;
      }
    });
  }

  PhoneNumber get _number => _contact!.numbers[_selected];

  Future<void> _call() async {
    setState(() => _busy = true);
    final CallResult result = await widget.services.phone.call(
      dialable(_number.number),
    );
    if (!mounted) return;
    switch (result) {
      case CallPlaced() || DialerOpened():
        Navigator.pop(context);
      case CallFailed(:final String reason):
        setState(() {
          _busy = false;
          _status = '${Messages.failedPrefix}${reason.toUpperCase()}';
        });
    }
  }

  Future<void> _whatsApp() async {
    setState(() => _busy = true);
    final WhatsAppResult result = await widget.services.whatsApp.openChat(
      whatsAppNumber(_number.number),
    );
    if (!mounted) return;
    switch (result) {
      case WhatsAppOpened():
        Navigator.pop(context);
      case WhatsAppFailed(:final String reason):
        setState(() {
          _busy = false;
          _status = '${Messages.failedPrefix}${reason.toUpperCase()}';
        });
    }
  }

  Future<void> _send() async {
    final String text = _message.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _busy = true;
      _status = Messages.contactSending;
    });
    final SmsResult result = await widget.services.sms.send(
      dialable(_number.number),
      text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (result) {
        case SmsSent():
          _status = Messages.contactSent;
          _composing = false;
          _message.clear();
        case SmsDenied(:final bool permanent):
          _status = permanent
              ? Messages.smsAllowInSettings
              : Messages.smsNotAllowed;
        case SmsFailed(:final String reason):
          _status = '${Messages.failedPrefix}${reason.toUpperCase()}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Contact? contact = _contact;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              (contact?.name ?? widget.name).toUpperCase(),
              style: text.bodyMedium?.copyWith(color: TileColors.textBright),
            ),
            const SizedBox(height: 4),
            Container(height: 2, color: TileColors.bezel),
            const SizedBox(height: TileMetrics.gutter),
            if (_loading)
              Text(Messages.contactsLoading, style: text.bodySmall)
            else if (contact == null)
              Text(_problem ?? '', style: text.bodyMedium)
            else ...<Widget>[
              for (final (int i, PhoneNumber n) in contact.numbers.indexed)
                _NumberRow(
                  key: contactNumberKey(i),
                  number: n,
                  selected: i == _selected,
                  // With one number there is nothing to choose between.
                  onTap: contact.numbers.length > 1
                      ? () => setState(() => _selected = i)
                      : null,
                ),
              const SizedBox(height: TileMetrics.margin),
              Row(
                children: <Widget>[
                  _ActionButton(
                    key: contactCallKey,
                    label: Messages.contactCall,
                    onTap: _busy ? null : _call,
                  ),
                  const SizedBox(width: TileMetrics.gutter),
                  _ActionButton(
                    key: contactSmsKey,
                    label: Messages.contactSms,
                    selected: _composing,
                    onTap: _busy
                        ? null
                        : () => setState(() => _composing = !_composing),
                  ),
                  const SizedBox(width: TileMetrics.gutter),
                  _ActionButton(
                    key: contactWhatsAppKey,
                    label: Messages.contactWhatsApp,
                    onTap: _busy ? null : _whatsApp,
                  ),
                ],
              ),
              if (_composing) ...<Widget>[
                const SizedBox(height: TileMetrics.margin),
                TextField(
                  key: contactMessageKey,
                  controller: _message,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 5,
                  style: text.bodySmall?.copyWith(
                    fontSize: 12,
                    color: TileColors.textBright,
                  ),
                  cursorColor: TileColors.textBright,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: Messages.contactMessageHint,
                    hintStyle: text.bodySmall?.copyWith(
                      fontSize: 12,
                      color: C64.lightGrey,
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: TileColors.bezel),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: TileColors.textBright),
                    ),
                  ),
                ),
                const SizedBox(height: TileMetrics.gutter),
                _ActionButton(
                  key: contactSendKey,
                  label: Messages.contactSend,
                  onTap: _busy ? null : _send,
                ),
              ],
              if (_status != null) ...<Widget>[
                const SizedBox(height: TileMetrics.margin),
                Text(
                  _status!,
                  style: text.bodySmall?.copyWith(
                    fontSize: 10,
                    color: C64.cyan,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// One of the person's numbers; the one the actions use is marked `>`.
class _NumberRow extends StatelessWidget {
  const _NumberRow({
    super.key,
    required this.number,
    required this.selected,
    required this.onTap,
  });

  final PhoneNumber number;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          '${selected ? '>' : ' '} ${number.label} ${number.number}',
          style: text.bodySmall?.copyWith(
            fontSize: 10,
            color: selected ? C64.cyan : C64.lightGrey,
          ),
        ),
      ),
    );
  }
}

/// A bordered text button in the launcher's own look. `null` [onTap] greys it.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Color colour = onTap == null
        ? TileColors.textDim
        : (selected ? C64.yellow : TileColors.textBright);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: colour, width: TileMetrics.bevel),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontSize: 10, color: colour),
        ),
      ),
    );
  }
}
