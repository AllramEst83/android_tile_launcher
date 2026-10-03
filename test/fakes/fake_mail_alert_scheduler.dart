import 'package:android_tile_launcher/model/mail_alert.dart';
import 'package:android_tile_launcher/services/mail_alert_scheduler.dart';

/// Remembers every mode it was set to.
class FakeMailAlertScheduler implements MailAlertScheduler {
  final List<MailAlertMode> applied = <MailAlertMode>[];

  /// What `allowRunningInBackground` answers, and how often it was asked.
  bool allowed = true;
  int allowAsked = 0;

  @override
  Future<void> apply(MailAlertMode mode) async => applied.add(mode);

  @override
  Future<bool> allowRunningInBackground() async {
    allowAsked++;
    return allowed;
  }
}
