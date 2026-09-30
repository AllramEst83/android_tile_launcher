import 'dart:async';

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/contact.dart';
import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/model/mail_format.dart';
import 'package:android_tile_launcher/services/contacts_repository.dart';
import 'package:android_tile_launcher/services/contacts_service.dart';
import 'package:android_tile_launcher/services/mail_service.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key composeToKey = ValueKey<String>('compose-to');
const Key composeCcKey = ValueKey<String>('compose-cc');
const Key composeSubjectKey = ValueKey<String>('compose-subject');
const Key composeBodyKey = ValueKey<String>('compose-body');
const Key composeSendKey = ValueKey<String>('compose-send');

/// One address chip in [field] ('to' or 'cc').
Key composeChipKey(String field, String address) =>
    ValueKey<String>('compose-chip-$field-$address');

/// One contact suggestion under [field] ('to' or 'cc').
Key composeSuggestionKey(String field, String email) =>
    ValueKey<String>('compose-suggestion-$field-$email');

/// What COMPOSE on the mail sheet opens (blank), or what tapping the sender's
/// address or REPLY/REPLY ALL/FORWARD in an open message opens: to, cc,
/// subject and the message text, SEND on the account already set up. [to] and
/// [cc] may each name more than one address (comma, semicolon or newline
/// separated), shown right away as chips. Typing a complete address followed
/// by a space, comma, semicolon or the keyboard's own done/next key turns it
/// into a chip the same way; backspacing on an empty field turns the last
/// chip back into editable text rather than deleting it outright. Closes on
/// its own once the server accepts it.
Future<void> showComposeSheet(
  BuildContext context, {
  required MailService mail,
  required ContactsRepository contacts,
  String? to,
  String? cc,
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
      child: _ComposeSheet(
        mail: mail,
        contacts: contacts,
        to: to,
        cc: cc,
        subject: subject,
        body: body,
      ),
    ),
  );
}

class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet({
    required this.mail,
    required this.contacts,
    this.to,
    this.cc,
    this.subject,
    this.body,
  });

  final MailService mail;
  final ContactsRepository contacts;
  final String? to;
  final String? cc;
  final String? subject;
  final String? body;

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  // Complete addresses already chipped, plus whatever is still being typed
  // in each field's own controller — [_toAddresses]/[_ccAddresses] combine
  // the two for sending, so a valid address needs no delimiter typed after it
  // just to be sent.
  late List<String> _toChips;
  late final TextEditingController _to;
  late List<String> _ccChips;
  late final TextEditingController _cc;

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

  /// Every (name, email) this phone's contacts offer, for the To/Cc fields'
  /// own autocomplete. Loaded once, silently: [ContactsRepository.peek]
  /// never asks for permission, so a phone book that is not accessible just
  /// means no suggestions rather than a dialog interrupting compose.
  List<(String name, String email)> _contactSuggestions = <(String, String)>[];

  @override
  void initState() {
    super.initState();
    final (List<String> toChips, String toRest) = _splitSeed(widget.to ?? '');
    _toChips = toChips;
    _to = TextEditingController(text: toRest);
    final (List<String> ccChips, String ccRest) = _splitSeed(widget.cc ?? '');
    _ccChips = ccChips;
    _cc = TextEditingController(text: ccRest);
    unawaited(_loadContactSuggestions());
  }

  Future<void> _loadContactSuggestions() async {
    final ContactsResult result = await widget.contacts.peek();
    if (!mounted || result is! ContactsRead) return;
    setState(() {
      _contactSuggestions = <(String, String)>[
        for (final Contact c in result.contacts)
          for (final String email in c.emails) (c.name, email),
      ];
    });
  }

  @override
  void dispose() {
    _to.dispose();
    _cc.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  /// [seed]'s addresses split into ones complete enough to chip right away
  /// and whatever is left (never itself complete, or [seed] would be too).
  (List<String> chips, String rest) _splitSeed(String seed) {
    final List<String> chips = <String>[];
    final List<String> rest = <String>[];
    for (final String part in parseAddressList(seed)) {
      (looksLikeCompleteEmail(part) ? chips : rest).add(part);
    }
    return (chips, rest.join(', '));
  }

  List<String> get _toAddresses => <String>[
    ..._toChips,
    ...parseAddressList(_to.text),
  ];
  List<String> get _ccAddresses => <String>[
    ..._ccChips,
    ...parseAddressList(_cc.text),
  ];

  Future<void> _send() async {
    if (_busy) return;
    final List<String> to = _toAddresses;
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
      cc: _ccAddresses,
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
              _ChipAddressField(
                fieldKey: composeToKey,
                chipField: 'to',
                label: Messages.mailTo,
                controller: _to,
                chips: _toChips,
                suggestions: _contactSuggestions,
                onChipsChanged: (List<String> chips) =>
                    setState(() => _toChips = chips),
              ),
              _ChipAddressField(
                fieldKey: composeCcKey,
                chipField: 'cc',
                label: Messages.mailCc,
                controller: _cc,
                chips: _ccChips,
                suggestions: _contactSuggestions,
                onChipsChanged: (List<String> chips) =>
                    setState(() => _ccChips = chips),
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

/// A To/Cc field that turns each complete address into a chip: [chips] are
/// already-committed addresses (shown as badges, each with its own X to
/// remove), and [controller] holds whatever is still being typed. Typing a
/// complete address followed by a space, comma or semicolon chips it (a
/// paste with several at once chips all but a trailing incomplete one);
/// so does the keyboard's own done/next action or the field losing focus.
/// Backspacing when the field is empty pops the last chip back into it as
/// text, rather than deleting it outright, so it can still be edited.
class _ChipAddressField extends StatefulWidget {
  const _ChipAddressField({
    required this.fieldKey,
    required this.chipField,
    required this.label,
    required this.controller,
    required this.chips,
    required this.suggestions,
    required this.onChipsChanged,
  });

  final Key fieldKey;
  final String chipField;
  final String label;
  final TextEditingController controller;
  final List<String> chips;

  /// This phone's contacts as (name, email) pairs, for suggesting a match
  /// while typing.
  final List<(String name, String email)> suggestions;
  final ValueChanged<List<String>> onChipsChanged;

  @override
  State<_ChipAddressField> createState() => _ChipAddressFieldState();
}

/// An invisible placeholder character kept in the field whenever it would
/// otherwise be empty while chips exist, so a backspace there has something
/// to delete — which is how it is told apart from a backspace inside real
/// text (nothing special happens then) without listening for raw key
/// presses, which a software keyboard is not guaranteed to send at all.
const String _emptyMarker = '​';

class _ChipAddressFieldState extends State<_ChipAddressField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    _setPending(widget.controller.text, hasChips: widget.chips.isNotEmpty);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) _commitPending();
  }

  /// Sets the field to [text], adding [_emptyMarker] when that would
  /// otherwise leave it empty while a chip could still be backspaced into.
  /// [hasChips] is the chip list [text] goes with — passed explicitly rather
  /// than read from `widget.chips`, which a just-called `onChipsChanged`
  /// has not necessarily rebuilt this widget with yet.
  void _setPending(String text, {required bool hasChips}) {
    final String value = text.isEmpty && hasChips ? _emptyMarker : text;
    widget.controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  /// Chips off every address in [raw] that a delimiter follows; whatever is
  /// still being typed after the last one is left in the field, even if it
  /// already looks complete (it may not be finished). A run of delimiters
  /// with nothing between them (typing "a@b.com, " leaves a comma then a
  /// space back to back once the address is chipped) collapses to nothing,
  /// rather than leaving stray punctuation behind. An empty [raw] with chips
  /// already there means the marker itself was backspaced away: the last
  /// chip comes back as editable text instead of vanishing.
  void _onChanged(String raw) {
    if (raw.isEmpty && widget.chips.isNotEmpty) {
      final List<String> chips = List<String>.of(widget.chips);
      final String last = chips.removeLast();
      widget.onChipsChanged(chips);
      widget.controller.value = TextEditingValue(
        text: last,
        selection: TextSelection.collapsed(offset: last.length),
      );
      return;
    }
    final String text = raw.startsWith(_emptyMarker)
        ? raw.substring(_emptyMarker.length)
        : raw;
    final RegExp delimiter = RegExp('[,; ]');
    final List<String> chipped = <String>[];
    final StringBuffer remaining = StringBuffer();
    int start = 0;
    for (final RegExpMatch m in delimiter.allMatches(text)) {
      final String segment = text.substring(start, m.start);
      final String trimmed = segment.trim();
      if (trimmed.isNotEmpty && looksLikeCompleteEmail(trimmed)) {
        chipped.add(trimmed);
      } else if (segment.isNotEmpty) {
        remaining.write(text.substring(start, m.end));
      }
      start = m.end;
    }
    remaining.write(text.substring(start));
    if (chipped.isEmpty) {
      // Nothing chipped, but the typed text changed: refresh the contact
      // suggestions it filters below.
      setState(() {});
      return;
    }
    final List<String> newChips = <String>[...widget.chips, ...chipped];
    widget.onChipsChanged(newChips);
    _setPending(remaining.toString(), hasChips: newChips.isNotEmpty);
  }

  /// Chips whatever is typed if, on its own, it is already a complete
  /// address — what the keyboard's done/next action and losing focus do.
  void _commitPending() {
    final String candidate = widget.controller.text
        .replaceAll(_emptyMarker, '')
        .trim();
    if (candidate.isEmpty || !looksLikeCompleteEmail(candidate)) return;
    final List<String> newChips = <String>[...widget.chips, candidate];
    widget.onChipsChanged(newChips);
    _setPending('', hasChips: newChips.isNotEmpty);
  }

  void _removeChip(String address) => widget.onChipsChanged(
    widget.chips.where((String a) => a != address).toList(),
  );

  /// Chips [email] straight from a tapped suggestion, replacing whatever was
  /// being typed.
  void _pickSuggestion(String email) {
    if (widget.chips.contains(email)) {
      _setPending('', hasChips: widget.chips.isNotEmpty);
      return;
    }
    final List<String> newChips = <String>[...widget.chips, email];
    widget.onChipsChanged(newChips);
    _setPending('', hasChips: newChips.isNotEmpty);
  }

  /// The contacts worth showing under the field right now: whatever is being
  /// typed, if it names at least two characters of a name or an address, and
  /// only while it is not already a chip.
  List<(String name, String email)> get _matches {
    final String query = widget.controller.text
        .replaceAll(_emptyMarker, '')
        .trim()
        .toLowerCase();
    if (query.length < 2) return const <(String, String)>[];
    return widget.suggestions
        .where(
          (r) =>
              !widget.chips.contains(r.$2) &&
              (r.$1.toLowerCase().contains(query) ||
                  r.$2.toLowerCase().contains(query)),
        )
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: TileMetrics.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.label,
            style: text.bodySmall?.copyWith(
              fontSize: 8,
              color: TileColors.muted,
            ),
          ),
          if (widget.chips.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final String address in widget.chips)
                  _RemovableChip(
                    key: composeChipKey(widget.chipField, address),
                    text: address,
                    onRemove: () => _removeChip(address),
                  ),
              ],
            ),
          ],
          TextField(
            key: widget.fieldKey,
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.emailAddress,
            onChanged: _onChanged,
            onSubmitted: (_) => _commitPending(),
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
          for (final (String name, String email) in _matches)
            InkWell(
              key: composeSuggestionKey(widget.chipField, email),
              onTap: () => _pickSuggestion(email),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '${name.toUpperCase()} — $email',
                  style: text.bodySmall?.copyWith(
                    fontSize: 11,
                    color: TileColors.accent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One address, already chipped, with its own X to remove it.
class _RemovableChip extends StatelessWidget {
  const _RemovableChip({super.key, required this.text, required this.onRemove});

  final String text;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontSize: 12, color: TileColors.accent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: TileColors.accent, width: TileMetrics.bevel),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(text.toUpperCase(), style: style),
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

/// One text field: a small muted label over an underline-bordered
/// `TextField`, the same shape [mail_setup_sheet]'s own fields take.
class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final int maxLines;

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
