import 'package:android_tile_launcher/model/mail_alert.dart';
import 'package:android_tile_launcher/services/mail_notifier.dart';

/// Records what it was asked to show, and answers the permission question
/// with [permitted].
class FakeMailNotifier implements MailNotifier {
  FakeMailNotifier({this.permitted = true});

  bool permitted;
  int permissionRequests = 0;
  final List<MailAlert> shown = <MailAlert>[];

  @override
  Future<void> show(List<MailAlert> alerts) async => shown.addAll(alerts);

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permitted;
  }

  @override
  Future<bool> isPermitted() async => permitted;
}
