import 'package:android_tile_launcher/model/mail_alert.dart';

/// Shows new-mail notifications, and says when one is tapped.
abstract interface class MailNotifier {
  /// Shows [alerts], each its own notification. Never throws.
  Future<void> show(List<MailAlert> alerts);

  /// Asks Android for permission to notify (a dialog, on Android 13 and
  /// newer), and says whether it is given. Only ever called from a tap.
  Future<bool> requestPermission();

  /// Whether notifications can be shown now.
  Future<bool> isPermitted();
}
