# lib/ui/profile — Profile + Settings + Block-settings screens

The main journal screen's AppBar exposes a profile dropdown
([../journal/widgets/profile_menu_button.dart](../journal/widgets/profile_menu_button.dart))
with a streak header, an auth-state-aware row (Sign in / Sign out),
and navigation rows for Settings, Layouts, Block settings. This
directory hosts the pushed screens:

- **Profile** (`/profile`) — the canonical sign-in entry point.
  Reuses `ProfileAuthCard` for both signed-out (Email / Google / Apple
  + bottom-sheet email flow) and signed-in (avatar + name/email +
  provider + verification + sign-out) states. Reachable from the
  dropdown's "Sign in" row when signed out; deep-linking in the
  signed-in state surfaces the same card's signed-in view.
- **Settings** (`/settings`) — Appearance / Journal templates /
  Blocks / Debug. Still embeds `ProfileAuthCard` as a section for
  parity with the dedicated Profile screen — both surface the same
  signed-in/out widget; if that duplication starts to bite, retire
  the Settings copy and keep `/profile` as the only entry point.
- **Block-settings** (`/block-settings`) — every block type's
  configuration inline on one screen. Edits are kept as drafts in
  `BlockSettingsViewModel`; a Cancel / Discard / Save dialog runs on
  leave, mirroring the layout editor. No more per-type push-into-
  sub-screen routes.

Settings contains:

1. **Appearance** — expanded by default; theme mode (segmented), surface
   palette grid, secondary/accent color pickers for built-ins, and
   full surface/secondary/accent/text editing for custom slots.
2. **Post-it style** — `SwitchListTile` toggling `themeSettings.postItModeEnabled`
   (defaults to on; flipping it off restores the pre-post-it flat-card
   look without rebuilding any data), followed by a `Wrap` of color
   swatches showing `themeSettings.postItPalette` plus a `+` tile that
   opens `showSwatchPicker(allowFreePick: true)` and appends the
   picked color via `addPostItColor`. Each swatch has an `×` cap that
   calls `removePostItColorAt(index)`. The palette manager stays
   visible-but-disabled when the toggle is off so users can curate
   while previewing classic mode.
3. **Journal templates** — `Manage templates` row that pushes `/layouts`.
4. **Blocks** — `Configure blocks` row that pushes `/block-settings`.
5. **Debug** — `Show debug menu` toggle plus, when on, `unlockAllDays`,
   surface override, and HSL free-pick for secondary/accent.

Block-settings is rendered inline by `BlockSettingsScreen` —
sections for Text block (char limit), Prompt block (list + strategy),
Mood tracker (title), Manual weather (title). Edits go into draft
state in `BlockSettingsViewModel`; the screen prompts Cancel /
Discard / Save on leave. Saves write back to
[BlockSettings](../../data/services/block_settings.dart).

```
profile/
├── view/         SettingsScreen, ProfileScreen, BlockSettingsScreen
├── view_model/   BlockSettingsViewModel
└── widgets/      palette_picker, swatch_grid_picker, theme_mode_selector,
                  profile_auth_card, prompt_block_settings, text_block_settings
```

## Screen patterns

`SettingsScreen` and `ProfileScreen` are `StatelessWidget`s. They
pull settings/repositories from `AppDependencies` and sprinkle
`ListenableBuilder`s where each section needs to react:

- The optional auth card listens to `authRepository`.
- Each appearance / debug color row listens to `themeSettings`.
- The `Show debug menu` and `unlockAllDays` switches listen to
  `debugSettings`.

`BlockSettingsScreen` follows the **VM + save-on-leave** pattern
instead, mirroring [`LayoutEditorScreen`](../layouts/view/layout_editor_screen.dart):
- `StatefulWidget`; constructs `BlockSettingsViewModel` in
  `didChangeDependencies`.
- `PopScope(canPop: false, onPopInvokedWithResult: _handlePop)` runs
  `_maybeSaveOnLeave` when the user tries to leave dirty.
- `TextBlockSettings` and `PromptBlockSettings` are now **controlled
  by the VM** — they take a `BlockSettingsViewModel` and bind to its
  controllers. No internal Save buttons, no `ScaffoldMessenger`
  "Saved" toasts (the save dialog is screen-wide now).

## Subdirectory CLAUDE.md files

- [view/CLAUDE.md](view/CLAUDE.md) — `SettingsScreen`, `ProfileScreen`,
  `BlockSettingsScreen`.
- [view_model/CLAUDE.md](view_model/CLAUDE.md) —
  `BlockSettingsViewModel`.
- [widgets/CLAUDE.md](widgets/CLAUDE.md) — `PalettePicker`,
  `ThemeModeSelector`, `showSwatchPicker` (the color dialog),
  `ProfileAuthCard`, `PromptBlockSettings`, `TextBlockSettings`.
  Note: `StreakStatCard` lives in [../core/widgets/](../core/widgets/)
  and is reused by the entries list and the profile dropdown.

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
- **Auth is optional and local-first.** A missing Firebase config shows
  a disabled Profile auth card; it must not block app launch or local
  journaling.
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
