import 'dart:typed_data';

import 'package:android_tile_launcher/services/attachment_download_service.dart';

/// Records what was asked to be saved, and answers with [result].
class FakeAttachmentDownloadService implements AttachmentDownloadService {
  FakeAttachmentDownloadService([this.result = AttachmentSaveResult.saved]);

  AttachmentSaveResult result;

  /// Every `save`, in order: the bytes' length, the file name and mime type.
  final List<(int, String, String)> saves = <(int, String, String)>[];

  @override
  Future<AttachmentSaveResult> save(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
  }) async {
    saves.add((bytes.length, fileName, mimeType));
    return result;
  }
}
