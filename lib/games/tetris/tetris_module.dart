import 'package:android_tile_launcher/games/game_module.dart';
import 'package:android_tile_launcher/games/tetris/tetris_screen.dart';
import 'package:android_tile_launcher/messages.dart';
import 'package:flutter/widgets.dart';

class TetrisModule extends GameModule {
  const TetrisModule();

  @override
  String get id => 'tetris';

  @override
  String get label => Messages.tetrisTitle;

  @override
  Future<void> play(BuildContext context) => showTetris(context);
}
