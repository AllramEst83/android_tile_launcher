import 'package:flutter/widgets.dart';

/// A game that can be pinned to the mosaic and launched fullscreen. Adding a
/// game means adding one of these to `gameModules` in `game_registry.dart` —
/// nothing else in the tile-grid plumbing (`GridState.pinGame`, the add-tile
/// sheet, `tile_view.dart`'s dispatch) needs to know what a game actually
/// does. This lives outside `model/` (which stays pure Dart) because [play]
/// needs a `BuildContext`, and outside `services/` (an abstraction over the
/// platform) because a game is content, not a platform capability.
abstract class GameModule {
  const GameModule();

  /// Stable id used in a pinned game tile's id (`game:<id>`) and to persist
  /// which games are pinned — never change once shipped, or existing pins
  /// orphan.
  String get id;

  /// Shown on the tile face and the add-tile sheet.
  String get label;

  /// Opens the game, fullscreen, returning once the player backs out.
  Future<void> play(BuildContext context);
}
