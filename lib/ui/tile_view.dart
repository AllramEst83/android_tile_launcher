import 'dart:async';

import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/sound_mode.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/clock_tile_source.dart';
import 'package:android_tile_launcher/services/sound_mode_tile_source.dart';
import 'package:android_tile_launcher/services/system_control_service.dart';
import 'package:android_tile_launcher/services/toggle_tile_source.dart';
import 'package:android_tile_launcher/ui/clock_tile_view.dart';
import 'package:android_tile_launcher/ui/state_tile_view.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_poller.dart';
import 'package:flutter/material.dart';

/// The chrome every tile shares regardless of kind: a flat VIC-II fill with a
/// 2px light-top-left/dark-bottom-right bevel (never a shadow or gradient),
/// or — in the grid editor — a bright outline if [selected] and a delete
/// badge if [onDelete] is given. [content] draws whatever the tile's kind
/// wants inside that frame; see [tileContent].
class TileView extends StatelessWidget {
  const TileView({
    super.key,
    required this.colour,
    required this.content,
    required this.onTap,
    this.onLongPress,
    this.selected = false,
    this.onDelete,
    this.deleteKey,
  });

  final C64Colour colour;
  final Widget content;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final VoidCallback? onDelete;

  /// Key for the delete badge, so a test can target one tile's badge among
  /// several. Only meaningful when [onDelete] is given.
  final Key? deleteKey;

  @override
  Widget build(BuildContext context) {
    final Color fill = colour.fill;
    final Color light = Color.lerp(fill, C64.white, 0.35)!;
    final Color dark = Color.lerp(fill, C64.black, 0.35)!;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          border: selected
              ? Border.all(color: C64.white, width: TileMetrics.bevel * 2)
              : Border(
                  top: BorderSide(color: light, width: TileMetrics.bevel),
                  left: BorderSide(color: light, width: TileMetrics.bevel),
                  right: BorderSide(color: dark, width: TileMetrics.bevel),
                  bottom: BorderSide(color: dark, width: TileMetrics.bevel),
                ),
        ),
        padding: const EdgeInsets.all(TileMetrics.gutter / 2),
        child: Stack(
          children: <Widget>[
            content,
            if (onDelete != null)
              Positioned(
                top: 0,
                right: 0,
                child: _DeleteBadge(key: deleteKey, onTap: onDelete!),
              ),
          ],
        ),
      ),
    );
  }
}

/// What goes inside [TileView] for [tile], dispatched by kind — the one
/// place a new tile kind's view gets wired in (see "Adding a tile kind" in
/// .agents/architecture.md). [labelFor] only matters for [TileKind.app].
/// [systemControl] backs every toggle kind's read and tap; [interactive]
/// turns tap-to-toggle off in the grid editor, where a tap selects the tile
/// instead.
Widget tileContent(
  Tile tile, {
  required String Function(Tile tile) labelFor,
  required SystemControlService systemControl,
  bool interactive = true,
}) {
  switch (tile.kind) {
    case TileKind.app:
      return AppTileContent(label: labelFor(tile), ink: tile.colour.ink);
    case TileKind.clock:
      return TilePoller(
        source: const ClockTileSource(),
        interval: const Duration(seconds: 30),
        builder: (context, content, refreshNow) => ClockTileContentView(
          content: content as ClockContent,
          ink: tile.colour.ink,
        ),
      );
    case TileKind.soundMode:
      return TilePoller(
        source: SoundModeTileSource(control: systemControl),
        interval: const Duration(seconds: 5),
        builder: (context, content, refreshNow) {
          final SoundMode mode = (content as SoundContent).mode;
          return StateTileContentView(
            label: displayNameOf(tile.kind),
            state: mode.label,
            ink: tile.colour.ink,
            onTap: interactive
                ? () => unawaited(
                    _act(
                      () => systemControl.setSoundMode(mode.next),
                      refreshNow,
                    ),
                  )
                : null,
          );
        },
      );
    case TileKind.flashlight:
      return TilePoller(
        source: ToggleTileSource(kind: tile.kind, control: systemControl),
        interval: const Duration(seconds: 5),
        builder: (context, content, refreshNow) {
          final bool on = (content as ToggleContent).on;
          return StateTileContentView(
            label: displayNameOf(tile.kind),
            state: on ? '[ON]' : '[OFF]',
            ink: tile.colour.ink,
            onTap: interactive
                ? () => unawaited(
                    _act(() => systemControl.setOn(tile.kind, !on), refreshNow),
                  )
                : null,
          );
        },
      );
  }
}

/// Runs a state-changing [action], then re-reads the tile so it shows the
/// result at once instead of at the next poll.
Future<void> _act(
  Future<void> Function() action,
  VoidCallback refreshNow,
) async {
  await action();
  refreshNow();
}

/// An app tile's content: a monochrome glyph — its label's first letter,
/// since no real app icons are drawn yet (plan.md, "Not implemented") — and
/// the label itself along the bottom edge.
class AppTileContent extends StatelessWidget {
  const AppTileContent({super.key, required this.label, required this.ink});

  final String label;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final String glyph = label.isEmpty ? '?' : label[0].toUpperCase();
    return Stack(
      children: <Widget>[
        Center(
          child: FittedBox(
            child: Text(
              glyph,
              style: TextStyle(fontFamily: kPixelFontFamily, color: ink),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: kPixelFontFamily,
              fontSize: 8,
              color: ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DeleteBadge extends StatelessWidget {
  const _DeleteBadge({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        color: C64.black,
        child: const Text(
          'X',
          style: TextStyle(
            fontFamily: kPixelFontFamily,
            fontSize: 8,
            color: C64.white,
          ),
        ),
      ),
    );
  }
}
