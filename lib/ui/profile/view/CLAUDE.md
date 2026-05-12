# lib/ui/profile/view — Profile screen widget

See [../CLAUDE.md](../CLAUDE.md) for the screen overview.

## Files

- [profile_screen.dart](profile_screen.dart) — public `ProfileScreen`
  (`StatelessWidget`) + private `_SectionHeader`, `_ColorTile`,
  `_ColorChip`.

## Composition (top to bottom)

| Block                       | Listens to              | Notes                              |
|-----------------------------|-------------------------|------------------------------------|
| _SectionHeader("Streak")    | —                       | accent-colored small caps          |
| `StreakStatCard`            | `journalRepository`     | `computeStreak(getAllEntries())`   |
| Divider                     | —                       |                                    |
| _SectionHeader("Appearance")| —                       |                                    |
| `ThemeModeSelector`         | `themeSettings`         | system/light/dark segmented        |
| "Surface palette" + `PalettePicker` | `themeSettings` | 2-column grid of curated palettes |
| `_ColorTile` "Secondary color" | `themeSettings`      | opens `showSwatchPicker`           |
| `_ColorTile` "Accent color"    | `themeSettings`      | opens `showSwatchPicker`           |
| Divider                     | —                       |                                    |
| `ListTile` "Layouts"        | —                       | navigates to `/profile/layouts`    |
| Divider                     | —                       |                                    |
| _SectionHeader("Debug")     | —                       |                                    |
| `SwitchListTile` "Unlock all days" | `debugSettings`  |                                    |
| `ListTile` "Override surface color" | `themeSettings` | `showSwatchPicker(allowFreePick: true)` |
| `ListTile` "Free-pick secondary (HSL)" | `themeSettings` |                                |
| `ListTile` "Free-pick accent (HSL)"    | `themeSettings` |                                |

## Private widgets

- `_SectionHeader` — accent-tinted titleSmall with letter-spacing.
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

## When to update this file

- A new section is added (and update the composition table here).
- A row is moved between sections — the section-header dividers are
  hand-placed, so reordering needs a manual re-check.
