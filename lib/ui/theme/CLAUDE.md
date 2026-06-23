# lib/ui/theme — Theme assembly

Pure-Dart theming. The `MaterialApp.router` in `main.dart` calls
`buildAppTheme(palette)` **once** (single `theme:`, no `darkTheme`/
`themeMode`) inside a `ListenableBuilder(listenable: themeSettings, ...)`
so palette / accent / text colour / brightness flips rebuild live.
**Each palette bakes in its own brightness (GUS-27)** — selecting Light
vs Dark is what flips the app; the OS brightness is no longer followed.

## Files

- [app_theme.dart](app_theme.dart) — `buildAppTheme(SurfacePalette palette)`.
  Pure function that:
  1. Reads `brightness = palette.brightness`, `surface = palette.surface`,
     and seeds an initial `ColorScheme` from `palette.seed` (gives M3 a
     reasonable starting point).
  2. **Derives the surfaceContainer tiers** by `Color.lerp(surface, onSurface, t)`
     with `t ∈ {0.03, 0.05, 0.08, 0.12}`. This is why blocks read as
     elevated against the dimmed base — the elevation is in surface
     color, not Material tint.
  3. Uses `palette.defaultTextColor ?? contrastOn(surface)` for
     `onSurface`, so custom palettes can carry a chosen font colour.
  4. Sets `primary` to the palette's **accent** (`defaultAccent`, user's
     10%), `secondary` to `defaultSecondary` (user's 30%), `tertiary` to
     a 40% lerp between them (a derived harmony).
  5. Computes container variants (`primaryContainer`, `secondaryContainer`,
     `tertiaryContainer`) by lerping each chroma toward the surface, with
     dark themes using a smaller lerp (0.30/0.35) so the accent stays
     visible against the dark base.
  6. Configures `appBarTheme` (no surfaceTint, no elevation),
     `bottomNavigationBarTheme`, `chipTheme`, `dividerTheme`. Ensures
     `scaffoldBackgroundColor == scheme.surface` so screens with no
     explicit `body` background still pick up the palette.
  7. Wires the **type system** (GUS-84): `fontFamily: kBodyFamily` (Inter)
     for stray `Text`, and `textTheme: buildAppTextTheme().apply(bodyColor:
     onSurface, displayColor: onSurface)` so every slot is tinted with the
     palette's text colour (the styles in `app_typography` carry no colour).
  - The old `secondary` / `accent` / `textColor` / `surfaceOverride` /
    `brightness` parameters are **gone** (GUS-27) — they only existed for
    the removed debug overrides. Everything is read off the palette now.
- [surface_palette.dart](surface_palette.dart) — `SurfacePalette` class
  (now carries `final Brightness brightness` + a single `final Color
  surface`; no `surfaceFor(brightness)`) + two built-in defaults
  `kLightDefaultPalette` (id `light`) and `kDarkDefaultPalette` (id
  `dark`), collected in `kBuiltInPalettes`. Both built-ins are free and
  always selectable; they are not editable/deletable. **Warm tactile
  palette (GUS-85):** the defaults are warm, not the old cool greys —
  light `surface` is warm cream `#FAF6EF` with warm near-black ink
  `#2B2622`; dark `surface` is warm near-black `#1A1714` with warm
  off-white ink `#F3ECE2`; the accent is a soft terracotta (`#C57B57`
  light / `#D98E68` dark) so CTAs/focus read warm. Re-cooling these
  undoes the redesign. Custom themes are
  decoded by `ThemeSettings` from persisted JSON (each carries its own
  `brightness` + `surface`) and use generated ids. `paletteById(id)`
  falls back to `kLightDefaultPalette` on unknown id — safe to call with
  a settings value that might have been written by an older version.
- [app_typography.dart](app_typography.dart) — the house **type system**
  (GUS-84). Two bundled OFL **variable** fonts (declared in `pubspec.yaml`,
  files in `assets/fonts/`): **Playfair Display** (`kDisplayFamily`) — a
  high-contrast transitional serif for the journal voice (titles, dates,
  headings), single `wght` axis (smaller display slots carry w600 so the
  hairlines hold up); **Inter** (`kBodyFamily`) — clean sans for body text +
  all UI chrome. `buildAppTextTheme()` assigns `display* / headline* /
  titleLarge / titleMedium` → Playfair Display and `titleSmall / body* /
  label*` → Inter (`titleSmall` is Inter on purpose: it labels UI chrome).
  `AppText` exposes named journal styles that don't map onto a Material slot
  (`entryTitle`, `entryDate`, `sectionHeading`) — read these instead of
  hand-rolling a `TextStyle`. We bundle the TTFs (no `google_fonts` runtime
  package); a single variable file per family carries every weight (Flutter
  maps `FontWeight` → the `wght` axis).
- [tonal.dart](tonal.dart) — the **tonal same-hue colour system** for coloured
  blocks (GUS-86). `tonalBlockBackground(base, brightness)` derives a soft,
  low-chroma tint of `base`'s hue (light wash in light themes, deep muted card
  in dark); `tonalBlockForeground(base, brightness)` derives a saturated
  **same-hue** ink for text + icons and walks its lightness until it clears a
  WCAG contrast `target` (default 5.0) against the background — so even a
  near-grey or awkward base resolves to legible text. `contrastRatio(a, b)` is
  the WCAG ratio helper. Used by `block_chrome` instead of the old
  `colorFromHex` + `contrastOn(bg)` black/white flip: every coloured block now
  reads as "one hue, tinted, with matched ink", coherent across a multi-colour
  grid. Block colours stored in `BlockVisuals.colorHex` are **hue anchors** —
  re-interpreted through this mapper at render time (no schema change).
- [color_hex.dart](color_hex.dart) — three top-level helpers:
  - `colorToHex(Color)` → `#RRGGBB` (uses the M3 `Color.r`/`.g`/`.b`
    floats, scaled to 0-255).
  - `colorFromHex(String?)` → `Color?` (null on missing/invalid;
    accepts with or without `#`, 6- or 8-hex).
  - `contrastOn(Color)` → black or white based on luminance threshold
    0.5. Used for every `on*` colour in `buildAppTheme`.

## Implementation details

- **Why a pure function?** `ListenableBuilder(listenable: themeSettings)`
  in `main.dart` calls `buildAppTheme(palette)` once on each
  `themeSettings` notification. The function is cheap and stateless, so
  rebuild cost is negligible.
- **Why `Color.lerp` for containers?** A traditional `ColorScheme.fromSeed`
  produces tints that don't quite match a manually-curated dimmed dark
  palette. Lerping from the palette's own surface keeps the dimmed
  feel; M3's seed-derived hues only provide the *non*-surface anchors.
- **Persisted colors are `#RRGGBB`**. `ThemeSettings` round-trips
  user-picked overrides and custom-palette JSON via `color_hex`. Don't
  store ARGB hex anywhere user-facing — alpha isn't user-controllable.
- **User themes live in settings, not Hive model boxes.** `ThemeSettings`
  decodes the `theme.customPalettes` JSON list, appends those themes
  after the two built-in defaults, and notifies listeners when a theme is
  added, edited, or deleted. Each custom-palette JSON object now carries a
  `brightness` (`'light'`/`'dark'`) and a single `surface` color; decode
  is tolerant (missing brightness → inferred from surface luminance).
- **Post-it palette is a separate concept.** `SurfacePalette` is the
  *theme* palette (one active at a time, owns surface + secondary +
  accent + text). The post-it palette — a flat `List<String>` of
  `#RRGGBB` hex on `ThemeSettings.postItPalette` — feeds the random
  per-block background color in `BlockVisuals.random` at entry
  materialization. Foreground is computed by `contrastOn(bg)` at
  render time (in `PostItBlock`), not stored.

## Gotchas

- **`palette` is derived from `ThemeSettings.palettes`.** The two
  built-in defaults are static; user theme edits rebuild live because
  `ThemeSettings` persists the JSON list and notifies.
- **`contrastOn` is a luminance threshold, not a WCAG-correct contrast
  check.** Custom palettes let users choose a text colour manually; the
  fallback still uses the threshold.
- **Don't add `surfaceTint` anywhere.** M3's elevation tint fights with
  the manual surfaceContainer tiers and makes blocks look flat in dark
  mode. `appBarTheme.surfaceTintColor: Colors.transparent` is set for
  the same reason.

## When to update this file

- The default palette changes, or user-theme JSON shape changes.
- The container-tier math in `buildAppTheme` changes.
- A new persisted theme override is added (and add a typed key pair in
  [data/services/settings_storage_service.dart](../../data/services/settings_storage_service.dart)).
