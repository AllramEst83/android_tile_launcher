import 'dart:async';

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// The sheet behind home's "+ ADD TILE": every system tile kind not already
/// pinned (there is at most one of each — a second clock would show the same
/// time). Tapping one pins it via [GridState.pinSystemTile] and closes.
Future<void> showAddTileSheet(
  BuildContext context, {
  required GridState gridState,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    builder: (BuildContext sheetContext) {
      final List<TileKind> available = <TileKind>[
        for (final TileKind kind in TileKind.values)
          if (kind != TileKind.app && !gridState.isPinned(kind.name)) kind,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final TileKind kind in available)
              _AddTileOption(
                label: displayNameOf(kind),
                onTap: () {
                  // Already pinned and showing once this returns; only the
                  // save to disk is still pending (see GridState's failure
                  // contract) and there is no error surface here for it.
                  unawaited(gridState.pinSystemTile(kind));
                  Navigator.pop(sheetContext);
                },
              ),
          ],
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
