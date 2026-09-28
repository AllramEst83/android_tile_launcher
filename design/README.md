# design/

Reference material and the sources of the icon. Nothing here is code, and
nothing here is read by the app at runtime.

| Folder | What it is | Used for |
|---|---|---|
| `reference/` | Photos and screenshots of Commodore hardware and software: the C64 and C64C, the Datasette, an Amiga 500, the C64 logo and stripe, two C64 user interfaces. | **The look and feel.** Light blue on blue, beige-and-brown hardware (the beige theme), the rainbow stripe, chunky bevels, pixel type. |
| `mockups/` | Four UI concepts from a design tool (`home.png`, `all-apps-drawer.png`, `grid-editor.png`, `settings.png`) and `DESIGN.md`, the design system that went with them ("Metro Flow"). | **Structure only:** which screens exist and what is on them. Their frosted acrylic, rounded corners, Inter type and Fluent palette are *not* the target look. All four screens are built. |
| `icon/` | `source.jpg` (the tile mosaic on an off-white backdrop), `background.jpg` (the scanline-blue background), `preview_circle.png` (the finished adaptive icon under a circle mask, used by the README). | Input to `python tool/make_app_icon.py`, which writes every Android icon size. Change the pictures and re-run the script; do not edit the generated PNGs under `android/`. |

`prompts.md` keeps the image-generation prompts for the icon and the lock-screen
wallpapers, with the file names and formats each one is meant to produce.

The pictures in `reference/` and `mockups/` are not this project's own work and
are not covered by its MIT licence; they are kept as private reference for the
look and would be removed from any public redistribution of the repository.
