import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/alarm_tile_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_alarm_service.dart';

void main() {
  test('reads the next alarm fresh every time', () async {
    final service = FakeAlarmService();
    final source = AlarmTileSource(service: service);

    expect(await source.read(), const AlarmContent(next: null));

    final due = DateTime(2026, 9, 28, 7, 30);
    service.nextAlarm = due;

    expect(await source.read(), AlarmContent(next: due));
  });
}
