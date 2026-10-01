import 'package:android_tile_launcher/services/link_service.dart';

class FakeLinkService implements LinkService {
  FakeLinkService({this.result = const LinkOpened()});

  LinkResult result;
  final List<String> opened = <String>[];

  @override
  Future<LinkResult> open(String url) async {
    opened.add(url);
    return result;
  }
}
