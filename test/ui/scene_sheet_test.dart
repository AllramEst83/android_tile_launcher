import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/scene_animation.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/scene_sheet.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_local_store.dart';

Future<SettingsState> _open(WidgetTester tester) async {
  final SettingsState settings = SettingsState(store: InMemoryLocalStore());
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showSceneSheet(context, settings: settings),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return settings;
}

void main() {
  testWidgets('lists every animation, by its own label', (
    WidgetTester tester,
  ) async {
    await _open(tester);

    for (final SceneAnimation animation in SceneAnimation.values) {
      expect(find.byKey(sceneOptionKey(animation)), findsOneWidget);
      expect(find.text(animation.label), findsOneWidget);
    }
  });

  testWidgets('the current animation is marked selected', (
    WidgetTester tester,
  ) async {
    await _open(tester);

    expect(
      tester
          .widget<PadKey>(find.byKey(sceneOptionKey(SceneAnimation.rocket)))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<PadKey>(find.byKey(sceneOptionKey(SceneAnimation.flower)))
          .selected,
      isFalse,
    );
  });

  testWidgets('tapping one applies it and closes the sheet', (
    WidgetTester tester,
  ) async {
    final SettingsState settings = await _open(tester);

    await tester.tap(find.byKey(sceneOptionKey(SceneAnimation.palmTree)));
    await tester.pumpAndSettle();

    expect(settings.settings.sceneAnimation, SceneAnimation.palmTree);
    expect(find.text(Messages.sceneTitle), findsNothing);
  });

  testWidgets('the close key leaves the animation as it was', (
    WidgetTester tester,
  ) async {
    final SettingsState settings = await _open(tester);

    await tester.tap(find.byKey(sceneCloseKey));
    await tester.pumpAndSettle();

    expect(settings.settings.sceneAnimation, SceneAnimation.rocket);
    expect(find.text(Messages.sceneTitle), findsNothing);
  });
}
