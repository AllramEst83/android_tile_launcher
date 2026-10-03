import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/mail_alert.dart';
import 'package:android_tile_launcher/services/mail_notifier.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// [MailNotifier] on `flutter_local_notifications`: the only file that knows
/// the package. Works in the app and in the background task alike.
class LocalMailNotifier implements MailNotifier {
  LocalMailNotifier({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const String _channelId = 'new_mail';

  /// Sets the plugin up. [onTap] is told the payload of a notification tapped
  /// while the app is running; [launchPayload] reads the one (if any) that
  /// started the app.
  Future<void> initialize({void Function(String? payload)? onTap}) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: onTap == null
          ? null
          : (NotificationResponse r) => onTap(r.payload),
    );
    _ready = true;
  }

  /// The payload of the notification that started the app, or null.
  Future<String?> launchPayload() async {
    final NotificationAppLaunchDetails? details = await _plugin
        .getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp ?? false
        ? details?.notificationResponse?.payload
        : null;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> requestPermission() async {
    if (!_ready) await initialize();
    return await _android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<bool> isPermitted() async {
    if (!_ready) await initialize();
    return await _android?.areNotificationsEnabled() ?? false;
  }

  @override
  Future<void> show(List<MailAlert> alerts) async {
    try {
      if (!_ready) await initialize();
      for (final MailAlert alert in alerts) {
        final MailRef? ref = alert.ref;
        await _plugin.show(
          // One notification per message (a second look at the same message
          // replaces it); 1 is the summary.
          id: ref == null ? 1 : ref.uid.abs() & 0x7fffffff,
          title: alert.title,
          body: alert.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              Messages.mailAlertChannel,
              channelDescription: Messages.mailAlertChannelNote,
              importance: Importance.high,
              priority: Priority.high,
              category: AndroidNotificationCategory.email,
              groupKey: 'new_mail_group',
            ),
          ),
          payload: ref?.payload ?? '',
        );
      }
    } on Object {
      // A notification that cannot be shown is not worth failing the check.
    }
  }
}
