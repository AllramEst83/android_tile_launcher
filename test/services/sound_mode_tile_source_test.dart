import 'package:android_tile_launcher/model/sound_mode.dart';
import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/sound_mode_tile_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_system_control_service.dart';

void main() {
  test('reads the ringer mode, fresh every time', () async {
    final control = FakeSystemControlService(sound: SoundMode.vibrate);
    final source = SoundModeTileSource(control: control);

    expect(await source.read(), const SoundContent(mode: SoundMode.vibrate));

    await control.setSoundMode(SoundMode.silent);

    expect(await source.read(), const SoundContent(mode: SoundMode.silent));
  });
}
