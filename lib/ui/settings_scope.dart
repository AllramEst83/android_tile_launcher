import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:flutter/widgets.dart';

/// Makes the launcher's [SettingsState] available to every widget below it (the
/// home mosaic reads its column count and gap from here), and rebuilds the ones
/// that asked when a setting changes.
class SettingsScope extends InheritedNotifier<SettingsState> {
  const SettingsScope({
    super.key,
    required SettingsState state,
    required super.child,
  }) : super(notifier: state);

  /// The current settings, and the widget is rebuilt when they change. Without
  /// a scope (a widget tested on its own) they are the defaults.
  static LauncherSettings of(BuildContext context) {
    final SettingsScope? scope = context
        .dependOnInheritedWidgetOfExactType<SettingsScope>();
    return scope?.notifier?.settings ?? const LauncherSettings();
  }

  /// The state itself, for changing settings; `null` without a scope.
  static SettingsState? stateOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SettingsScope>()?.notifier;
}
