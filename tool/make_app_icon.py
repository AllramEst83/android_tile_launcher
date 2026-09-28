"""Builds the Android launcher icon from design/icon/source.jpg and
design/icon/background.jpg.

The source is a JPEG of the four-tile mosaic and rainbow stripe on an off-white
backdrop, so this first cuts the artwork out (flood-filling the light,
colourless backdrop in from the edges, which also clears the white gaps in the
stripe but leaves the pale highlights inside the tiles), then writes:

  * an adaptive icon (Android 8+): the artwork as the foreground layer on the
    scanline-blue background picture, sized so that every opaque pixel sits
    inside the guaranteed-safe circle and no launcher mask (circle, squircle,
    teardrop) can clip it;
  * a monochrome layer for themed icons (Android 13+): the artwork as a flat
    silhouette, which the phone tints;
  * plain rounded-square icons for older Android.

Run from the repo root (needs Pillow: pip install pillow):
    python tool/make_app_icon.py
"""

import os
from collections import deque

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, 'design', 'icon', 'source.jpg')
RES = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')

BACKGROUND_SOURCE = os.path.join(ROOT, 'design', 'icon', 'background.jpg')

# Adaptive icons are drawn on a 108dp canvas; only the middle 72dp circle is
# reliably visible, and 66dp is the guaranteed-safe circle. The farthest
# opaque pixel of the artwork is kept within this radius of the centre.
CANVAS_DP = 108
SAFE_RADIUS_DP = 34

# Legacy (pre-8) icons are 48dp; the artwork is this tall in them.
LEGACY_HEIGHT = 0.80

DENSITIES = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0}


def cut_out_artwork(image):
    image = image.convert('RGB')
    w, h = image.size
    px = image.load()

    def is_backdrop(c):
        r, g, b = c
        return min(r, g, b) >= 225 and max(r, g, b) - min(r, g, b) <= 16

    seen = bytearray(w * h)
    queue = deque()
    for x in range(w):
        queue.extend(((x, 0), (x, h - 1)))
    for y in range(h):
        queue.extend(((0, y), (w - 1, y)))
    while queue:
        x, y = queue.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or seen[y * w + x]:
            continue
        if not is_backdrop(px[x, y]):
            continue
        seen[y * w + x] = 1
        queue.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))

    mask = Image.new('L', (w, h), 0)
    mp = mask.load()
    for y in range(h):
        for x in range(w):
            if not seen[y * w + x]:
                mp[x, y] = 255
    # JPEG ringing leaves a pale rim just inside the artwork; shave a pixel.
    mask = mask.filter(ImageFilterMin(3))
    rgba = image.convert('RGBA')
    rgba.putalpha(mask)
    return rgba.crop(mask.getbbox())


def ImageFilterMin(size):
    from PIL import ImageFilter

    return ImageFilter.MinFilter(size)


def farthest_pixel(artwork):
    """Distance from the artwork's centre to its farthest opaque pixel."""
    small = artwork.resize(
        (artwork.width // 4, artwork.height // 4), Image.NEAREST
    )
    alpha = small.getchannel('A').load()
    cx, cy = small.width / 2, small.height / 2
    far = 0.0
    for y in range(small.height):
        for x in range(small.width):
            if alpha[x, y] > 128:
                far = max(far, ((x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2) ** 0.5)
    return far * 4


def scaled(artwork, factor):
    return artwork.resize(
        (max(1, round(artwork.width * factor)), max(1, round(artwork.height * factor))),
        Image.LANCZOS,
    )


def centred(layer, size, canvas):
    canvas.alpha_composite(
        layer, ((size - layer.width) // 2, (size - layer.height) // 2)
    )
    return canvas


def silhouette(layer):
    flat = Image.new('RGBA', layer.size, (255, 255, 255, 255))
    flat.putalpha(layer.getchannel('A'))
    return flat


def save(image, folder, name):
    path = os.path.join(RES, folder)
    os.makedirs(path, exist_ok=True)
    image.save(os.path.join(path, name), optimize=True)


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', newline='\n') as f:
        f.write(text)


def main():
    artwork = cut_out_artwork(Image.open(SOURCE))
    # Work in pixels of the (large) cut-out, scaled per density below.
    radius = farthest_pixel(artwork)
    background = Image.open(BACKGROUND_SOURCE).convert('RGB')

    for name, density in DENSITIES.items():
        size = round(CANVAS_DP * density)
        factor = SAFE_RADIUS_DP * density / radius
        fitted = scaled(artwork, factor)

        # Adaptive foreground: 108dp, artwork only, transparent around it.
        foreground = centred(fitted, size, Image.new('RGBA', (size, size), (0, 0, 0, 0)))
        save(foreground, f'mipmap-{name}', 'ic_launcher_foreground.png')
        save(
            background.resize((size, size), Image.LANCZOS).convert('RGBA'),
            f'mipmap-{name}',
            'ic_launcher_background.png',
        )
        save(
            centred(
                silhouette(fitted),
                size,
                Image.new('RGBA', (size, size), (0, 0, 0, 0)),
            ),
            f'mipmap-{name}',
            'ic_launcher_monochrome.png',
        )

        # Legacy icon: 48dp rounded square with the artwork filling most of it.
        size = round(48 * density)
        legacy = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        square = Image.new('L', (size * 4, size * 4), 0)
        ImageDraw.Draw(square).rounded_rectangle(
            (0, 0, size * 4 - 1, size * 4 - 1), radius=size * 4 * 0.18, fill=255
        )
        square = square.resize((size, size), Image.LANCZOS)
        colour = background.resize((size, size), Image.LANCZOS).convert('RGBA')
        legacy.paste(colour, (0, 0), square)
        legacy = centred(
            scaled(artwork, size * LEGACY_HEIGHT / artwork.height), size, legacy
        )
        save(legacy, f'mipmap-{name}', 'ic_launcher.png')

    write(
        os.path.join(RES, 'mipmap-anydpi-v26', 'ic_launcher.xml'),
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@mipmap/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n'
        '</adaptive-icon>\n',
    )
    # A preview of the finished adaptive icon under a circle mask, for a look.
    preview_size = 432
    preview = background.resize((preview_size, preview_size), Image.LANCZOS).convert('RGBA')
    fitted = scaled(artwork, SAFE_RADIUS_DP * 4 / radius)
    centred(fitted, preview_size, preview)
    circle = Image.new('L', (preview_size * 2, preview_size * 2), 0)
    ImageDraw.Draw(circle).ellipse(
        (preview_size * 2 * (1 - 72 / 108) / 2,) * 2
        + (preview_size * 2 * (1 + 72 / 108) / 2,) * 2,
        fill=255,
    )
    circle = circle.resize((preview_size, preview_size), Image.LANCZOS)
    out = Image.new('RGBA', (preview_size, preview_size), (0, 0, 0, 0))
    out.paste(preview, (0, 0), circle)
    os.makedirs(os.path.join(ROOT, 'design', 'icon'), exist_ok=True)
    out.save(os.path.join(ROOT, 'design', 'icon', 'preview_circle.png'))
    print('icons written to', RES)


if __name__ == '__main__':
    main()
