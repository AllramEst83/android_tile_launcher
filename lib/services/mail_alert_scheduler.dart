import 'package:android_tile_launcher/model/mail_alert.dart';
import 'package:android_tile_launcher/services/mail_alert_worker.dart';
import 'package:workmanager/workmanager.dart';

/// Starts and stops the background look for new mail to match the setting.
abstract interface class MailAlertScheduler {
  /// Makes the background work what [mode] says: nothing for off, one look
  /// about every 15 minutes for periodic. Never throws.
  Future<void> apply(MailAlertMode mode);
}

/// [MailAlertScheduler] on Android's WorkManager (through `workmanager`),
/// the only file that knows the package. The job runs [mailAlertDispatcher]
/// in a background isolate, so it works with the launcher closed.
class WorkmanagerMailAlertScheduler implements MailAlertScheduler {
  const WorkmanagerMailAlertScheduler();

  static const String _name = 'mail_alert_check';

  /// Must run once at start-up, before [apply].
  Future<void> initialize() async {
    await Workmanager().initialize(mailAlertDispatcher);
  }

  @override
  Future<void> apply(MailAlertMode mode) async {
    try {
      switch (mode) {
        case MailAlertMode.off:
          await Workmanager().cancelByUniqueName(_name);
        case MailAlertMode.periodic:
          await Workmanager().registerPeriodicTask(
            _name,
            _name,
            frequency: const Duration(minutes: 15),
            // No network, no look.
            constraints: Constraints(networkType: NetworkType.connected),
            existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
          );
      }
    } on Object {
      // A job that cannot be scheduled is only a missing alert.
    }
  }
}
