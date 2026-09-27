---
name: Metro Flow
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#393939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1b1b1b'
  surface-container: '#1f1f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353535'
  on-surface: '#e2e2e2'
  on-surface-variant: '#c0c7d4'
  inverse-surface: '#e2e2e2'
  inverse-on-surface: '#303030'
  outline: '#8a919e'
  outline-variant: '#414752'
  surface-tint: '#a4c9ff'
  primary: '#a4c9ff'
  on-primary: '#00315d'
  primary-container: '#0078d7'
  on-primary-container: '#000510'
  inverse-primary: '#005fad'
  secondary: '#4bd9e5'
  on-secondary: '#00363b'
  secondary-container: '#02b7c3'
  on-secondary-container: '#004347'
  tertiary: '#ffb597'
  on-tertiary: '#581d00'
  tertiary-container: '#cc4e00'
  on-tertiary-container: '#ffffff'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d4e3ff'
  primary-fixed-dim: '#a4c9ff'
  on-primary-fixed: '#001c39'
  on-primary-fixed-variant: '#004884'
  secondary-fixed: '#7ff4ff'
  secondary-fixed-dim: '#4bd9e5'
  on-secondary-fixed: '#002022'
  on-secondary-fixed-variant: '#004f55'
  tertiary-fixed: '#ffdbcd'
  tertiary-fixed-dim: '#ffb597'
  on-tertiary-fixed: '#360f00'
  on-tertiary-fixed-variant: '#7d2d00'
  background: '#131313'
  on-background: '#e2e2e2'
  surface-variant: '#353535'
typography:
  display-hero:
    fontFamily: Inter
    fontSize: 56px
    fontWeight: '200'
    lineHeight: 60px
    letterSpacing: -0.03em
  display-metric:
    fontFamily: Inter
    fontSize: 40px
    fontWeight: '300'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '300'
    lineHeight: 36px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '400'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.005em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: 0em
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0em
  label-tile-title:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
  label-badge:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.02em
  label-micro:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '500'
    lineHeight: 12px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 0.5rem
  margin: 0.75rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style

This design system fuses the utilitarian typographic purity and motion-driven ethos of the classic Metro interface with the tactile materials of modern Fluent design, tailored natively for Android. It rejects ornamental skeuomorphism and excessive drop shadows in favor of authentic digital hierarchy, information-dense typography, and vibrant chromatic energy.

The aesthetic rests upon three pillars:
- **Glanceable Authenticity:** Information takes center stage over containers. Large typographic displays communicate state instantly, eliminating the need to dive into applications for basic daily updates.
- **Acrylic Depth & Modern Tactility:** Deep OLED surfaces layered with translucent acrylic live tiles bring soft light diffraction, grounding nostalgic flat geometry in contemporary hardware-accelerated materials.
- **Dynamic Modular Rhythm:** Asymmetric tile arrangements transform the launcher from a passive app drawer into a pulsating personal dashboard.

## Colors

The palette leverages an absolute OLED pitch-black foundation (`#000000`), allowing vivid chromatic accents to illuminate content with optical intensity.

- **Primary Accent (`#0078D7` / Cobalt):** Anchor for active states, dominant system actions, and default hero live tiles.
- **Secondary (`#00B7C3` / Cyan):** Expressive status indicators, secondary live tiles, communication alerts, and live glyph highlights.
- **Tertiary (`#F7630C` / Mango):** Media controls, urgent calendar notifications, battery warnings, and focal callouts.
- **Neutral Surface Ecosystem:**
  - Base Canvas: `#000000` (Pure OLED)
  - Tile Background (Solid): `#111111`
  - Acrylic Glass Tile (Translucent): `rgba(25, 25, 25, 0.72)` with a 20px background blur
  - Subtle Border Strokes: `rgba(255, 255, 255, 0.08)`
  - Elevated Popovers/Sheets: `#1A1A1A`
- **Text & Foreground:**
  - High Emphasis: `#FFFFFF` (100%)
  - Medium Emphasis: `rgba(255, 255, 255, 0.68)`
  - Micro / Disabled: `rgba(255, 255, 255, 0.42)`

## Typography

The type system prioritizes high-ratio scale contrasts reminiscent of classic Swiss modernism and Windows Phone's oversized typographic anchors. **Inter** serves across all typographic levels due to its geometric neutrality, pristine tabular lining figures, and ultra-light weights at massive scales.

Key rules:
- **Dramatic Disproportion:** Giant numerals (`display-hero` and `display-metric`) are juxtaposed directly against strict, uppercase `label-micro` tags to create an editorial cadence without requiring iconography.
- **Light Display Weights:** Headlines larger than 24px default to Light (`300`) or Extra Light (`200`) weight to maintain high visual impact without visual heaviness.
- **Micro-Labels & Anchors:** Bottom-left anchored tile titles use `label-tile-title` with all-caps styling and positive letter-spacing (`0.04em`), ensuring readability against busy live backgrounds.

## Layout & Spacing

The canvas is constructed on an exact 4-column base modular grid governed by an **8px base unit**. 

- **Outer Margin:** `0.75rem` (12px) horizontal screen margin ensures maximum screen utilization while clearing bezel palm-rejection buffers.
- **Grid Gutter:** `0.5rem` (8px) unified distance between all tiles. This tight spacing produces the signature solid mosaic tile aesthetic.
- **Tile Geometry:**
  - Small: `1x1` (1 column width × 1 base row height)
  - Medium: `2x2` (2 column width × 2 base row heights + 1 gutter)
  - Wide: `4x2` (Full 4 column width × 2 base row heights + 1 gutter)
  - Large: `4x4` (Full 4 column width × 4 base row heights + 3 gutters)
- **Vertical Hierarchy:**
  - Top: Safe area padding for the Android status bar (`space-xl`), followed by a continuous horizontal text carousel or glanceable header.
  - Body: Continuous vertical scrolling live-tile stream.
  - Bottom: Gestural navigation margin (`space-lg`) preventing accidental tile clicks when performing home bar gestures.

## Elevation & Depth

This system intentionally eliminates traditional diffuse drop shadows. Depth and visual hierarchy are instead expressed through **refractive layering, opacity, and flat planar motion**:

- **Layer 0 (Canvas Base):** Deep `#000000` canvas. Provides maximum contrast and battery conservation on OLED panels.
- **Layer 1 (Tiles & Surfaces):** Acrylic frosted surfaces using `rgba(25, 25, 25, 0.72)` combined with `backdrop-filter: blur(20px) saturate(125%)`. Each tile features an inner stroke of `1px solid rgba(255, 255, 255, 0.08)` to clearly distinguish adjacent items without cast shadows.
- **Layer 2 (Accent & Active Surfaces):** Colored tiles use 85% opacity chromatic fills, allowing wallpaper luminescence to filter through while preserving contrast.
- **Interactive Depth (3D Perspective Shift):** On touch press, tiles do not cast shadows; they tilt slightly along their 3D axis toward the point of contact (`transform: perspective(600px) rotateX(...) rotateY(...) scale(0.98)`), echoing classic hardware responsiveness.

## Shapes

While historical Metro design relied on rigid 0px edges, this modern Android-adapted design system introduces a subtle, controlled corner radius to match modern hardware curvature and Android gesture conventions:

- Base tile corners use **12px** (`roundedness: 2`), softening the mosaic while preserving geometric discipline.
- Nested chips, counters, and status badges use pill profiles or **4px** radii to signal secondary utility.
- Modal panels and pull-up sheets leverage an asymmetric top-rounded corner of **20px** with flat bottom corners.

## Components

### Live Tiles (Core Primitive)
- **Container:** Acrylic or accent-colored surface with 12px border radius and 1px edge stroke.
- **Metadata Placement:** The bottom edge hosts the title label (`label-tile-title`) in the bottom-left corner and notification badge counter in the bottom-right corner.
- **Content Zones:**
  - *Small (1x1):* Centered 28px linear icon or single critical metric.
  - *Medium (2x2):* Icon in top-left, live micro-content (e.g., weather condition + temperature) in center, title at base.
  - *Wide (4x2):* Split layout. Left holds icon/summary; right displays scrolling agenda items, multi-day forecasts, or audio progress.
  - *Large (4x4):* Editorial card with full imagery, interactive playback controls, or dense unread message previews.

### Notification Badges
- Pill or square-circle containers positioned strictly in the tile's lower-right corner.
- Background: Solid contrast accent or pure white with dark typography (`label-badge`).
- Shows raw numerical values (e.g., `3`, `12`) without superfluous ornament.

### Buttons & Quick Actions
- Flat, highly saturated rectangular blocks with 8px inner padding and 8px border radius.
- States: Default uses a semi-transparent surface (`rgba(255, 255, 255, 0.12)`); active state switches to full Cobalt (`#0078D7`) with white text.

### Search & App Drawer Inputs
- Edge-to-edge minimalist search bar with a transparent background, single bottom border line (`1.5px solid rgba(255, 255, 255, 0.3)`), and high-contrast placeholder typography.
- Focused state transitions the border to Cyan (`#00B7C3`) with zero drop shadow.

### Alphabet App List (All Apps)
- Vertically scrolling linear list with large letter jump-markers (e.g., `A`, `B`, `C`) styled with `headline-md` in accent colors.
- App rows feature a 36px monochrome geometric glyph, followed by a single line of `body-lg` text, maintaining 48px minimum touch targets.