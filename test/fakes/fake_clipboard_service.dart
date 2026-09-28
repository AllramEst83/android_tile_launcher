import 'package:android_tile_launcher/services/clipboard_service.dart';

/// A clipboard held in memory.
class FakeClipboardService implements ClipboardService {
  FakeClipboardService([this.text]);

  String? text;

  /// Whether writing works, to test a clipboard that refuses.
  bool works = true;

  @override
  Future<bool> write(String value) async {
    if (!works) return false;
    text = value;
    return true;
  }

  @override
  Future<String?> read() async => text;
}
