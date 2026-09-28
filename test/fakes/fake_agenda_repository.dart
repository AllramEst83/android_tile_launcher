import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/services/agenda_repository.dart';

/// Answers with [snapshot]; [allow] switches to [afterAllow] and counts how
/// often each was asked. Remembers the last range asked for.
class FakeAgendaRepository implements AgendaRepository {
  FakeAgendaRepository([
    this.snapshot = const AgendaNeedsPermission(),
    this.afterAllow,
  ]);

  AgendaSnapshot snapshot;
  AgendaSnapshot? afterAllow;
  int betweenCalls = 0;
  int allowCalls = 0;
  DateTime? lastFrom;
  DateTime? lastTo;

  @override
  Future<AgendaSnapshot> between(DateTime from, DateTime to) async {
    betweenCalls++;
    lastFrom = from;
    lastTo = to;
    return snapshot;
  }

  @override
  Future<void> allow() async {
    allowCalls++;
    snapshot = afterAllow ?? snapshot;
  }
}
