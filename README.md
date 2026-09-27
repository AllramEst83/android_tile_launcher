# Tile Launcher

An Android home-screen launcher made of live tiles, in a Commodore-era look.
The home screen is a scrolling mosaic: each tile shows what it knows (the time,
the weather, the next event, how many messages are waiting) and opens the app
behind it when you tap it. Built with Flutter.

The layout is Windows-Phone-ish — a four-column grid of 1×1, 2×2, 4×2 and 4×4
tiles you arrange yourself. The *look* is not: light blue on C64 blue, the
sixteen VIC-II colours, hard edges and bevels instead of shadows and blur.

## Status

Early. The project foundation is in place — it installs, can be chosen as the
Home app, and draws a boot screen — but no tiles exist yet. See
[plan.md](plan.md) for the phases and what is next.

## Development

The repo root is the Flutter project. Run everything from here:

```
flutter pub get
flutter run                                        # device or emulator
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug                          # after touching android/
```

To use it as your launcher, install it and pick **Tile Launcher** as the
default Home app in Android settings. Know how to get back to your usual
launcher before you do (Settings → Apps → Default apps → Home app).

The app name shown by Android is `app_name` in
`android/app/src/main/res/values/strings.xml`. The Dart package and the Android
application id (`com.codedbykay.android_tile_launcher`) keep their original
names.

## Layout

- `lib/model/` — pure-Dart core: tiles, sizes, grid packing, app matching
- `lib/services/` — service interfaces (apps, storage, tile sources) and their Android or network implementations
- `lib/ui/` — the theme (VIC-II palette, grid metrics) and the widgets that render state
- `android/` — manifest (Home intent filter, package-visibility queries) and the Kotlin channel handlers
- `test/` — mirrors `lib/`; `test/fakes/` holds the fakes
- `design/` — reference material, not code: `commodore64/` is the look and feel, `google.stich/` is structural inspiration only

## Contributing / agents

See [AGENTS.md](AGENTS.md) and [.agents/](.agents/README.md) for architecture,
conventions and the definition of done, and [plan.md](plan.md) for what's next.
