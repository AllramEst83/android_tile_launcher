import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/toggle_tile_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_system_control_service.dart';

void main() {
  test('reads the control service\'s current state for its own kind', () async {
    final control = FakeSystemControlService(
      initial: {TileKind.flashlight: true},
    );
    final source = ToggleTileSource(
      kind: TileKind.flashlight,
      control: control,
    );

    final content = await source.read();

    expect(content, isA<ToggleContent>());
    expect((content as ToggleContent).on, isTrue);
  });

  test('a fresh read reflects a state change made elsewhere', () async {
    final control = FakeSystemControlService();
    final source = ToggleTileSource(
      kind: TileKind.flashlight,
      control: control,
    );

    expect((await source.read() as ToggleContent).on, isFalse);

    await control.setOn(TileKind.flashlight, true);

    expect((await source.read() as ToggleContent).on, isTrue);
  });
}
