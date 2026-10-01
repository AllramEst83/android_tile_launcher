import 'package:android_tile_launcher/model/camera_access.dart';
import 'package:android_tile_launcher/services/camera_service.dart';

class FakeCameraService implements CameraService {
  FakeCameraService({this.result = const CameraGranted()});

  CameraAccess result;
  int requests = 0;

  @override
  Future<CameraAccess> request() async {
    requests++;
    return result;
  }
}
