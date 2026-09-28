import 'dart:async';

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/alpha_grouping.dart';
import 'package:android_tile_launcher/model/contact.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/services/contacts_repository.dart';
import 'package:android_tile_launcher/services/contacts_service.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key contactSearchKey = ValueKey<String>('contact-search');
Key contactRowKey(String key) => ValueKey<String>('contact-row-$key');

/// The sheet behind "+ ADD TILE" > CONTACT: everyone in the phone book with a
/// number, searchable by name; tapping one pins them as a tile and closes.
/// Opening it is what asks for contacts access, if that has not been given.
Future<void> showContactPicker(
  BuildContext context, {
  required ContactsRepository contacts,
  required GridState gridState,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => Padding(
      // Keep the list and the search field above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
        ),
        child: _ContactPicker(contacts: contacts, gridState: gridState),
      ),
    ),
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
  late final Future<ContactsResult> _result = widget.contacts.all().then(
    _inPhoneBookOrder,
  );
  String _query = '';

  /// By name as a Swedish phone book files it, the way the app drawer does
  /// (A to Z, then Å, Ä, Ö), not in the provider's own order, which puts Ä
  /// among the A's.
  static ContactsResult _inPhoneBookOrder(ContactsResult result) {
    if (result is! ContactsRead) return result;
    final List<(String, int, Contact)> keyed = <(String, int, Contact)>[
      for (final (int i, Contact c) in result.contacts.indexed)
        (alphabeticalKey(c.name), i, c),
    ];
    keyed.sort((a, b) {
      final int byName = a.$1.compareTo(b.$1);
      return byName != 0 ? byName : a.$2.compareTo(b.$2);
    });
    return ContactsRead(<Contact>[for (final (_, _, c) in keyed) c]);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              key: contactSearchKey,
              onChanged: (String value) => setState(() => _query = value),
              style: text.bodyMedium,
              cursorColor: TileColors.textBright,
              decoration: InputDecoration(
                isDense: true,
                hintText: Messages.contactSearch,
                hintStyle: text.bodyMedium?.copyWith(color: C64.lightGrey),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: TileColors.bezel),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: TileColors.textBright),
                ),
              ),
            ),
            const SizedBox(height: TileMetrics.gutter),
            Flexible(
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
    return ListView.builder(
      shrinkWrap: true,
      itemCount: shown.length,
      itemBuilder: (BuildContext context, int index) {
        final Contact contact = shown[index];
        return InkWell(
          key: contactRowKey(contact.key),
          onTap: () {
            // In effect at once; only the save is still pending.
            unawaited(
              widget.gridState.pinContact(key: contact.key, name: contact.name),
            );
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              contact.name.toUpperCase(),
              style: text.bodyMedium?.copyWith(color: TileColors.textBright),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}
