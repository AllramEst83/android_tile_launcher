# Tile Launcher — Plan

Goal: an Android home-screen launcher made of live tiles, so the user rarely has to leave it. The structure is a four-column mosaic of 1×1, 2×2, 4×2 and 4×4 tiles (see `design/google.stich/`); the look is Commodore-era (see `design/commodore64/`): light blue on C64 blue, the sixteen VIC-II colours, hard edges, bevels instead of shadows.

Guidance for agents: [AGENTS.md](AGENTS.md) and [.agents/](.agents/README.md). Each step ends with `dart format`, `flutter analyze`, `flutter test` clean, `flutter build apk --debug` after touching `android/`, and — where it touches the phone — a device check. Small steps: finish and verify one before starting the next.

The sibling repo `../android_terminal_launcher` already solves many of these features (weather over SMHI, IMAP mail, calendar read/write, contacts, Text TV). Its services are pure Dart behind interfaces and are worth porting rather than rewriting. Its *presentation* does not transfer: there is no command line here.

## Done

| Phase | What it delivered |
|---|---|
| 0 | **Foundation.** Real name (`Tile Launcher`), description and lints; default counter app and its test removed. Launcher role in the manifest (`MAIN`+`HOME`+`DEFAULT`, `singleTask`, `<queries>` for package visibility), C64-blue launch window in both `values/` and `values-night/` so there is no flash on start. `lib/ui/theme.dart` with the VIC-II palette and grid metrics, a boot screen behind `PopScope(canPop: false)`, `messages.dart`. `README.md`, `AGENTS.md`, `CLAUDE.md` and `.agents/` (architecture, android-launcher, best practices, testing) written for this repo. Format, analyze, 2 tests and a debug APK build all clean. |
| 1 | **The pixel font.** *Press Start 2P* (OFL 1.1, `fonts/PressStart2P-Regular.ttf` + `fonts/OFL.txt`), bundled as an asset, never fetched at runtime. A C64 face (`C64 Pro Mono`) was considered and rejected: its licence is free for non-commercial use but separately forbids "direct download from any web site," which conflicts with this repo being public on GitHub. Named behind one constant, `kPixelFontFamily` in `lib/ui/theme.dart`; every text style in `tileLauncherTheme()` goes through it. Confirmed on the user's own phone. |
| 2 | **Apps over a channel.** `AppRepository` (abstract, `listApps`/`launch` only — `uninstall` waits for Phase 4) + `AndroidAppRepository` on a `MethodChannel`, backed by `AppsChannelHandler.kt` (lists off the main thread, launch via `getLaunchIntentForPackage`). Excludes our own package, sorts case-insensitively, caches with an explicit refresh reachable by pulling down. Proved with a plain scrolling list (`AppListView`) in place of the static boot screen, which now doubles as the list's loading and error state. 16 tests (7 repository, 9 widget), format/analyze/debug-APK-build all clean. |

## Next, in order

3. **Phase 3, the mosaic.** `Tile` (id, kind, size, colour, target), `TileSize` (1×1, 2×2, 4×2, 4×4), a pure `tile_layout.dart` that packs an ordered list into four-column rows, `TileGrid` and `TileView` with the first kind: an app tile (glyph, label bottom-left, VIC-II fill, 2px bevel). Tap launches. **This is the first usable launcher** — set it as Home and live with it.
4. **Phase 4, the drawer.** All Apps: grouped by initial (A–Z, then Å Ä Ö, as the sibling repo sorts), a jump index, a search field, reached by swiping left from home. Long-press a row for quick actions: pin to grid, app details, uninstall (`REQUEST_DELETE_PACKAGES`).
5. **Phase 5, a layout that sticks.** `LocalStore` over `shared_preferences`; save and restore the grid, pin from the drawer, remove a tile. Round-trip tested.
6. **Phase 6, the grid editor.** Long-press the canvas to enter edit mode: drag to reorder, resize between the four geometries, pick a fill from the sixteen colours, delete. Apply or cancel. (`design/google.stich/grid_editor_customizer/`.)
7. **Phase 7, the first live tiles: clock and device.** `TileSource` as an interface, a refresh that runs only while the launcher is resumed, and the oversized-numeral type style. Clock (time large, date small) and a device tile (battery, storage).
8. **Phase 8, weather.** Port the sibling repo's `weather.dart` (SMHI where it reaches, Open-Meteo elsewhere and as fallback) and its saved fixtures. `INTERNET` + `ACCESS_COARSE_LOCATION`. A 2×2 (now) and a 4×2 (five days).
9. **Phase 9, the agenda.** `READ_CALENDAR`: the next event on a wide tile, the day or week on tap. Event writing (`WRITE_CALENDAR`, add/edit/remove) comes after, only once reading has been used for a while.
10. **Phase 10, people.** `READ_CONTACTS`: a contact pinned as a tile, with call (`CALL_PHONE`, dialer fallback), SMS (`SEND_SMS`) and WhatsApp (`wa.me`, no permission) actions. Anything that acts on a tap asks first, the way the sibling repo fills the prompt instead of sending.
11. **Phase 11, notes and todos.** Local storage, a list tile that shows the top few items, a full view on tap.
12. **Phase 12, mail.** IMAP with an app password stored in the Android Keystore (port `SecretStore` and the `enough_mail` code): unread count as a badge, the newest messages on tap, move-to-Trash never outright delete.
13. **Phase 13, Text TV.** texttv.nu in colour on a large tile; its block graphics and page navigation are already solved next door.
14. **Phase 14, calc and convert.** A tile that opens a small pad; the expression parser and unit/currency tables port straight across.
15. **Phase 15, timers and alarms.** `SET_ALARM` hand-off to the phone's clock app, as next door: the launcher sets and opens, it does not schedule.
16. **Phase 16, settings.** (`design/google.stich/launcher_settings/`.) Theme variants (the C64 screen, a pitch-black OLED canvas, the beige-hardware palette), column count, gutter, gestures, export/import the layout, a shortcut to the Home-app chooser.
17. **Phase 17, polish.** An app icon generated by a script (not hand-edited PNGs), a press animation that reads as a bevel being pushed in, the boot screen as a real first-run animation, haptics, and most-used ranking to suggest tiles.

## Deliberately different from the terminal launcher

- **No command line.** `help`, `ui rich|plain`, aliases, `&&` chaining and macros have no counterpart here; a tile is either self-evident or badly designed.
- **`list`, `open`, `refresh`, `uninstall`** stop being commands and become the drawer, a tap, a pull-to-refresh and a long-press action.
- **Six themes** become a smaller set of canvases (Phase 16). The sixteen VIC-II colours are the palette in all of them; the canvas changes, not the tile colours.
- **Rich vs. plain** does not exist. Every tile is a card by definition.

## Not implemented (on purpose or not yet)

- **Real app icons on tiles**: the default is a monochrome geometric glyph, which suits the look and avoids shipping icon bitmaps over the channel per app. Real icons stay opt-in, lazily fetched and cached (see `.agents/android-launcher.md`).
- **Widgets**: hosting real Android `AppWidget`s is a much larger job (`AppWidgetHost`, permissions, remote views) and is not planned. Tiles are ours.
- **Notification badges** need notification-listener access, which is a heavy permission; only the counts we can get another way (mail, calendar) are planned.
- **Wallpaper pass-through, acrylic blur, 3D tile tilt, rounded corners**: all in the Stitch mockups, none in this design. Flat, opaque, square.
- **Landscape and tablets**: portrait phone only until the phone version is good.

## Open questions for the user

1. Swedish collation (Å Ä Ö last) in the drawer, as in the sibling repo — or plain A–Z?
2. Is the C64 blue canvas the default, with pitch-black OLED as an option, or the other way round?

## Changelog

- 2026-09-27: repo bootstrapped. Phase 0 (foundation) built and verified; this plan written to replace the two-line phase sketch. Design references sorted into `design/commodore64/` (look and feel) and `design/google.stich/` (structure only — its Fluent/acrylic styling is explicitly not the target, recorded in `.agents/architecture.md`).
- 2026-09-27: Phase 1, the pixel font: Press Start 2P (OFL 1.1) bundled, not a C64 face — `C64 Pro Mono`'s licence forbids direct web download and this repo is public on GitHub. Decision and the single `kPixelFontFamily` constant recorded in `.agents/architecture.md`.
- 2026-09-27: Phase 2, apps over a channel. `AppRepository`/`AndroidAppRepository`/`AppsChannelHandler.kt` ported from the sibling repo's pattern, scoped down to `listApps`/`launch` (no `uninstall` until Phase 4 needs it). The boot screen now doubles as the app list's loading/error state rather than a separate static screen. **Not yet checked on a device** — analyze, 16 tests and a debug APK build are clean, but only a real phone can confirm every installed app appears and launches.
