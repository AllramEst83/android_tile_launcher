# Patched copy of dotlottie_flutter 0.1.7

Copied from pub.dev and kept here because the Android plugin kept ONE static
`binaryMessenger`, overwritten by every Flutter engine that attached. This app
runs headless engines for background work (WorkManager's mail check and the
instant-mail foreground service), so after one of them started and stopped, a
Scene tile built later sent every animation frame to a dead engine, and the log
filled for ever with `FlutterJNI was detached from native C++ ... Channel:
dotlottie_view_N`.

The fix (Android Kotlin only): `DotLottieViewFactory` and `DotLottiePlatformView`
take the messenger of the engine that registered them, and the static is gone.
The other platforms were dropped from the copy's `pubspec.yaml`; the Dart code
is untouched.

When upstream fixes this, delete this folder and go back to
`dotlottie_flutter: ^<version>` in `pubspec.yaml`.
