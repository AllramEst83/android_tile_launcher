import 'dart:async';

import 'package:android_tile_launcher/services/flutter_secret_store.dart';
import 'package:android_tile_launcher/services/imap_mail_service.dart';
import 'package:android_tile_launcher/services/local_mail_notifier.dart';
import 'package:android_tile_launcher/services/mail_account.dart';
import 'package:android_tile_launcher/services/mail_alert_runner.dart';
import 'package:android_tile_launcher/services/mail_idle_loop.dart';
import 'package:android_tile_launcher/services/shared_preferences_local_store.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// What the foreground service runs, in its own isolate. Kept apart from the
/// scheduler so the isolate does not drag the whole app in.
@pragma('vm:entry-point')
void mailAlertServiceCallback() {
  FlutterForegroundTask.setTaskHandler(_MailIdleHandler());
}

/// Hands the service's task to a [MailIdleLoop]: starts it with the service
/// and stops it, connection and all, when the service ends.
class _MailIdleHandler extends TaskHandler {
  MailIdleLoop? _loop;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final ImapMailService mail = ImapMailService(
      accounts: MailAccountStore(FlutterSecretStore()),
    );
    final MailIdleLoop loop = MailIdleLoop(
      mail: mail,
      runner: MailAlertRunner(
        mail: mail,
        store: SharedPreferencesLocalStore(),
        notifier: LocalMailNotifier(),
      ),
    );
    _loop = loop;
    unawaited(loop.run());
  }

  // The loop is driven by the server, not by a timer.
  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _loop?.stop();
  }
}
