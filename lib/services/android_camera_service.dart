import 'package:android_tile_launcher/model/camera_access.dart';
import 'package:android_tile_launcher/services/camera_service.dart';
import 'package:android_tile_launcher/services/permission_service.dart';

/// [CameraService] on a [PermissionService] (`CAMERA`, requested every time
/// the QR scanner screen opens — that tap is the deliberate action asking for
/// it, the same as [AndroidPhoneService] asking for `CALL_PHONE` right when
/// CALL is tapped).
class AndroidCameraService implements CameraService {
  const AndroidCameraService({required this.permissions});

  final PermissionService permissions;

  @override
  Future<CameraAccess> request() async {
    final PermissionStatus status = await permissions.request(
      AppPermission.camera,
    );
    return switch (status) {
      PermissionStatus.granted => const CameraGranted(),
      PermissionStatus.denied => const CameraDenied(permanent: false),
      PermissionStatus.permanentlyDenied => const CameraDenied(permanent: true),
    };
  }
}
