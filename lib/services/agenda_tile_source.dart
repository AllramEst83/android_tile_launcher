import 'package:android_tile_launcher/model/agenda_format.dart';
import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/agenda_repository.dart';
import 'package:android_tile_launcher/services/tile_source.dart';

DateTime _systemNow() => DateTime.now();

/// The agenda tile's content: what is still to come in the next [days] days
/// (events already over are not asked for).
class AgendaTileSource implements TileSource {
  const AgendaTileSource({
    required this.repository,
    this.days = 7,
    this.clock = _systemNow,
  });

  final AgendaRepository repository;
  final int days;
  final DateTime Function() clock;

  @override
  Future<TileContent> read() async {
    final DateTime now = clock();
    return AgendaContent(
      snapshot: await repository.between(now, addDays(startOfDay(now), days)),
      now: now,
    );
  }
}
