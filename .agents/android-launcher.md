# Android launcher specifics

Paths are relative to the repo root, which is the Flutter project.
Application id: `com.codedbykay.android_tile_launcher`.

## Becoming a launcher
- `android/app/src/main/AndroidManifest.xml` main activity needs an intent filter with `MAIN` + `HOME` + `DEFAULT` (already present). This is what makes it appear in Settings → Default apps → Home app.
- It also has a separate `MAIN` + `LAUNCHER` filter, on purpose: it gives the app a normal drawer icon and lets `flutter run` find and start it. Because of it, this app shows up in its own app listing, so the app repository must exclude our own package.
- `android:launchMode="singleTask"` (the template default is `singleTop`) so pressing Home returns to the existing instance instead of stacking new ones.
- Override back handling: a launcher must not exit on back. `PopScope(canPop: false)` wraps the shell (`lib/ui/home_shell.dart`), and a test asserts it.
- Handle `AppLifecycleState.resumed`: refresh what tiles show, and stop their timers while paused.
- Home key press while already open arrives as a new intent; make sure state (scroll position, grid) is preserved.
- Test the launcher role early on a real device: Settings → Default apps → Home app.

## No white flash on start
- `values/styles.xml` **and** `values-night/styles.xml` both use `@android:style/Theme.Black.NoTitleBar`: the launcher's look does not follow the OS dark-mode setting.
- `NormalTheme`'s window background and `drawable*/launch_background.xml` are both `@color/launch_canvas` (`values/colors.xml`), which duplicates `TileColors.canvas` in `lib/ui/theme.dart`. Change the two together or the window will show through in the wrong colour.

## Listing installed apps (package visibility)
- Since Android 11 (API 30), apps only see packages they declare. For a launcher the right, minimal approach is a `<queries>` block:
  ```xml
  <queries>
      <intent>
          <action android:name="android.intent.action.MAIN" />
          <category android:name="android.intent.category.LAUNCHER" />
      </intent>
  </queries>
  ```
  It is already there. Keep the `PROCESS_TEXT` query the template added.
- `QUERY_ALL_PACKAGES` is only needed to see non-launchable packages. It is a Play-restricted permission; don't add it unless a feature requires it, and document why.
- List **launchable** apps only (have a launch intent / `CATEGORY_LAUNCHER` activity), exclude this app itself, sort case-insensitively by label.

## Permissions
The manifest declares none yet. Add each one only when the feature that needs it lands, with a comment saying which feature, and ask for the dangerous ones at runtime through a `PermissionService` (the sibling repo's `PermissionsChannelHandler` is a working pattern to copy).
Expected as tiles arrive: `INTERNET` (weather), `ACCESS_COARSE_LOCATION` (weather here), `READ_CALENDAR` (the agenda tile), `READ_CONTACTS`/`CALL_PHONE`/`SEND_SMS` (people tiles), `REQUEST_DELETE_PACKAGES` (uninstall from the drawer), `SET_ALARM` (a timer tile).

## Package choice
- `device_apps` (the obvious search result) is **discontinued** (last release 2021) and unsafe on modern AGP/Kotlin. Do not use it.
- Preferred: a small custom `MethodChannel` in `MainActivity.kt` using `PackageManager.queryIntentActivities` + `getLaunchIntentForPackage`. It's ~60 lines, has no dependency risk, and can later serve battery/notification/etc. tiles.
- Acceptable alternative: `installed_apps` (maintained) if speed matters more than control.
- Either way it lives behind `AppRepository` (see [architecture.md](architecture.md)).

## Platform channel rules
- Channel name: `com.codedbykay.android_tile_launcher/apps` (namespaced).
- Do work off the main thread for large queries; reply on the main thread.
- Return plain serializable data (`List<Map<String, Object?>>`), map it to Dart models in the repository. Handle `PlatformException` there and convert to domain errors.
- Never crash on a missing package/launch intent; return a failure the tile can show.

## App icons on tiles
A tile showing a real app icon needs the icon as bytes over the channel (`PackageManager.getApplicationIcon` → PNG). That is expensive per app: fetch lazily, cache by package name, and never do it during a scroll frame. A monochrome geometric glyph (the Commodore look) avoids the problem entirely and is the default; real icons are opt-in.

## Build config
- `minSdk`: Flutter's default is fine.
- Full-screen look: `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` is set in `main.dart`; respect insets with `SafeArea`.
- Release builds: signing config and R8 are out of scope until the MVP works on a device.

## Device workflow
- `flutter devices`, `flutter run -d <id>` (real phone preferred over emulator).
- To reset the default launcher during testing: Settings → Apps → Default apps → Home app, choose the stock launcher. **Keep a way back to the stock launcher before testing risky changes.**
- `adb logcat -s flutter` for logs.
- Kotlin and the manifest are not compiled by `flutter test` or `flutter analyze`; run `flutter build apk --debug` after touching `android/`.

## App name
The name Android shows (app list, Home-app chooser) is the string resource `app_name` in `android/app/src/main/res/values/strings.xml` (`Tile Launcher`), referenced by `android:label` in the manifest. Change it there, not in the manifest. The Dart package name (`android_tile_launcher`) and the application id stay as they are.

## App icon
Still the Flutter template's icon. Replacing it means an adaptive icon (`mipmap-anydpi-v26/ic_launcher.xml` = a colour background + a foreground PNG) plus the plain `mipmap-*/ic_launcher.png` for older Android. The sibling repo generates all of them with a script (`tool/make_app_icon.py`) rather than editing PNGs by hand; do the same here.
