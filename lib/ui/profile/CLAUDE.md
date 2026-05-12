# lib/ui/profile — Profile screen

The first tab. A `ListView` of grouped settings sections:

1. **Streak** — current vs longest streaks (or a nudge when current is 0).
2. **Appearance** — theme mode (segmented), surface palette grid,
   secondary/accent color pickers.
3. **Layouts** entry point → `/profile/layouts`.
4. **Debug** — `unlockAllDays` switch, surface override, HSL free-pick
   for secondary/accent.

```
profile/
├── view/        ProfileScreen — all UI inline (no per-section subwidgets)
└── widgets/     palette_picker, swatch_grid_picker, streak_stat_card, theme_mode_selector
```

## Stateless screen + listeners

`ProfileScreen` is a `StatelessWidget`. It pulls `themeSettings`,
`debugSettings`, and `journalRepository` from `AppDependencies` and
sprinkles `ListenableBuilder`s where each section needs to react:

- The streak card listens to the repository.
- Each appearance / debug ListTile listens to `themeSettings`.
- The `unlockAllDays` switch listens to `debugSettings`.

This is the **one screen** that uses `ListenableBuilder` directly
instead of the standard view-model pattern. Justified because there's
no derived state to compute — everything maps 1:1 to the underlying
settings notifiers.

## Subdirectory CLAUDE.md files

- [view/CLAUDE.md](view/CLAUDE.md) — `ProfileScreen` + the private
  `_SectionHeader`, `_ColorTile`, `_ColorChip` widgets.
- [widgets/CLAUDE.md](widgets/CLAUDE.md) — `PalettePicker`,
  `ThemeModeSelector`, `showSwatchPicker` (the color dialog),
  `StreakStatCard`.

## Theme override semantics

- **Secondary / accent** — `setSecondaryOverride(null)` and
  `setAccentOverride(null)` clear the override so the palette's
  default takes effect. Color pickers return a `SwatchResult` sentinel
  that distinguishes "picked a color" (`SwatchResult.color(c)`),
  "reset to default" (`SwatchResult.reset()`), and "dismissed" (`null`).
- **Debug surface override** — `setDebugSurfaceOverride(null)`
  restores the palette surface.
- **Debug free-pick HSL** — runs the same `showSwatchPicker` with
  `allowFreePick: true`, surfacing Hue / Saturation / Lightness
  sliders alongside the curated swatches.

## Gotchas

- **Multiple `ListenableBuilder`s on the same notifier** are fine —
  each is local and re-renders only the section it wraps. Don't try
  to consolidate into a single builder at the top; the section
  granularity is intentional.
- **The streak listens to `journalRepository`, not to a
  `StreakViewModel`.** `computeStreak` is pure and fast; calling it
  per build is cheaper than another `ChangeNotifier`.
- **`SwitchListTile.onChanged` is wired straight to
  `debug.setUnlockAllDays`** — no debouncing. Toggling repeatedly
  is harmless because the setter no-ops on unchanged values.

## When to update this file

- A new settings section is added.
- The `ListenableBuilder`-per-section pattern is replaced with a real
  view model (justified if state grows beyond direct passthrough).
- The color-picker `SwatchResult` sentinel grows new variants.
