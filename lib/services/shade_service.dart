/// Pulls Android's notification shade or quick-settings panel down. Nothing
/// here reads or changes what is in them; it only opens them, as a swipe from
/// the top of the screen would.
abstract interface class ShadeService {
  /// Opens the notification shade. `true` once the phone accepted it; `false`
  /// when this phone or Android version refuses. Never throws.
  Future<bool> expandNotifications();

  /// Opens the quick-settings panel. Same contract as [expandNotifications].
  Future<bool> expandQuickSettings();
}
