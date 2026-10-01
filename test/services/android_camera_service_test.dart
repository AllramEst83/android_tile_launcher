import 'package:android_tile_launcher/model/camera_access.dart';
import 'package:android_tile_launcher/services/android_camera_service.dart';
import 'package:android_tile_launcher/services/permission_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_permission_service.dart';

void main() {
  test('granted asks the permission service for camera', () async {
    final permissions = FakePermissionService();
    final service = AndroidCameraService(permissions: permissions);

    expect(await service.request(), isA<CameraGranted>());
    expect(permissions.requested, <AppPermission>[AppPermission.camera]);
  });

  test('denied is not yet permanent', () async {
    final service = AndroidCameraService(
      permissions: FakePermissionService(PermissionStatus.denied),
    );

    final result = await service.request();
    expect(result, isA<CameraDenied>());
    expect((result as CameraDenied).permanent, isFalse);
  });

  test('permanently denied says so', () async {
    final service = AndroidCameraService(
      permissions: FakePermissionService(PermissionStatus.permanentlyDenied),
    );

    final result = await service.request();
    expect(result, isA<CameraDenied>());
    expect((result as CameraDenied).permanent, isTrue);
  });
}
