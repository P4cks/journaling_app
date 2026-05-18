# lib/ui/profile/view — Profile + Settings screens

See [../CLAUDE.md](../CLAUDE.md) for the screen overview. The profile
dropdown in the main screen's AppBar
([../../journal/widgets/profile_menu_button.dart](../../journal/widgets/profile_menu_button.dart))
pushes these screens.

## Files

- [profile_screen.dart](profile_screen.dart) — public `ProfileScreen`
  (`StatelessWidget`). Scaffold + AppBar('Profile') + body that
  embeds [`ProfileAuthCard`](../widgets/profile_auth_card.dart) inside
  a `ListenableBuilder(listenable: authRepository)`, so the body
  swaps from signed-out (Email / Google / Apple + bottom-sheet email
  flow) to signed-in (avatar + name/email + provider + verification +
  sign-out) the moment auth completes. Pushed via `/profile` from the
  profile dropdown's "Sign in" row.
- [settings_screen.dart](settings_screen.dart) — public `SettingsScreen`
  (`StatelessWidget`) + private color helpers. Pushed via `/settings`
  from the profile dropdown.
- [custom_block_editor_screen.dart](custom_block_editor_screen.dart) —
  public `CustomBlockEditorScreen({String? definitionId})`. Create
  (`null` id) or edit (existing id) a `CustomCarouselDefinition`.
  Same draft + Cancel/Discard/Save-on-leave shape as the layout
  editor and the block-settings screen. Body: title `TextField` +
  `ReorderableListView` of items + "Add emoji" / "Add icon"
  outlined buttons. Pushed via `/custom-block/new` or
  `/custom-block/edit/:id` — no UI entry point yet (lands with the
  Add-Block sheet integration and Block Settings sections in the
  next commits).
  - Private `_ItemRow` — `Card` with leading preview (`Text` for
    emoji / `AppIcon` for icon), label, kind subtitle, X-remove,
    and a `ReorderableDragStartListener` drag handle.
  - Private `_AddEmojiDialog` — single-line `TextField` with a
    cancel / add pair. Length-capped at 16 chars (sanity bound;
    no strict grapheme-cluster validation).
  - Top-level `_showIconPicker` — modal sheet over `kCarouselIcons`,
    layout mirrors [layout_icon_picker.dart](../../layouts/widgets/layout_icon_picker.dart).
- [block_settings_screen.dart](block_settings_screen.dart) — public
  `BlockSettingsScreen` (`StatefulWidget`). Inline sections for every
  block-type-global configuration (Text block char limit, Prompt
  block list + strategy, Mood title, Weather title), followed by one
  section per custom-carousel definition + an "Add custom block"
  button. Built-in fields live on `BlockSettingsViewModel` as drafts;
  `PopScope` runs `_maybeSaveOnLeave` which mirrors
  `LayoutEditorScreen`'s Cancel / Discard / Save dialog. The save
  dialog surfaces a SnackBar ("Fix the highlighted fields before
  saving") and stays on the screen when `vm.canSave` is false.
  Pushed via `/block-settings`.
  - Private `_TitleField` widget renders the optional-title row used
    by both Mood and Weather sections (label + hint + 40-char max
    `TextField` bound to the VM's controller).
  - Private `_CustomCarouselSections` subscribes to `BlockSettings`
    directly via `ListenableBuilder` (NOT through the VM — the
    custom-block editor screen writes through `BlockSettings`
    immediately on save, not as a draft). Each definition gets a
    section with Edit + Delete buttons. Edit pushes
    `/custom-block/edit/<id>`; Delete shows a confirm dialog with
    the usage count across layouts ("Used in N layouts — existing
    entries keep their pick…"). Before pushing the editor route the
    parent's `_maybeSaveOnLeave` runs so a dirty built-in draft
    isn't silently buried under another screen.
  - Private `_CustomDefinitionRow` renders the per-definition body
    (item count + Edit / Delete actions).

## SettingsScreen composition

| Block                       | Listens to              | Notes                              |
|-----------------------------|-------------------------|------------------------------------|
| `ExpansionTile` "Appearance"| —                       | expanded by default                |
| `ThemeModeSelector`         | `themeSettings`         | system/light/dark segmented        |
| "Theme" + `PalettePicker` | `themeSettings` | horizontal Graphite/user-theme strip |
| `showThemeEditorSheet`    | —                       | add/edit user themes                |
| `_PostItStyleSection`       | `themeSettings`         | "Playful post-it style" `SwitchListTile` + post-it palette `Wrap` (`_PostItSwatch` + `_AddPostItSwatch`). Greyed out when toggle is off |
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
