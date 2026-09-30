import 'package:android_tile_launcher/games/game_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tetris is registered', () {
    expect(gameModules.map((m) => m.id), contains('tetris'));
  });

  test('every module has a unique, non-empty id and label', () {
    final ids = gameModules.map((m) => m.id).toSet();
    expect(ids, hasLength(gameModules.length));
    for (final module in gameModules) {
      expect(module.id, isNotEmpty);
      expect(module.label, isNotEmpty);
    }
  });

  test('gameModuleById finds a registered module by id', () {
    expect(gameModuleById('tetris')?.label, 'TETRIS');
  });

  test('gameModuleById returns null for an unknown id', () {
    expect(gameModuleById('does-not-exist'), isNull);
  });
}
