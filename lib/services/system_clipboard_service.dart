import 'package:android_tile_launcher/services/clipboard_service.dart';
import 'package:flutter/services.dart';

/// [ClipboardService] on Flutter's own clipboard support.
class SystemClipboardService implements ClipboardService {
  const SystemClipboardService();

  @override
  Future<bool> write(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<String?> read() async {
    try {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } on PlatformException {
      return null;
    }
  }
}
