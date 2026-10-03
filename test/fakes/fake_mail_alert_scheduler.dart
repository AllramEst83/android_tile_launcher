import 'package:android_tile_launcher/model/mail_alert.dart';
import 'package:android_tile_launcher/services/mail_alert_scheduler.dart';

/// Remembers every mode it was set to.
class FakeMailAlertScheduler implements MailAlertScheduler {
  final List<MailAlertMode> applied = <MailAlertMode>[];

  @override
  Future<void> apply(MailAlertMode mode) async => applied.add(mode);
}
