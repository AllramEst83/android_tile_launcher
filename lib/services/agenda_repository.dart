import 'package:android_tile_launcher/model/agenda_snapshot.dart';

/// The calendar for the agenda tile and its sheet. Both calls never throw:
/// every failure is an [AgendaSnapshot] the tile can word.
abstract interface class AgendaRepository {
  /// Events overlapping [from, to), or why there are none to show.
  Future<AgendaSnapshot> between(DateTime from, DateTime to);

  /// Asks Android for calendar access (showing its dialog if it still will).
  /// Only ever called from a tap: a permission dialog must never appear on its
  /// own. The outcome shows up in the next [between].
  Future<void> allow();
}
