import 'package:android_tile_launcher/model/mail_alert.dart';
import 'package:flutter/foundation.dart';

/// A tapped new-mail notification on its way to the mail sheet: whoever hears
/// the tap [open]s it, and the shell, listening, [take]s it and opens the
/// message. Holds one message at a time; a later tap replaces an earlier one
/// not yet taken.
class MailAlertLinks extends ChangeNotifier {
  MailRef? _pending;
  bool _openMail = false;

  /// Whether a tap is waiting to be taken.
  bool get hasPending => _pending != null || _openMail;

  /// A notification was tapped; [ref] null opens the mail without picking out
  /// a message (the summary).
  void open(MailRef? ref) {
    _pending = ref;
    _openMail = true;
    notifyListeners();
  }

  /// The waiting tap, if any, and forgets it: `(true, ref)` for a tap (with a
  /// null ref for the summary), `(false, null)` for none.
  (bool, MailRef?) take() {
    final bool had = _openMail;
    final MailRef? ref = _pending;
    _pending = null;
    _openMail = false;
    return (had, ref);
  }
}
