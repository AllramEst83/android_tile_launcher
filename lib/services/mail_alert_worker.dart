import 'package:android_tile_launcher/model/mail_alert.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/services/flutter_secret_store.dart';
import 'package:android_tile_launcher/services/imap_mail_service.dart';
import 'package:android_tile_launcher/services/local_mail_notifier.dart';
import 'package:android_tile_launcher/services/mail_account.dart';
import 'package:android_tile_launcher/services/mail_alert_runner.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/services/shared_preferences_local_store.dart';
import 'package:workmanager/workmanager.dart';

/// What the background job runs, in a background isolate with none of the
/// app's objects: it builds its own, reads the setting from the saved
/// settings, looks at the inbox and notifies. Kept apart from the scheduler
/// so the isolate does not drag the whole app in.
@pragma('vm:entry-point')
void mailAlertDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? input) async {
    final SharedPreferencesLocalStore store = SharedPreferencesLocalStore();
    final LauncherSettings settings = LauncherSettings.fromJson(
      await store.read(SettingsState.storeKey),
    );
    // Switched off since the job was queued.
    if (settings.mailAlerts == MailAlertMode.off) return true;
    await MailAlertRunner(
      mail: ImapMailService(accounts: MailAccountStore(FlutterSecretStore())),
      store: store,
      notifier: LocalMailNotifier(),
    ).check();
    return true;
  });
}
