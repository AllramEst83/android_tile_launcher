import 'dart:async';

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/services/contacts_repository.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/ui/contact_picker.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// The sheet behind home's "+ ADD TILE": every system tile kind not already
/// pinned (there is at most one of each — a second clock would show the same
/// time). Tapping one pins it via [GridState.pinSystemTile] and closes.
/// CONTACT is always offered (one tile per person) and opens the contact
/// picker instead of pinning at once.
Future<void> showAddTileSheet(
  BuildContext context, {
  required GridState gridState,
  required ContactsRepository contacts,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    // The list grows with each tile kind; a sheet capped at the default
    // height would overflow on a short screen.
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      final List<TileKind> available = <TileKind>[
        for (final TileKind kind in TileKind.values)
          if (kind != TileKind.app &&
              (kind == TileKind.contact || !gridState.isPinned(kind.name)))
            kind,
      ];
      if (available.isEmpty) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TileMetrics.margin),
            child: Text(
              Messages.noTilesToAdd,
              style: Theme.of(sheetContext).textTheme.bodyMedium,
            ),
          ),
        );
      }
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final TileKind kind in available)
                _AddTileOption(
                  label: displayNameOf(kind),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (kind == TileKind.contact) {
                      unawaited(
                        showContactPicker(
                          context,
                          contacts: contacts,
                          gridState: gridState,
                        ),
                      );
                      return;
                    }
                    // Already pinned and showing once this returns; only the
                    // save to disk is still pending (see GridState's failure
                    // contract) and there is no error surface here for it.
                    unawaited(gridState.pinSystemTile(kind));
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _AddTileOption extends StatelessWidget {
  const _AddTileOption({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TileMetrics.margin,
          vertical: TileMetrics.gutter * 2,
        ),
        child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
