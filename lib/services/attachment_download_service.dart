import 'dart:typed_data';

/// How a save to the Downloads folder ended.
enum AttachmentSaveResult {
  /// It is in the Downloads folder now.
  saved,

  /// The phone refused (no space, or storage is locked down some other way).
  refused,

  /// Anything else: it could not be written.
  failed,
}

/// Saves a mail attachment's bytes to the phone's own Downloads folder, so
/// the user can find it the same way any other download shows up. Never
/// throws.
abstract interface class AttachmentDownloadService {
  /// Saves [bytes] as [fileName] (a name from the message, not a path) with
  /// [mimeType].
  Future<AttachmentSaveResult> save(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
  });
}
