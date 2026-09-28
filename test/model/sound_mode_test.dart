import 'package:android_tile_launcher/model/sound_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('next cycles normal, vibrate, silent and back to normal', () {
    expect(SoundMode.normal.next, SoundMode.vibrate);
    expect(SoundMode.vibrate.next, SoundMode.silent);
    expect(SoundMode.silent.next, SoundMode.normal);
  });

  test('every mode has a distinct label', () {
    final labels = SoundMode.values.map((m) => m.label).toSet();
    expect(labels, hasLength(SoundMode.values.length));
  });
}
