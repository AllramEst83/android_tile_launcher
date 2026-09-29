import 'dart:async';
import 'dart:math' as math;

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/alpha_grouping.dart';
import 'package:android_tile_launcher/model/contact.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/services/contacts_repository.dart';
import 'package:android_tile_launcher/services/contacts_service.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/ui/clear_field_button.dart';
import 'package:android_tile_launcher/ui/grouped_list.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key contactSearchKey = ValueKey<String>('contact-search');
const Key contactClearSearchKey = ValueKey<String>('contact-clear-search');
Key contactRowKey(String key) => ValueKey<String>('contact-row-$key');

/// The sheet behind "+ ADD TILE" > CONTACT: everyone in the phone book with a
/// number, filed A to Z then Å Ä Ö with a jump index like the app drawer, or a
/// flat list while the search field has text; tapping one pins them as a tile
/// and closes. Opening it is what asks for contacts access, if that has not
/// been given.
Future<void> showContactPicker(
  BuildContext context, {
  required ContactsRepository contacts,
  required GridState gridState,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    // Without this the sheet is laid out from the very top of the screen, and
    // its context is told there is no status bar.
    useSafeArea: true,
    builder: (BuildContext sheetContext) {
      final MediaQueryData media = MediaQuery.of(sheetContext);
      // Never taller than the room between the status bar and the keyboard: a
      // sheet a fixed share of the screen tall, pushed up by the keyboard,
      // ran up under the status bar with the search field over the clock.
      final double room =
          media.size.height -
          media.viewInsets.bottom -
          media.padding.top -
          TileMetrics.margin;
      return Padding(
        // Keep the list and the search field above the keyboard.
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        // A fixed height, not "as tall as the list": the sheet would otherwise
        // shrink and grow as the search narrows the list, and the jump index
        // needs a definite height to lay its letters out in.
        child: SizedBox(
          height: math.min(media.size.height * 0.8, room),
          child: _ContactPicker(contacts: contacts, gridState: gridState),
        ),
      );
    },
  );
}

class _ContactPicker extends StatefulWidget {
  const _ContactPicker({required this.contacts, required this.gridState});

  final ContactsRepository contacts;
  final GridState gridState;

  @override
  State<_ContactPicker> createState() => _ContactPickerState();
}

class _ContactPickerState extends State<_ContactPicker> {
  late final Future<ContactsResult> _result = widget.contacts.all();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearQuery() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              key: contactSearchKey,
              controller: _searchController,
              onChanged: (String value) => setState(() => _query = value),
              style: text.bodyMedium,
              cursorColor: TileColors.textBright,
              decoration: InputDecoration(
                // Roomy, not dense: a thin field is hard to hit and to read.
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                hintText: Messages.contactSearch,
                hintStyle: text.bodyMedium?.copyWith(color: TileColors.muted),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: TileColors.bezel),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: TileColors.textBright),
                ),
                suffixIcon: _query.isNotEmpty
                    ? ClearFieldButton(
                        key: contactClearSearchKey,
                        onTap: _clearQuery,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: TileMetrics.gutter),
            Expanded(
              child: FutureBuilder<ContactsResult>(
                future: _result,
                builder: (context, snapshot) {
                  final ContactsResult? result = snapshot.data;
                  if (result == null) {
                    return Text(
                      Messages.contactsLoading,
                      style: text.bodyMedium,
                    );
                  }
                  return switch (result) {
                    ContactsRead(:final List<Contact> contacts) => _list(
                      context,
                      contacts,
                    ),
                    ContactsDenied(:final bool permanent) => Text(
                      permanent
                          ? Messages.contactsAllowInSettings
                          : Messages.contactsNotAllowed,
                      style: text.bodyMedium,
                    ),
                    ContactsUnavailable(:final String reason) => Text(
                      reason.toUpperCase(),
                      style: text.bodyMedium,
                    ),
                    // The repository asks first, so this cannot come back.
                    ContactsNoAccess() => Text(
                      Messages.contactsNotAllowed,
                      style: text.bodyMedium,
                    ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<Contact> contacts) {
    final TextTheme text = Theme.of(context).textTheme;
    final String query = _query.trim().toLowerCase();
    final List<Contact> shown = <Contact>[
      for (final Contact c in contacts)
        // One tile per person, so anyone already pinned is not offered again.
        if (!widget.gridState.isPinned(contactTileId(c.key)) &&
            (query.isEmpty || c.name.toLowerCase().contains(query)))
          c,
    ];
    if (shown.isEmpty) {
      return Text(
        contacts.isEmpty ? Messages.contactsNone : Messages.contactsNoMatch,
        style: text.bodyMedium,
      );
    }
    if (query.isEmpty) {
      return GroupedList<Contact>(
        items: shown,
        label: (Contact c) => c.name,
        rowBuilder: _row,
      );
    }
    // Searching: a flat list, in phone-book order, without headers or index.
    return ListView(
      children: <Widget>[
        for (final Contact c in _inPhoneBookOrder(shown)) _row(context, c),
      ],
    );
  }

  /// By name as a Swedish phone book files it (A to Z, then Å, Ä, Ö), the way
  /// `GroupedList` does, for the flat search results.
  static List<Contact> _inPhoneBookOrder(List<Contact> contacts) {
    final List<(String, int, Contact)> keyed = <(String, int, Contact)>[
      for (final (int i, Contact c) in contacts.indexed)
        (alphabeticalKey(c.name), i, c),
    ];
    keyed.sort((a, b) {
      final int byName = a.$1.compareTo(b.$1);
      return byName != 0 ? byName : a.$2.compareTo(b.$2);
    });
    return <Contact>[for (final (_, _, c) in keyed) c];
  }

  Widget _row(BuildContext context, Contact contact) {
    final TextTheme text = Theme.of(context).textTheme;
    return InkWell(
      key: contactRowKey(contact.key),
      onTap: () {
        // In effect at once; only the save is still pending.
        unawaited(
          widget.gridState.pinContact(key: contact.key, name: contact.name),
        );
        Navigator.pop(context);
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(
          horizontal: TileMetrics.margin,
          vertical: TileMetrics.gutter,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: TileColors.bezel)),
        ),
        child: Text(
          contact.name.toUpperCase(),
          style: text.bodyMedium?.copyWith(color: TileColors.textBright),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
