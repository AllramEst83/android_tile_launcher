/// Whether this launcher is the phone's Home app, and a way to change that.
/// Android decides which app is Home; a launcher can only ask and show the
/// system's own chooser.
abstract interface class HomeRoleService {
  /// Whether this launcher is what the Home button goes to; `null` when that
  /// cannot be found out. Never throws.
  Future<bool?> isDefault();

  /// Opens Android's settings page for choosing the Home app. `true` once it
  /// was opened. Never throws.
  Future<bool> openSettings();
}
