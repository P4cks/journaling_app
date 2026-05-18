# lib/ui/theme — Theme assembly

Pure-Dart theming. The `MaterialApp.router` in `main.dart` calls
`buildAppTheme(...)` twice (once for light, once for dark) inside a
`ListenableBuilder(listenable: themeSettings, ...)` so palette / accent /
text colour / brightness flips rebuild live.

## Files

- [app_theme.dart](app_theme.dart) — `buildAppTheme({palette, brightness, secondary, accent, textColor, surfaceOverride})`.
  Pure function that:
  1. Seeds an initial `ColorScheme` from `palette.seed` (gives M3 a
     reasonable starting point).
  2. Picks the surface from `surfaceOverride ?? palette.surfaceFor(brightness)`.
  3. **Derives the surfaceContainer tiers** by `Color.lerp(surface, onSurface, t)`
     with `t ∈ {0.03, 0.05, 0.08, 0.12}`. This is why blocks read as
     elevated against the dimmed base — the elevation is in surface
     color, not Material tint.
  4. Uses `textColor ?? palette.defaultTextColor ?? contrastOn(surface)`
     for `onSurface`, so custom palettes can carry a chosen font colour.
  5. Sets `primary` to the **accent** (user's 10%), `secondary` to the
     **secondary** (user's 30%), `tertiary` to a 40% lerp between them
     (a derived harmony).
  6. Computes container variants (`primaryContainer`, `secondaryContainer`,
     `tertiaryContainer`) by lerping each chroma toward the surface, with
     dark themes using a smaller lerp (0.30/0.35) so the accent stays
     visible against the dark base.
  7. Configures `appBarTheme` (no surfaceTint, no elevation),
     `bottomNavigationBarTheme`, `chipTheme`, `dividerTheme`. Ensures
     `scaffoldBackgroundColor == scheme.surface` so screens with no
     explicit `body` background still pick up the palette.
- [surface_palette.dart](surface_palette.dart) — `SurfacePalette` class
  + `kDefaultSurfacePalette` / `kSurfacePalettes`. Graphite is the only
  built-in palette and is not editable or deletable. User themes are
  decoded by `ThemeSettings` from persisted JSON and use generated ids.
  `paletteById(id)` falls back to Graphite on unknown id — safe to call
  with a settings value that might have been written by an older version
  of the app.
- [color_hex.dart](color_hex.dart) — three top-level helpers:
  - `colorToHex(Color)` → `#RRGGBB` (uses the M3 `Color.r`/`.g`/`.b`
    floats, scaled to 0-255).
  - `colorFromHex(String?)` → `Color?` (null on missing/invalid;
    accepts with or without `#`, 6- or 8-hex).
  - `contrastOn(Color)` → black or white based on luminance threshold
    0.5. Used for every `on*` colour in `buildAppTheme`.

## Implementation details

- **Why a pure function?** `ListenableBuilder(listenable: themeSettings)`
  in `main.dart` calls `buildAppTheme` twice on each `themeSettings`
  notification (light + dark). The function is cheap and stateless, so
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
  after Graphite, and notifies listeners when a theme is added, edited,
  or deleted. Legacy `custom1`/`custom2`/`custom3` map JSON is still
  decoded for users who tried the earlier slot implementation.
- **Post-it palette is a separate concept.** `SurfacePalette` is the
  *theme* palette (one active at a time, owns surface + secondary +
  accent + text). The post-it palette — a flat `List<String>` of
  `#RRGGBB` hex on `ThemeSettings.postItPalette` — feeds the random
  per-block background color in `BlockVisuals.random` at entry
  materialization. Foreground is computed by `contrastOn(bg)` at
  render time (in `PostItBlock`), not stored.

## Gotchas

- **`palette` is derived from `ThemeSettings.palettes`.** Graphite is
  static; user theme edits rebuild live because `ThemeSettings` persists
  the JSON list and notifies.
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
