# lib/ui/profile/view — Settings screens

See [../CLAUDE.md](../CLAUDE.md) for the screen overview. The
standalone profile screen is gone — its functionality is now the
profile dropdown in the main screen's AppBar
([../../journal/widgets/profile_menu_button.dart](../../journal/widgets/profile_menu_button.dart)).

## Files

- [settings_screen.dart](settings_screen.dart) — public `SettingsScreen`
  (`StatelessWidget`) + private color helpers. Pushed via `/settings`
  from the profile dropdown.
- [block_settings_screen.dart](block_settings_screen.dart) — public
  `BlockSettingsScreen` (`StatelessWidget`). Index of configurable
  block types; drills into per-type screens. Pushed via
  `/block-settings`.

## SettingsScreen composition

| Block                       | Listens to              | Notes                              |
|-----------------------------|-------------------------|------------------------------------|
| `ExpansionTile` "Appearance"| —                       | expanded by default                |
| `ThemeModeSelector`         | `themeSettings`         | system/light/dark segmented        |
| "Theme" + `PalettePicker` | `themeSettings` | horizontal Graphite/user-theme strip |
| `showThemeEditorSheet`    | —                       | add/edit user themes                |
| `SwitchListTile` "Show debug menu" | `debugSettings` | persisted; gates debug rendering   |
| `ExpansionTile` "Debug"     | `debugSettings`         | collapsed by default, conditional  |
| `SwitchListTile` "Unlock all days" | `debugSettings`  |                                    |
| `ListTile` "Override surface color" | `themeSettings` | `showSwatchPicker(allowFreePick: true)` |
| `ListTile` "Free-pick secondary (HSL)" | `themeSettings` |                                |
| `ListTile` "Free-pick accent (HSL)"    | `themeSettings` |                                |
| `ListTile` "Delete all entries"  | —             | destructive; confirm dialog; calls `JournalRepository.deleteAllEntries` |
| `ListTile` "Delete all layouts"  | —             | destructive; confirm dialog; calls `LayoutRepository.deleteAllLayouts` (re-seeds default) |

## Top-level helpers (settings_screen.dart)

- `_confirmDestructive(context, {title, message, confirmLabel})` —
  shared confirm dialog with a red `FilledButton`. Returns true on
  confirm. Used by the two "Delete all …" debug actions.
- `_confirmAndDeleteAllEntries(context)` /
  `_confirmAndDeleteAllLayouts(context)` — confirm + call repository
  + show a SnackBar with the deleted count. The layouts variant
  surfaces "default restored" because the repository re-seeds.

## Private widgets

- `_SectionHeader` — accent-tinted titleSmall with letter-spacing.
- `_ExpansionTitle` — same accent-tinted titleSmall styling, used in
  `SettingsScreen` `ExpansionTile.title`.
- `_ThemeEditorSheet` / `showThemeEditorSheet` — half-sheet add/edit UI
  for user themes; edits name, surface tint, secondary, accent, and text
  colour. Returns a `SurfacePalette` for `ThemeSettings` to persist.
- `_ColorTile` — palette-icon leading, label + subtitle ("… · custom"
  appended when overridden), `_ColorChip` trailing.
- `_ColorChip` — 28×28 circle. `outlined: true` adds a thicker
  `scheme.outline` border (used to visually distinguish "no override
  set" from "override is the same color as default").

## Gotchas

- **`SwatchResult` handling**: every callback that consumes a picker
  result follows the same pattern: `null` → do nothing, `isReset` →
  call `setXxx(null)`, otherwise → call `setXxx(result.color)`.
  Preserve this — `isReset` is the only way to distinguish reset from
  cancel.
- **The "Layouts" ListTile is *outside* the Appearance section's
  `ListenableBuilder`** — it doesn't depend on theme state and
  shouldn't rebuild on color changes.
- **Debug is conditionally rendered, not just collapsed.** When
  `debugMenuVisible` is false, the debug controls are absent from the
  tree so casual users do not see the override controls.
- **Deleting the active user theme falls back to Graphite.**
  `ThemeSettings.deleteCustomPalette` owns the fallback and clears any
  secondary/accent overrides.

## When to update this file

- A new section or Profile entry row is added (and update the relevant
  composition table here).
- A row is moved between sections — the section-header dividers are
  hand-placed, so reordering needs a manual re-check.
