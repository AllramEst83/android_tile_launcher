import 'dart:async';

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/scene_animation.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key sceneCloseKey = ValueKey<String>('scene-close');
Key sceneOptionKey(SceneAnimation animation) =>
    ValueKey<String>('scene-option-${animation.name}');

/// What a tap on the Scene tile opens: every animation, the current one
/// marked, each a single tap away — there is nothing else to configure, so
/// picking one closes the sheet at once rather than needing an APPLY.
Future<void> showSceneSheet(
  BuildContext context, {
  required SettingsState settings,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    useSafeArea: true,
    builder: (BuildContext sheetContext) => _SceneSheet(settings: settings),
  );
}

class _SceneSheet extends StatelessWidget {
  const _SceneSheet({required this.settings});

  final SettingsState settings;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final SceneAnimation current = settings.settings.sceneAnimation;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // So the title row is not flush against the sheet's own top edge.
            const SizedBox(height: TileMetrics.gutter),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(Messages.sceneTitle, style: text.bodyMedium),
                ),
                SizedBox(
                  width: 48,
                  child: PadKey(
                    key: sceneCloseKey,
                    label: 'X',
                    height: 32,
                    fontSize: 12,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TileMetrics.margin),
            for (final SceneAnimation animation in SceneAnimation.values)
              Padding(
                padding: const EdgeInsets.only(bottom: TileMetrics.gutter),
                child: PadKey(
                  key: sceneOptionKey(animation),
                  label: animation.label,
                  selected: animation == current,
                  height: 44,
                  fontSize: 12,
                  onTap: () {
                    Navigator.of(context).pop();
                    unawaited(
                      settings.update(
                        settings.settings.copyWith(sceneAnimation: animation),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
