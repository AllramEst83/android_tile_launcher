import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/agenda_tile_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_agenda_repository.dart';

void main() {
  test('reads from now to the end of the seventh day', () async {
    final FakeAgendaRepository repository = FakeAgendaRepository(
      const AgendaNeedsPermission(),
    );
    final DateTime now = DateTime(2026, 9, 28, 10, 30);

    final TileContent content = await AgendaTileSource(
      repository: repository,
      clock: () => now,
    ).read();

    expect(repository.lastFrom, now);
    expect(repository.lastTo, DateTime(2026, 10, 5));
    expect(content, isA<AgendaContent>());
    expect((content as AgendaContent).now, now);
    expect(content.snapshot, const AgendaNeedsPermission());
  });

  test('the number of days can be chosen', () async {
    final FakeAgendaRepository repository = FakeAgendaRepository();

    await AgendaTileSource(
      repository: repository,
      days: 1,
      clock: () => DateTime(2026, 9, 28, 23),
    ).read();

    expect(repository.lastTo, DateTime(2026, 9, 29));
  });
}
