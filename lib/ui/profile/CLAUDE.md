# lib/ui/profile — Profile + Settings screens

The first tab. Profile is now a lightweight navigation surface, while
the detailed settings live one push deeper at `/profile/settings`.

Profile contains:

1. **Streak** — current vs longest streaks (or a nudge when current is 0).
2. **Settings** entry point → `/profile/settings`.
3. **Layouts** entry point → `/profile/layouts`.

Settings contains:

1. **Appearance** — expanded by default; theme mode (segmented), surface
   palette grid, secondary/accent color pickers for built-ins, and
   full surface/secondary/accent/text editing for custom slots.
2. **Show debug menu** — persisted discovery switch.
3. **Debug** — rendered only when `debugMenuVisible` is true; collapsed
   by default; `unlockAllDays`, surface override, HSL free-pick for
   secondary/accent.

```
profile/
├── view/        ProfileScreen, SettingsScreen
└── widgets/     palette_picker, swatch_grid_picker, streak_stat_card, theme_mode_selector
```

## Stateless screen + listeners

`ProfileScreen` and `SettingsScreen` are both `StatelessWidget`s. They
pull the settings/repositories they need from `AppDependencies` and
sprinkle `ListenableBuilder`s where each section needs to react:

- The streak card listens to the repository.
- Each appearance / debug color row listens to `themeSettings`.
- The `Show debug menu` and `unlockAllDays` switches listen to
  `debugSettings`.

These are the **only profile-area screens** that use `ListenableBuilder`
directly instead of the standard view-model pattern. Justified because
there's no derived state to compute — everything maps 1:1 to the
underlying settings notifiers.

## Subdirectory CLAUDE.md files

- [view/CLAUDE.md](view/CLAUDE.md) — `ProfileScreen`, `SettingsScreen`,
  and their private section/color helper widgets.
- [widgets/CLAUDE.md](widgets/CLAUDE.md) — `PalettePicker`,
  `ThemeModeSelector`, `showSwatchPicker` (the color dialog),
  `StreakStatCard`.

## Theme override semantics

- **User themes** — Graphite is the protected default. User-created
  themes appear beside it in a horizontal strip, can be edited through
  a half-sheet, and can be deleted. Deleting the active user theme
  falls back to Graphite.
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
- **Debug menu visibility** — `debugSettings.debugMenuVisible` is a
  persisted gate. When false, the debug `ExpansionTile` is not rendered.

## Gotchas

- **Multiple `ListenableBuilder`s on the same notifier** are fine —
  each is local and re-renders only the section it wraps. Don't try
  to consolidate into a single builder at the top; the section
  granularity is intentional.
- **The streak listens to `journalRepository`, not to a
  `StreakViewModel`.** `computeStreak` is pure and fast; calling it
  per build is cheaper than another `ChangeNotifier`.
- **`SwitchListTile.onChanged` is wired straight to
  `debug.setDebugMenuVisible` / `debug.setUnlockAllDays`** — no
  debouncing. Toggling repeatedly is harmless because the setters no-op
  on unchanged values.
- **Settings is a nested Profile route.** Push `Routes.settings` from
  Profile; don't move it to the router root or the bottom nav will
  disappear.

## When to update this file

- A new settings section or profile entry point is added.
- The `ListenableBuilder`-per-section pattern is replaced with a real
  view model (justified if state grows beyond direct passthrough).
- The color-picker `SwatchResult` sentinel grows new variants.
