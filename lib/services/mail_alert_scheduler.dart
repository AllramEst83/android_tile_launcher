import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/mail_alert.dart';
import 'package:android_tile_launcher/services/mail_alert_service.dart';
import 'package:android_tile_launcher/services/mail_alert_worker.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:workmanager/workmanager.dart';

/// Starts and stops the background look for new mail to match the setting.
abstract interface class MailAlertScheduler {
  /// Makes the background work what [mode] says: nothing for off, one look
  /// about every 15 minutes for periodic, and for instant a foreground
  /// service holding a connection open (with the 15-minute look as well, for
  /// when Android stops the service). Never throws.
  Future<void> apply(MailAlertMode mode);

  /// Asks Android to leave the launcher out of battery saving, which can
  /// otherwise stop the instant mode's service, and says whether it is. A
  /// system dialog; only ever called from a tap.
  Future<bool> allowRunningInBackground();
}

/// [MailAlertScheduler] on Android's WorkManager (through `workmanager`) and
/// a foreground service (through `flutter_foreground_task`); the only file
/// that knows either package. The jobs run [mailAlertDispatcher] and
/// [mailAlertServiceCallback] in background isolates, so they work with the
/// launcher closed.
class WorkmanagerMailAlertScheduler implements MailAlertScheduler {
  const WorkmanagerMailAlertScheduler();

  static const String _name = 'mail_alert_check';
  static const int _serviceId = 7001;

  /// Must run once at start-up, before [apply].
  Future<void> initialize() async {
    await Workmanager().initialize(mailAlertDispatcher);
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'mail_watch',
        channelName: Messages.mailAlertServiceChannel,
        channelDescription: Messages.mailAlertServiceChannelNote,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        // The loop is driven by the server, not a timer.
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  @override
  Future<void> apply(MailAlertMode mode) async {
    try {
      switch (mode) {
        case MailAlertMode.off:
          await Workmanager().cancelByUniqueName(_name);
          await _stopService();
        case MailAlertMode.periodic:
          await _registerLook();
          await _stopService();
        case MailAlertMode.instant:
          await _registerLook();
          await _startService();
      }
    } on Object {
      // A job that cannot be scheduled is only a missing alert.
    }
  }

  Future<void> _registerLook() => Workmanager().registerPeriodicTask(
    _name,
    _name,
    frequency: const Duration(minutes: 15),
    // No network, no look.
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );

  Future<void> _startService() async {
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      serviceTypes: <ForegroundServiceTypes>[ForegroundServiceTypes.specialUse],
      notificationTitle: Messages.mailAlertServiceTitle,
      notificationText: Messages.mailAlertServiceText,
      callback: mailAlertServiceCallback,
    );
  }

  Future<void> _stopService() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  @override
  Future<bool> allowRunningInBackground() async {
    try {
      if (await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        return true;
      }
      return await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    } on Object {
      return false;
    }
  }
}
