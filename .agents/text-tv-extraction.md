# Text TV → standalone app: inventory, plan and improvements

Written 2026-10-04 from a read of every Text TV file in this repo. Nothing has been moved yet. This file is the record of what the module is, the to-do list for turning it into its own app, and the improvements worth making on the way.

Not verified live: the build sandbox could not reach texttv.nu (proxy 403), so everything below about the API comes from the code, its tests and the three saved fixtures. Re-check against the live API in phase 0.

## 1. What the module is

A viewer for SVT Text (Swedish teletext, pages 100–899) through the public **texttv.nu** JSON API, plus a launcher tile that shows the headlines of page 100.

- **Viewer** (`ui/text_tv_screen.dart`): full-screen route. Top bar (`X`, title, `REFRESH`), the coloured 40-column page on its own black screen, `<` page-number `>` row, six shortcut chips, a remote-style number pad, tappable page links, swipes between sub-pages and pages, a part bar (`PART 2/3`), back through the pages read.
- **Tile** (`ui/text_tv_tile_view.dart`): name + page number when small, plus as many headlines of page 100 as fit when larger. Polled every 10 min while the launcher is resumed; tap opens the viewer; the tile re-reads when the viewer closes.
- **Rendering** (`ui/tv_row.dart` + model): each row is painted cell by cell (colour bars, double-height headlines, block-graphics logo, underlined links), so bars line up with letters and rows touch with no seam.

## 2. Every file that belongs to it

### 2a. Moves with the module (viewer core)

| File | Lines | What it is | Depends on |
|---|---:|---|---|
| `lib/model/styled_text.dart` | 109 | `TvColor` (8 teletext colours), `StyledRun` (text, fg, bg, underline, tall, mosaic masks, command), `mergeRuns`, `plainText` | nothing |
| `lib/model/text_tv_page.dart` | 53 | `TextTvPage` (number, `parts`, `styledParts`, `previous`, `next`), sealed `TextTvResult` = `TextTvShown` / `TextTvNotBroadcast` / `TextTvFailed` | `styled_text` |
| `lib/model/text_tv_html.dart` | 149 | `parseTextTvHtml`: texttv.nu HTML → styled rows; returns null if the shape is not what it expects (caller falls back to plain text) | `styled_text`, `tv_mosaic` |
| `lib/model/tv_mosaic.dart` | 166 | `tvPictureFor(hash)`: rebuilds every block-graphics GIF the site uses (13×16, 2×3 sixths), CRC-32s it, looks the hash up. No downloads. Built lazily on first use | `styled_text` |
| `lib/model/tv_layout.dart` | 64 | `tvIsBar`, `tvTextMargins`, `tvGutters`: the black gutter each side that centres a page's *text* | `styled_text` |
| `lib/services/text_tv.dart` | 92 | `TextTv`: the API client. `page(n)` → `TextTvPage?`, throws `NetworkException` | `HttpFetcher`, `NetworkException`, model |
| `lib/services/text_tv_repository.dart` | 10 | `TextTvRepository`: `page(n, {fresh})` → `TextTvResult`, never throws | model |
| `lib/services/live_text_tv_repository.dart` | 52 | In-memory cache over `TextTv`: 5 min, 40 pages, failures and unbroadcast pages not kept | `TextTv`, repository |
| `lib/ui/tv_row.dart` | 370 | `TvRow` widget + painter, `tvColorOf` (the fixed teletext palette), `tvCellWidth`, `tvCommandAt` (link hit-test with one cell of slack) | `styled_text` |
| `lib/ui/text_tv_screen.dart` | 714 | `showTextTv` / `TextTvScreen` and all the viewer widgets (`_TopBar`, `_PageArea`, `_Grid`, `_PartBar`, `_Button`, `_NumberBox`, `_Shortcuts`, `_Keypad`), the `textTv*Key` test keys, `textTvShortcuts`, page range 100–899 | repository, `Messages`, `theme.dart` (see 2d) |

### 2b. Tile-only (does **not** move; stays in or leaves the launcher, see decision D1)

| File | Lines | What it is |
|---|---:|---|
| `lib/model/text_tv_headlines.dart` | 21 | `textTvHeadlines(page)`: the headline lines for the tile. Worth keeping in the new app too (reader mode, widget, share) |
| `lib/services/text_tv_tile_source.dart` | 16 | `TextTvTileSource`: reads page 100 for the tile poller |
| `lib/ui/text_tv_tile_view.dart` | 229 | `TextTvTileContentView`: the tile's layout and its headline fitting |

### 2c. Launcher wiring (edited, not moved)

| Where | What |
|---|---|
| `lib/model/tile.dart` :17, :48 | `TileKind.textTv`; `displayNameOf` → `'TEXT TV'` |
| `lib/model/tile_content.dart` :6, :111-119 | import + `TextTvContent` |
| `lib/ui/tile_view.dart` :26-27, :60-61, :322-341 | imports + `case TileKind.textTv:` (`TilePoller`, 10 min, `showTextTv(...).then(refreshNow)`) |
| `lib/services/tile_services.dart` :21, :41, :68 | `TileServices.textTv` field |
| `lib/main.dart` :38, :48, :116 | `LiveTextTvRepository(textTv: TextTv(fetcher: fetcher))` |
| `lib/messages.dart` :417-425, :521 | `textTv*` strings (title, tap to open, not broadcast, loading, try again, refresh, part, page-not-broadcast) and the `TEXT TV — …` line of the help text |
| `lib/ui/add_tile_sheet.dart` :40 | offers every `TileKind` automatically, so the tile disappears from the sheet when the kind does |
| Comments only | "Text TV" is named in comments in `calc_tile_view.dart`:29, `mail_tile_view.dart`:92, `weather_tile_view.dart`:81,103, `media_tile_view.dart`:66, `agenda_tile_view.dart`:77,102, `device_tile_view.dart`:32, `settings_screen.dart`:30, `qr_scanner_screen.dart`:22, `app.dart`:118 |
| Docs | `README.md` :36, :74 (INTERNET row), :127 (credits); `plan.md` :7, :9; `.agents/architecture.md` :16, :28-33, :48, :88-91, :128, :156-158 and the decision log :304-310; `.agents/archive/*` (history, leave as is) |

### 2d. Shared launcher code the module leans on

| Dependency | Used by | Standalone answer |
|---|---|---|
| `services/http_fetcher.dart` (8), `io_http_fetcher.dart` (66), `network_exception.dart` (16) | `TextTv` | **Copy** (tiny, generic). 10 s timeout on connect/first byte/each chunk, 2 MB cap, UTF-8 with replacement, new `HttpClient` per request, no retry |
| `ui/theme.dart`: `TileColors` (canvas, textBright, textDim, highlight, bezel), `TileMetrics` (gutter 8, margin 12, bevel 2), `C64.black/white`, `kPixelFontFamily` | viewer chrome and message text | **Replace** with the new app's own theme (decision D2). `tvColorOf` already uses its own fixed palette and needs nothing from the launcher |
| `fonts/PressStart2P-Regular.ttf` + `fonts/OFL.txt` | the grid and all viewer text | **Copy** (bundled, offline). Consider a real teletext face (improvement I-12) |
| `app.dart` `_ScaledTextScaler` (the FONT SIZE setting) | `TvRow` and the tile read `MediaQuery.textScalerOf`; the grid fits the width anyway, so the setting only changes the viewer's chrome | **Not carried**; the new app needs real zoom (I-3) |
| `ui/tile_poller.dart`, `TileSource`, `TileContent` | the tile only | Not carried |
| `model/pinned_tile.dart` `_kindByName`, `grid_state`, `layout_export` | persistence of the tile | See phase 6: a saved `textTv` tile is **silently dropped** once the enum value is gone |
| `test/fakes/fake_http_fetcher.dart`, `fake_text_tv_repository.dart`, `fake_tile_services.dart` | tests | Copy the first two; `fake_tile_services` only loses a field |
| Android: `INTERNET` permission only | the API | `android/app/src/main/AndroidManifest.xml` :40 (shared with weather, rates, mail, so it stays in the launcher). The module needs no other permission, no Kotlin and no platform channel |

### 2e. Tests and fixtures

| File | Lines | Covers |
|---|---:|---|
| `test/services/text_tv_test.dart` | 275 | request URL and `app` id, real-page shape (24 lines ≤ 40 cols, Swedish letters, trailing spaces), colours all-or-nothing, parts, neighbours, not-in-broadcast (empty list, "Sidan ej i sändning"), unreadable answers, network failures |
| `test/services/text_tv_html_test.dart` | 340 | class names → colours, links, entities, double-height rows, real front page, everything-unexpected-is-null |
| `test/services/text_tv_html_pictures_test.dart` | 202 | block-graphics cells, links, real pages 100 and 377 |
| `test/services/tv_mosaic_test.dart` | 101 | real picture hashes, "every picture on the saved pages is known", unknown hash → null |
| `test/services/live_text_tv_repository_test.dart` | 110 | cache age, `fresh`, failures not kept, capacity |
| `test/services/text_tv_tile_source_test.dart` | 43 | tile source (tile-only) |
| `test/model/tv_layout_test.dart` | 184 | bars, margins, gutters, on real pages (reads fixtures 100 and 377) |
| `test/model/text_tv_headlines_test.dart` | 88 | headline extraction, on real page 100 |
| `test/ui/text_tv_screen_test.dart` | 623 | opening, filling the screen, air, bar/text centring, arrows, shortcuts, links, number pad, parts and swipes, back, failure/retry/refresh |
| `test/ui/text_tv_tile_view_test.dart` | 174 | tile layout and taps (tile-only) |
| `test/ui/home_shell_test.dart` :978-1023 | 46 of 1,898 | tile shows headlines, opens viewer, re-reads on close (launcher-only; delete that test with the tile) |
| `test/fakes/fake_text_tv_repository.dart` | 24 | records `(number, fresh)`; serves a map; settable failure |
| `test/fixtures/texttv_100.json`, `texttv_104.json`, `texttv_377.json` | 13/11/13 | real answers: 100 (HTML + plain, logo, headlines), 104 (plain only, has `date_updated_unix`), 377 (HTML, sport matches with links) |

Tests load fixtures by file path and the screen tests use `tileLauncherTheme()`; both need touching when ported. `flutter test` does not load the pixel font, so text layout is checked by geometry in tests, not by eye.

## 3. Behaviour to preserve (the spec)

### 3a. API contract (as the code uses it)

- `GET https://texttv.nu/api/get/{n}?app=android_tile_launcher&includePlainTextContent=1`. The site asks every client to send its own unique `app` value; the standalone app must send its **own** id, not the launcher's.
- Answer: JSON list. Element 0 is a map with `num`, `title`, `content` (list of HTML strings, one per sub-page; absent on some responses), `content_plain` (list of strings, one per sub-page, lines joined by `\n`), `next_page`, `prev_page` (strings), and sometimes `date_updated_unix` (int; **read by nobody today**).
- Not in broadcast = empty list, **or** exactly one part with exactly one line containing `ej i sändning` (case-insensitive). A real page that merely mentions it is still a page.
- Anything else unexpected (not JSON, not a list, element not a map, `content_plain` missing / empty / not all strings) → `NetworkException('texttv.nu sent an answer I could not read')`.
- `parts` = `content_plain` split on `\n`, each line right-trimmed. `styledParts` = HTML parsed per part, **all or nothing**: if the `content` count differs from the plain part count, or any part fails, the page is plain text only. The plain text is the source of truth.
- `previous` / `next` = `int.tryParse` of `prev_page` / `next_page`, null if missing.

### 3b. HTML → rows (`parseTextTvHtml`)

- Row = `<span … class="line…">`; `class` need not be the first attribute (`line DH` rows carry a `style` first).
- Inside a row, one `<span class="…">` per stretch. Class names: `bgBl bgR bgG bgY bgB bgM bgC bgW` (backgrounds), `bl R G Y B M C W` (text colours), `bgImg` (block-graphics cell; the picture is `storage/chars/{hash}.gif` in the `style`). Defaults white on black.
- `<a href="/{n}">` inside a span → underlined run whose command is `'$n'`. Other links are underlined but not tappable.
- Every row must be exactly 40 characters wide after tag stripping, else the whole part is null.
- `DH` rows are double height. The blank row the site leaves under a headline is dropped, but only if it is blank (content under a headline stays).
- Entities decoded: `&nbsp; &lt; &gt; &quot; &#39; &amp;`.
- A picture hash it does not know → a blank cell in the span's colours (no crash).
- Palette in the hash rebuild: the site's teletext colours with channels pulled in to 4/252 (green 2/254). Mask bit `row*2 + column`, rows 5/6/5 sixteenths, columns 6/7 thirteenths.

### 3c. Repository

- `LiveTextTvRepository`: key = page number; reuse if younger than 5 min unless `fresh`; keep ≤ 40 pages (oldest read evicted); only a read page is kept; a not-in-broadcast answer evicts; a `NetworkException` becomes `TextTvFailed(message)`. In memory only.

### 3d. Viewer

- Range 100–899 (`textTvFirstPage` / `textTvLastPage`). Start page configurable.
- `_load` bumps a request counter; only the newest answer is applied (a slow one that was overtaken is ignored); checks `mounted`.
- Opening a page pushes the page left onto a history stack; opening the page already shown (and loaded) is a no-op.
- Arrows use the site's `prev`/`next`, else ±1, hidden at the ends. They also work on a not-in-broadcast page.
- Number pad: first digit 1–8; third digit opens; `DEL`; `X` closes the pad; the number box shows `1--`-style progress; opening a page closes the pad.
- Swipe (|velocity| ≥ 200): left = next part, then next page; right = previous part, then previous page. Part bar only when a page has > 1 part.
- Back: closes the pad first, then pops the history, then closes (`PopScope`).
- `REFRESH` and `TRY AGAIN` read with `fresh: true`. Failures print the exception message upper-cased.
- Shortcuts (Swedish, hard-coded): 100 NYHETER, 101 INRIKES, 104 UTRIKES, 300 SPORT, 400 VÄDER, 700 INNEHÅLL.
- Layout constants: 40 columns + 2 gutter cells; cell width capped at `8 × 1.75`; row height spreads the free height over the row units (double-height = 2), clamped to 1.6–3 cells; glyphs stretched upright up to 2× about the cell centre; `leadingDistribution: even` so text is not low in its row; 12 px air above and below; text centred by `tvGutters`, colour bars (≥ 90 % non-black background) centred by their edges with a 1-cell gutter; first row ignored for margin measurement; rows with < 12 characters of ink ignored.
- A row is announced to TalkBack as its trimmed plain text.

### 3e. Tile (only if it survives, see D1)

- Page 100, poll 10 min while resumed. Width < 120 → title + page number. Otherwise a 28 px header and headlines in 11 px caps, indent 14, gap 5, lead story up to 3 lines and others up to 2, wrapped by measuring with `TextPainter` and the ambient text scaler; later headlines are all-or-nothing, the lead is shown with however many lines fit.

## 4. Decisions needed before building

- **D1. What does the launcher do afterwards?** Hosting another app's widget is on the launcher's "not planned" list (`plan.md`), so the live headline tile cannot be fed by the new app. Options: (a) remove the kind and let a Text TV **app tile** launch the new package, losing the live headlines (**recommended**: one owner for the code, nothing duplicated); (b) keep a copy of the client + tile in the launcher (duplicates ~1,000 lines, the thing this migration is meant to end); (c) extract a shared Dart package both apps import (clean, but a second repo to version and publish privately).
- **D2. Look of the new app.** The C64 chrome (bevels, VIC-II colours, Press Start 2P everywhere) comes from the launcher. Recommended: the new app gets its own teletext-native look (black, the eight teletext colours, flat) and drops the C64 theme, which also removes the launcher's rule "colours from `theme.dart` only". Say if it should stay C64.
- **D3. Name, application id and repo.** Needs a new id (not `com.codedbykay.android_tile_launcher`) and an `app` value for the API. Suggested: repo `android_text_tv`, id `com.codedbykay.texttv`, `app=texttv_android` (change freely; fix before phase 1, it is painful to change after publishing).
- **D4. Scope of v1.** Recommended: the module as it is plus the Tier 1 improvements in section 6. Tier 2 and 3 after.
- **D5. Distribution.** Sideload only, or Play Store? The second needs the legal checks in I-14 first.

## 5. To-do list

Rules carried over from `AGENTS.md`: small steps, each phase finished and verified before the next; `dart format`, `flutter analyze`, `flutter test` clean; `flutter build apk --debug` after touching `android/`; model logic pure Dart and unit-tested; dispose controllers and timers, check `mounted` after awaits; works offline.

### Phase 0: verify and decide
- [ ] Answer D1–D5 above.
- [ ] From a machine with internet: re-fetch pages 100, 101, 104, 300, 377, 400, 700, 899 and one multi-part page; diff against the fixtures; confirm `content`, `content_plain`, `date_updated_unix` and the empty-list / "ej i sändning" behaviour still hold.
- [ ] Read texttv.nu's API page (`https://texttv.nu/blogg/texttv-api`) for its terms, rate limits, attribution rules and any endpoints that would help (see I-5, I-9, I-14). Record the answers at the top of this file.
- [ ] Decide whether the 3 fixtures become a larger set (see I-15) before porting the tests that use them.

### Phase 1: new project
- [ ] `flutter create --org com.codedbykay --platforms android <repo>`; fix the application id and namespace in `android/app/build.gradle.kts`, `MainActivity` package and `AndroidManifest.xml` label.
- [ ] `pubspec.yaml`: SDK constraint at least `^3.13.0` (the client uses private named parameters, `TextTv({required this._fetcher})`). Dependencies: Flutter only to start. **Do not** bring the launcher's `workmanager`, `enough_mail`, `mobile_scanner`, `dotlottie_flutter`, `flutter_foreground_task`, etc.
- [ ] Copy `analysis_options.yaml`, `.gitignore`, `fonts/PressStart2P-Regular.ttf`, `fonts/OFL.txt`; declare the font in `pubspec.yaml`.
- [ ] Seed `AGENTS.md`, `CLAUDE.md`, `.agents/` (README index, flutter-best-practices, testing-and-quality, architecture) from this repo, rewritten for a one-feature app; put this file's section 3 into the new `.agents/architecture.md` as the module's spec and move the decision-log entries at `.agents/architecture.md` :304-310 across with it.
- [ ] New app icon and name (do not reuse the launcher's C64 icon); `LICENSE` (copy, same author).
- [ ] CI: a GitHub Actions workflow running `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test`, and `flutter build apk --debug` (this repo has none).
- [ ] Verify: empty app builds and runs.

### Phase 2: move the pure Dart core (model + services), tests first
- [ ] Copy, keeping paths under `lib/`: `model/styled_text.dart`, `text_tv_page.dart`, `text_tv_html.dart`, `tv_mosaic.dart`, `tv_layout.dart`, `text_tv_headlines.dart`; `services/text_tv.dart`, `text_tv_repository.dart`, `live_text_tv_repository.dart`, `http_fetcher.dart`, `io_http_fetcher.dart`, `network_exception.dart`.
- [ ] Replace every `package:android_tile_launcher/…` import with the new package name; change the `TextTv` default `_app` and `IoHttpFetcher.userAgent` to the new id.
- [ ] Copy tests: `test/services/text_tv_test.dart`, `text_tv_html_test.dart`, `text_tv_html_pictures_test.dart`, `tv_mosaic_test.dart`, `live_text_tv_repository_test.dart`, `test/model/tv_layout_test.dart`, `text_tv_headlines_test.dart`; fakes `fake_http_fetcher.dart`; fixtures `texttv_100/104/377.json`. Update the `app` id assertion in `text_tv_test.dart` ('asks texttv.nu for the page…, naming this app').
- [ ] Remove the one cross-layer smell while here: `TextTvPage`'s doc refers to `TextTv.columns` (a service) from the model, and the UI hard-codes `40` in `_Grid` and `TvRow`. Make one `textTvColumns` constant in `model/` and use it everywhere.
- [ ] Verify: `dart format`, `flutter analyze`, `flutter test` green with only these tests. Test count of the moved files should equal the count in the launcher.

### Phase 3: move the UI and make it the app
- [ ] Copy `ui/tv_row.dart` and `ui/text_tv_screen.dart`.
- [ ] Create the new `theme.dart` (D2) and replace the `TileColors` / `TileMetrics` / `C64` / `kPixelFontFamily` references listed in 2d. Keep `tvColorOf` as is.
- [ ] Create `messages.dart` with the 6 viewer strings (`title`, `loading`, `tryAgain`, `refresh`, `part`, `pageNotBroadcast`).
- [ ] Turn the viewer from a pushed `fullscreenDialog` route into the app's home screen: remove `showTextTv` and the `X` close button; `PopScope` stays for "back steps through pages, then leaves the app" (set `canPop` the same way). Keep the page-request counter and the `mounted` checks.
- [ ] `main.dart`: build `IoHttpFetcher` → `TextTv` → `LiveTextTvRepository` and pass the repository in. No `TileServices`, `TilePoller` or `TileSource`.
- [ ] Hand the system bars over properly (edge-to-edge, black, light icons) since the page is always black.
- [ ] Copy `test/ui/text_tv_screen_test.dart` and `fake_text_tv_repository.dart`; the `_open` helper pushes the route today, so change it to pump the screen directly and delete the "close button closes it" / "over the whole screen" cases.
- [ ] Verify: format, analyze, test, `flutter build apk --debug`, and run it on a phone: pages 100, 101, 377 (links), 700, a missing page, airplane mode.

### Phase 4: Android checks
- [ ] Manifest: `INTERNET` only. No cleartext traffic. Set `android:label`, own icon, `enableOnBackInvokedCallback` if using predictive back.
- [ ] Release signing: this repo signs release builds with the debug key; create a real keystore for the new app and keep it out of git.
- [ ] Verify on a device: back button, rotation (see I-3), TalkBack reads rows.

### Phase 5: launcher side (only after the standalone app works on a phone)
Order matters. Do **not** just delete the enum value: `PinnedTile.fromJson` drops entries whose kind it does not know (`pinned_tile.dart` :85-90), so every saved Text TV tile, and every exported layout containing one, would silently vanish.
- [ ] Add a migration first: a saved or imported `kind: "textTv"` tile becomes an app tile for the new package id (same size and colour). Look at how an app tile (`TileKind.app` in `tile_view.dart`) behaves when the package is not installed and decide what the user sees (an install hint is better than a blank tile). Unit-test it in `model/` (`pinned_tile_test`, `layout_export_test`).
- [ ] Then remove: the files in 2a and 2b; `TileKind.textTv` and its `displayNameOf` line; `TextTvContent`; the `case TileKind.textTv:` block and imports in `tile_view.dart`; `TileServices.textTv`; the wiring in `main.dart`; `Messages.textTv*` and the help-text line; `test/fixtures/texttv_*.json`, `fake_text_tv_repository.dart`, the field in `fake_tile_services.dart`, the Text TV test in `home_shell_test.dart`, and every test file in 2e.
- [ ] Keep `HttpFetcher`, `IoHttpFetcher`, `NetworkException`, `fake_http_fetcher.dart` (weather and rates use them) and `fonts/PressStart2P` (the whole launcher uses it).
- [ ] Reword the comments in 2c "Comments only".
- [ ] Docs: `README.md` (feature list, INTERNET row, credits keep texttv.nu only if still used), `plan.md` (:7, :9), `.agents/architecture.md` (file index lines, `tile_services` line, decision-log entries moved to the new repo, a short pointer left behind), add a line to `.agents/change_log.md`; link to the new repo.
- [ ] Verify: `dart format`, `flutter analyze`, `flutter test`, `flutter build apk --debug`; test a layout export from before the change imports with the Text TV tile migrated; run on the phone with an existing layout that has the tile.

### Phase 6: improvements (section 6), Tier 1 first, each its own small step with tests

### Phase 7: release
- [ ] Version, changelog, signed release APK/AAB, store listing and privacy text if D5 says Play (I-14).

## 6. Improvements for a standalone app

Ordered by how much a user would notice. Tier 1 are the glaring ones; do them for v1.

### Tier 1

- **I-1. Persistent cache, stale-while-revalidate.** Today the cache is in memory for 5 min, so a cold start with no network shows an error even for a page read a minute ago. Keep pages on disk (SQLite/drift or files; JSON per page), show the cached page immediately, refresh behind it, and say "offline, updated 14:32" using `date_updated_unix` (today it is thrown away). Evict by age/size.
- **I-2. Remember where you were.** Last page, history and last sub-page survive restarts; a cold start opens the last page, not always 100.
- **I-3. Zoom and orientation.** 40 columns fitted to a phone width is small and there is no way to enlarge it (the old decision log already says so). Add pinch-to-zoom / a text-size control, a landscape layout (and tablets: the launcher is portrait-only, a standalone app should not be), and a **reader mode**: the same page as a large-type list of stories (`textTvHeadlines` is the start of it) that also respects the system font size and works well with TalkBack.
- **I-4. Type the number like a real set.** Replace "tap the box, then open a pad" with always-visible digit entry that shows `1--` in the corner and opens on the third digit (what the pad already does), plus **Fastext**: four red/green/yellow/blue buttons built from the page's bottom row links.
- **I-5. Auto-refresh and pull-to-refresh.** Pages change (news, sport results, weather). Refresh on resume if older than N minutes, optional auto-refresh while a page is on screen (30–60 s for live pages), pull-to-refresh next to the REFRESH button, a visible "updated" time. Respect the API's limits (phase 0) and use any "last updated" endpoint the site offers instead of refetching.
- **I-6. Prefetch.** Fetch the previous/next page and the page numbers linked from the current one into the cache so paging feels instant. Also a short page-turn transition (there is none).
- **I-7. Favourites, recents and Android shortcuts.** Star a page (e.g. 377, 400), a recents list, and long-press-the-app-icon shortcuts to the favourites; the six built-in chips become the default favourites, editable.
- **I-8. Network handling.** One 10 s timeout, no retry, and every failure shows the same message style. Distinguish offline / server error / site changed, retry with back-off once, and never block the UI on a failed prefetch.
- **I-9. Search.** Find a page by word or jump by headline. texttv.nu may offer a search or "most read" endpoint (check in phase 0); if not, search the on-disk cache.
- **I-10. Share / copy.** Copy the page text, share it as text or as an image of the page (the plain text is already the source of truth), share a link to texttv.nu's page.
- **I-11. Localization.** Strings and shortcut names are hard-coded caps (English chrome, Swedish chips), and "not in broadcast" is detected by the Swedish phrase. Move strings to ARB (sv + en), name the shortcut chips by language, and treat the phrase check as one of two signals (empty list is the other) so a wording change on the site does not turn "not in broadcast" into a page.

### Tier 2

- **I-12. A proper teletext face and rendering.** Press Start 2P is a game font and the code stretches its glyphs upright (`stretch`, up to 2×) to imitate teletext's tall characters. Evaluate a real teletext font (e.g. Bedstead; check its licence) and drop the stretch. Also: `_paintCell` builds a `TextPainter` for every non-blank character on every repaint (about 900 per page); cache glyph paragraphs per (character, style, size) or draw each row as one paragraph, and wrap the page in a `RepaintBoundary`. Not urgent (a page rarely repaints), but it is the obvious cost if animation or zoom gestures are added.
- **I-13. Sub-page cycling.** Real teletext rotates sub-pages by itself; add a "play" toggle and an indicator `1/3` on the page rather than only the part bar and swipes.
- **I-14. Legal, attribution and store basics.** The content is SVT's, relayed by texttv.nu's author. Before publishing: read their terms, add an About screen crediting SVT Text and texttv.nu, send an `app` id that identifies this app (their API page asks for it), consider contacting the site's author about a published app's extra load, and write a privacy statement ("no account, no analytics; the page number you ask for is sent to texttv.nu"). Add a data-safety note for the Play listing. Do this before D5 decides on the store.
- **I-15. Parser robustness.** The HTML is parsed with regular expressions (non-greedy `<span …>(.*?)</span>`), which works because the site's markup is flat; one change (nested spans, new class) makes `parseTextTvHtml` return null and the page falls back to plain text, losing colours and the block-graphics logo without anyone noticing. Mitigations: snapshot a larger fixture set (all 800 pages once, with a script `tool/fetch_fixtures.dart` that rewrites them), a test that every picture hash on them is known (the current "every picture on the saved pages is known" test generalised), and an optional scheduled CI job that fetches a handful of live pages and fails when parsing falls back. The block-graphics decoder depends on how the site's GIFs are encoded (it rebuilds them byte for byte to match CRC-32s); that dependency should be named in the docs and watched by the same canary.
- **I-16. Accessibility.** Rows already have a semantic label; add a page-level label ("Page 377, part 1 of 2"), announce page changes, make links reachable by TalkBack (rows are one semantics node with `excludeSemantics`, so links inside them are not), and keep ≥ 48 dp targets.

### Tier 3 (later, only if wanted)

- **I-17. Home-screen widget** with the headlines of a chosen page: this is what replaces the launcher tile for people who want live headlines (note: a real widget, which the launcher cannot host, see D1).
- **I-18. Breaking-news notification** for page 100 or a chosen page. Needs background polling and a notification permission; weigh battery and the API's limits before building.
- **I-19. Dark/amoled/colour-blind options**: teletext is always black, but offer a high-contrast palette and a no-flash mode.
- **I-20. Other teletext sources** (the same viewer over another country's service) once the client is behind a small interface; the repository interface already allows it.

## 7. Risks and traps found while reading

- **Saved tiles vanish** if `TileKind.textTv` is deleted without a migration (phase 5).
- **Same `app` id for two apps**: the launcher sends `android_tile_launcher`; the new app must not, and the launcher's tile code must stop sending it once removed.
- **Silent loss of colour** if the site's markup shifts (I-15); nothing reports it today.
- **Hard-coded `40`** appears in the UI as well as `TextTv.columns`; a page of another width would parse to null and fall back to plain text.
- **`flutter test` has no pixel font**, so layout regressions are caught by geometry assertions only; add a golden test with the font loaded (`FontLoader`) in the new repo.
- **Dart SDK**: private named parameters in `TextTv` need a recent SDK; keep the new project's constraint in line with this one.
- **Kotlin is not compiled by `flutter test`**: nothing here touches Kotlin, but the new app's `android/` changes (id, label, signing) need `flutter build apk --debug`.
