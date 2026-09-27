import 'dart:async';

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Long-press on an app row anywhere in the drawer opens this: pin/unpin,
/// Android's own "App info" screen, and uninstall (which opens Android's own
/// confirmation — tapping here is not itself the confirmation).
Future<void> showQuickActions(
  BuildContext context, {
  required AppInfo app,
  required GridState gridState,
  required Future<bool> Function(String packageName) onOpenDetails,
  required Future<bool> Function(String packageName) onUninstall,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    builder: (BuildContext sheetContext) {
      final bool pinned = gridState.isPinned(app.packageName);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _QuickAction(
              label: pinned ? Messages.unpinFromGrid : Messages.pinToGrid,
              onTap: () {
                // The pin/unpin already took effect in memory and notified;
                // only the save to disk is still pending, and nothing here
                // needs to react to it failing.
                unawaited(gridState.toggle(app.packageName));
                Navigator.pop(sheetContext);
              },
            ),
            _QuickAction(
              label: Messages.appDetails,
              onTap: () {
                Navigator.pop(sheetContext);
                unawaited(onOpenDetails(app.packageName));
              },
            ),
            _QuickAction(
              label: Messages.uninstall,
              onTap: () {
                Navigator.pop(sheetContext);
                unawaited(onUninstall(app.packageName));
              },
            ),
          ],
        ),
      );
    },
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.label, required this.onTap});

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
