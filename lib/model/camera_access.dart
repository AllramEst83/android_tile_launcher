/// Whether the QR scanner may use the camera, and if not, why — the same
/// granted/denied/permanently-denied shape every other runtime permission in
/// this app surfaces, rather than exposing [PermissionStatus] straight to
/// the UI.
sealed class CameraAccess {
  const CameraAccess();
}

/// The camera may be opened.
class CameraGranted extends CameraAccess {
  const CameraGranted();
}

/// Refused; [permanent] is whether asking again can still show the dialog.
class CameraDenied extends CameraAccess {
  const CameraDenied({required this.permanent});

  final bool permanent;
}
