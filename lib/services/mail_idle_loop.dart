import 'dart:async';

import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/services/mail_alert_runner.dart';
import 'package:android_tile_launcher/services/mail_service.dart';

/// Keeps a connection to the mail server open and looks at the inbox each time
/// the server says something changed. It is the instant mode's whole job,
/// apart from running inside a foreground service ([mailAlertServiceCallback]).
///
/// The loop looks at the inbox first (to catch up on whatever came while it
/// was not running), then waits; when the wait ends in a change, or just runs
/// out of time (servers close an idle connection after about half an hour), it
/// looks again. A connection that fails is retried after a pause that grows
/// from 30 seconds to 5 minutes, so a phone with no signal does not hammer the
/// server.
class MailIdleLoop {
  MailIdleLoop({
    required this.mail,
    required this.runner,
    this.wait = const Duration(minutes: 25),
    this.pause = _pause,
  });

  final MailService mail;
  final MailAlertRunner runner;

  /// How long one wait lasts at most.
  final Duration wait;

  /// How to sleep between failed tries; replaced in tests.
  final Future<void> Function(Duration) pause;

  static Future<void> _pause(Duration d) => Future<void>.delayed(d);

  static const List<Duration> backoff = <Duration>[
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
  ];

  final Completer<void> _stop = Completer<void>();

  bool get stopped => _stop.isCompleted;

  /// Ends the loop: the wait in progress is cut short.
  void stop() {
    if (!_stop.isCompleted) _stop.complete();
  }

  /// Runs until [stop]. Never throws.
  Future<void> run() async {
    int failures = 0;
    while (!stopped) {
      try {
        await runner.check();
      } on Object {
        // A look that fails is made again at the next change.
      }
      if (stopped) break;
      final MailWait result = await mail.waitForChange(
        timeout: wait,
        cancel: _stop.future,
      );
      if (stopped) break;
      if (result == MailWait.failed) {
        final Duration sleep =
            backoff[failures < backoff.length ? failures : backoff.length - 1];
        failures++;
        await pause(sleep);
      } else {
        failures = 0;
      }
    }
  }
}
