import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/text_tv_repository.dart';
import 'package:android_tile_launcher/services/tile_source.dart';

/// The Text TV tile's content: the headline page ([page], 100), for the tile
/// to show a few of its headlines from.
class TextTvTileSource implements TileSource {
  const TextTvTileSource({required this.repository, this.page = 100});

  final TextTvRepository repository;
  final int page;

  @override
  Future<TileContent> read() async =>
      TextTvContent(result: await repository.page(page));
}
