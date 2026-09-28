# Image prompts

The prompts used (or handed over) to generate this project's pictures, so they
can be revisited, tweaked and re-run. Palette values are the launcher's own
(`lib/ui/theme.dart`): blue `#2E2C9B`, light blue `#706DEB`, the rainbow stripe
`#E2342B #F58220 #FFEC00 #3AB54A #0095DA`.

Where the results go, and what turns them into the app's files:

| Picture | Goes in | Turned into |
|---|---|---|
| Icon foreground | `design/icon/source.jpg` | `python tool/make_app_icon.py` (icons under `android/`) |
| Icon background | `design/icon/background.jpg` | the same script |
| Wallpapers | `assets/wallpapers/wallpaper_{c64,oled,beige}.png` | bundled as assets; SETTINGS → WALLPAPER puts one on the phone |

The wallpapers in `assets/wallpapers/` are the pictures generated from the
prompts below (1290×2870 PNG). To try new ones, replace the files with the same
names; nothing else needs to change. The file name is derived from the theme in
`wallpaperAssetOf` (`lib/model/wallpaper.dart`).

---

## App icon (Phase 18)

**Format asked for:** PNG, two separate files. The foreground on a *transparent*
background (500×500 or larger is enough; the largest layer Android needs is
432×432 px), everything important inside the middle ~60%, because Android crops
the outer edge to a circle or squircle. The background opaque and full-bleed.
If the generator cannot make transparency, ask for the foreground on flat white
and cut it out afterwards. The version that was actually used is a JPEG on an
off-white backdrop that `tool/make_app_icon.py` cuts out itself.

### Foreground

```
App icon foreground artwork for an Android launcher app, 1024x1024, transparent background, no text, no letters, no drop shadow outside the artwork.

Subject: a 2x2 mosaic of four chunky square tiles, seen straight on, slightly rounded corners of only a few pixels, each tile with a thick pixel-art bevel (a lighter 1-tile-pixel edge on the top and left, a darker edge on the bottom and right) so they look like physical Commodore 64 keycaps or hardware buttons. The four tiles are different flat VIC-II colours: blue #2E2C9B, purple #8E3C97, green #56AC4D and yellow #EDF171. One tile (the top right) is pushed in slightly, with its bevel reversed, to suggest it is being pressed. A small 5-stripe rainbow rule (red #E2342B, orange #F58220, yellow #FFEC00, green #3AB54A, blue #0095DA) runs across the top of the mosaic, like the classic Commodore stripe.

Style: authentic 1980s Commodore 64 / VIC-II aesthetic, crisp hard pixel edges, no anti-aliased gradients, no glow, no photorealism, limited flat colour palette, hand-drawn pixel-art feel. Perfectly symmetrical, centred, generous empty margin around the mosaic: the whole artwork fits inside the middle 60% of the canvas.
```

### Background

```
Flat square background texture for an Android app icon, 1024x1024, full bleed, no subject, no text, no border. Solid deep C64 blue #2E2C9B with very subtle, evenly spaced horizontal scanlines (slightly darker, about 6% opacity) like an old CRT screen. No gradients, no vignette, no glow.
```

### Optional extras

- **Beige variant:** swap the background for a warm beige `#D8CDB2` with faint
  brown `#553800` scanlines, for a "hardware" look.
- **Quality check:** if the generator smooths the pixel edges, add
  "nearest-neighbour upscaled from a 64x64 pixel grid".

---

## Lock-screen wallpapers (Phase 19)

**Format asked for:** three portrait pictures, one per theme, named
`wallpaper_c64.png`, `wallpaper_oled.png` and `wallpaper_beige.png` (a JPEG works
too if the file name in `wallpaperAssetOf` is changed). 9:20 aspect, at least 1080×2400, ideally 1290×2870. No transparency,
no layers.

**Layout rules:**
- The phone draws its own clock and notifications over the top third of a
  lock-screen wallpaper and shortcuts over the bottom fifth. Keep those areas
  calm and low-contrast, with the detail in the middle band.
- Tile Launcher paints its own screen, so a *home-screen* wallpaper only shows
  behind other launchers and in the app switcher. The lock screen is the one
  that matters; it is the default in settings.

### Shared style (paste at the start of each prompt)

```
Portrait phone wallpaper, 9:20 aspect ratio, 1290x2870 pixels. Authentic 1980s Commodore 64 / VIC-II aesthetic: crisp hard-edged pixel art, flat colours, no gradients, no glow, no photorealism, no text or letters anywhere, no people. A subtle CRT scanline texture (thin horizontal lines, about 6% darker). The top third and the bottom fifth of the image must be calm, low-detail and low-contrast, because the phone draws a clock and shortcuts over them; put the interest in the middle band. Palette limited to the VIC-II colours: blue #2E2C9B, light blue #706DEB, black, white, and the rainbow stripe red #E2342B, orange #F58220, yellow #FFEC00, green #3AB54A, blue #0095DA.
```

### 1. `wallpaper_c64.png`

```
[shared style] Solid C64 blue #2E2C9B screen filling the whole image with a slightly lighter light-blue #706DEB border frame 40 pixels thick, like the C64 start-up screen. In the middle band, a large field of chunky bevelled square tiles, like the tiles of a phone home screen, in flat VIC-II colours (purple, green, yellow, cyan, orange), arranged in a loose mosaic that fades out to plain blue at the top and bottom. Each tile has a pixel bevel: light top and left edge, dark bottom and right edge. A thin five-stripe rainbow rule runs across the image at about 40% of the height.
```

### 2. `wallpaper_oled.png`

```
[shared style] Pure black #000000 background over the whole image (true black, so an OLED screen switches those pixels off). In the middle band only, a small, sparse cluster of the same chunky bevelled pixel tiles in blue, purple, green and yellow, with a thin five-stripe rainbow rule beside them. Everything else stays pure black, with no scanlines on the black.
```

### 3. `wallpaper_beige.png`

```
[shared style, but replace the palette line] Warm beige plastic #D8CDB2, like the case of an 80s home computer, with faint brown #553800 scanlines. In the middle band, a row and column of chunky keyboard-key shaped squares in brown #8E5029 and cream, with a bevelled light top-left and dark bottom-right edge, like the keys of a C64 keyboard seen from above, fading out to plain beige at the top and bottom. A thin five-stripe rainbow rule in the lower third.
```

If a picture comes out with text in it, or busy top and bottom areas, re-roll it.
