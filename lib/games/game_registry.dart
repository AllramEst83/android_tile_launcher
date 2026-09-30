import 'package:android_tile_launcher/games/game_module.dart';
import 'package:android_tile_launcher/games/tetris/tetris_module.dart';

/// Every game the launcher knows about, in the order offered on the add-tile
/// sheet. Add a game by adding it here — see .agents/architecture.md's
/// "Adding a tile kind" for how the rest (a pinned [TileKind.game] tile, the
/// add-tile sheet, `tile_view.dart`'s dispatch) reads this list generically
/// rather than switching on individual games.
const List<GameModule> gameModules = <GameModule>[TetrisModule()];

/// The module with this [id], or `null` if it no longer exists — a tile
/// pinned to a game later removed from [gameModules].
GameModule? gameModuleById(String id) {
  for (final GameModule module in gameModules) {
    if (module.id == id) return module;
  }
  return null;
}
