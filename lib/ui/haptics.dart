import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The two strengths the launcher uses: a light tick for a tap, a firmer one
/// for a press that starts something (the grid editor).
enum Haptic { tap, press }

/// Buzzes the phone, unless haptics are switched off in settings. Reads the
/// setting without depending on it, so it is safe from an event handler.
/// Never throws and does not wait: a phone with no vibrator just does nothing.
void haptic(BuildContext context, Haptic kind) {
  final bool on = SettingsScope.stateOf(context)?.settings.haptics ?? true;
  if (!on) return;
  switch (kind) {
    case Haptic.tap:
      HapticFeedback.lightImpact();
    case Haptic.press:
      HapticFeedback.mediumImpact();
  }
}
