import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/model/mail_alert.dart';
import 'package:android_tile_launcher/services/local_store.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
import 'package:android_tile_launcher/services/mail_notifier.dart';
import 'package:android_tile_launcher/services/mail_service.dart';

/// One look at the inbox for mail that arrived since the last look, and a
/// notification for each. Whoever decides when to look (a background job
/// every 15 minutes) calls [check]; this knows nothing about the schedule.
class MailAlertRunner {
  const MailAlertRunner({
    required this.mail,
    required this.store,
    required this.notifier,
  });

  final MailService mail;
  final LocalStore store;
  final MailNotifier notifier;

  /// Where the last look ended.
  static const String storeKey = 'mail_alert_cursor';

  /// How far down the inbox a look goes: a few hours' mail, not the lot.
  static const int lookAt = 30;

  /// How many notifications were shown. Never throws: a look that fails is
  /// simply made again next time.
  Future<int> check() async {
    final MailAccountInfo? account = await mail.account();
    if (account == null) return 0;
    final MailResult result = await mail.latest(count: lookAt, fresh: true);
    if (result is! MailMessages) return 0;

    MailAlertCursor? cursor;
    try {
      cursor = MailAlertCursor.fromJson(await store.read(storeKey));
    } on LocalStoreException {
      // Looked at as for the first time: nothing is announced.
    }
    final MailAlertPlan plan = planMailAlerts(
      listing: result,
      account: account.email,
      cursor: cursor,
    );
    try {
      await store.write(storeKey, plan.cursor.toJson());
    } on LocalStoreException {
      // Then the same mail is announced again next time rather than lost.
      return 0;
    }
    if (plan.alerts.isNotEmpty) await notifier.show(plan.alerts);
    return plan.alerts.length;
  }
}
