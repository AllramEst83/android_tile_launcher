import 'package:android_tile_launcher/model/camera_access.dart';

/// Camera access for the QR scanner tile, wrapping [PermissionService] the
/// same shape [BluetoothService] wraps it for `BLUETOOTH_CONNECT` — a
/// feature-shaped interface over a generic capability, rather than exposing
/// [PermissionService] itself to the UI.
abstract interface class CameraService {
  /// Requests the CAMERA permission if not already granted. Returns at once,
  /// with no dialog, when it already is. Never throws.
  Future<CameraAccess> request();
}
