/// The phone's clipboard, as plain text: how a layout is copied out and pasted
/// in without any file access.
abstract interface class ClipboardService {
  /// Puts [text] on the clipboard. `true` when it took. Never throws.
  Future<bool> write(String text);

  /// The text on the clipboard, or `null` when there is none (or it cannot be
  /// read). Never throws.
  Future<String?> read();
}
