# Bloom — Splash Screen

## Design

A five-petal cherry-blossom mark — each petal a rounded lobe with a small
notch at its outer tip, in the style of 🌸 — blooms open around a warm
sunrise-gold heart. The same mark also replaces both letterforms of "o" in
the wordmark itself: **"Bl🌸🌸m"**, with each flower spinning smoothly and
continuously in place for as long as the splash is on screen. The flower
opens first (staggered, petal by petal), the heart settles in, then the
wordmark rises in with its two blossoms already spinning — so the reading
order is always **flower opens → name arrives, mid-spin**, not everything
appearing at once.

Colors and type are pulled directly from the app's own dark theme
(`#191115` background, `#7A2942`/`#3A222C` glow, Fraunces wordmark), so the
splash feels like a continuation of the icon the person just tapped, not a
separate marketing asset.

Total runtime: ~2.4s of bloom-in animation + a brief hold (with the wordmark
flowers still spinning throughout), then a 500ms cross-fade into the Home
screen.

## Vector source

`assets/splash/flower.svg` is the single source of truth for the petal
shape — a 5-petal mark built from one `<path>` (four cubic Bézier segments
forming a lobe with a notch at its tip) reused via `<use>` at five 72°
rotations, with radial gradients for petal shading and the center heart.
`lib/screens/splash_screen.dart`'s `_BlossomPainter` reproduces the exact
same normalized Bézier points in Dart (documented inline) so the in-app
vector rendering matches the SVG exactly rather than approximating it.
Edit the SVG first if you ever want to adjust the petal shape, then port
the same control points into `_BlossomPainter`.


## Two screens, on purpose

There are actually **two** splash-related surfaces, and they're intentionally
different:

1. **Native launch screen** (OS-level, shows instantly before the Flutter
   engine even starts) — kept deliberately minimal: just the flower mark,
   centered, on the app's background color, **no wordmark, no tagline, no
   animation**. This follows Apple's Human Interface Guidelines directly:
   > "A launch screen isn't an opportunity for a splash screen... avoid
   > including text in your launch screen." — the native screen's only job
   > is to appear instantly and feel like the first frame of the app, not to
   > brand or delight.
2. **In-app splash** (`lib/screens/splash_screen.dart`) — shown *after* the
   Flutter engine has taken over, where the full animated bloom + wordmark +
   tagline experience lives. This is a normal app screen like any other, so
   none of the native-launch-screen restrictions apply here — this is where
   the "beautiful, enhances the experience" ask fully lives.

This split is what keeps the app both HIG-compliant *and* delightful: Apple
never sees a "branded splash screen" at the OS level, but the person still
gets the full blooming-flower moment a beat later.

## Files

- `lib/screens/splash_screen.dart` — the in-app animated splash (pure
  `CustomPainter`/vector, no image asset dependency, so it's crisp at any
  device resolution and has zero extra load time).
- `assets/splash/flower.svg` — **the vector source** for the mark. Open this
  in Figma/Illustrator/any SVG tool to edit the design directly.
- `assets/splash/native_launch_logo_512.png` — the mark-only PNG used for
  the native launch screen via `flutter_native_splash`.
- `assets/splash/bloom_logo.png` — full-resolution (1024px) transparent
  raster of the mark, reused anywhere else in the app or marketing
  materials that need a static, high-res logo rather than the live vector.
- `pubspec.yaml` → `flutter_native_splash:` section — config for generating
  the native Android/iOS launch screens. After editing, regenerate with:
  ```bash
  dart run flutter_native_splash:create
  ```

## Wiring

`main.dart` now routes through a small `_RootRouter` that shows
`SplashScreen` first and cross-fades into the existing `AppShell` once the
splash's `onFinished` callback fires — no changes needed anywhere else in
the app's navigation.
