# Improvements

Refactor observations that are worth preserving, but should stay separate from
small behavior-preserving cleanup commits.

## Open

- Several UI files are large enough to hide responsibilities
  (`layout_editor_screen.dart`, `settings_screen.dart`, `block_grid.dart`,
  `profile_auth_card.dart`). Split them only when touching their feature areas,
  so behavior stays easy to verify commit by commit.
- **Profile vs Settings auth-card duplication.** Both `/profile` and
  `/settings` render `ProfileAuthCard`. `lib/ui/profile/CLAUDE.md` already
  notes this as retirable. Deferred because the call is behavioral
  (drops a UI surface), not cosmetic. Suggested resolution: keep
  `/profile` as the canonical sign-in entry point; drop the embedded
  auth section from `/settings`.
- **Bottom-sheet scaffolds are inconsistent.** `layout_picker_sheet`,
  `add_block_sheet`, `add_section_sheet`, `prompt_picker_sheet`,
  `swatch_grid_picker`, and `showThemeEditorSheet` mix
  `DraggableScrollableSheet` with plain `showModalBottomSheet` and
  vary on drag handle / padding / dismissal. A shared
  `lib/ui/core/widgets/bottom_sheet_scaffold.dart` would standardise
  the chrome. Deferred — six call sites; each needs a separate
  verification pass.
- **`profile_auth_card.dart` is ~502 lines.** The `_EmailAuthSheetState.build()`
  alone is ~125 lines. Splitting `_EmailField`, `_PasswordField`, and
  `_ActionButtons` into private widgets would help readability. Purely
  visual; defer until the auth flow next changes.
- **`calendar_bottom_bar.dart` (~340 LOC) and `add_block_sheet.dart`
  (~331 LOC).** Both are dense but not problematic. Touch only when
  next changing that feature.
- **Class / file renames.** `MainJournalScreen` → `JournalEditorScreen`
  was considered. Deferred: cosmetic improvement, lots of import churn.

## Resolved During Refactor

- `SettingsSection` had two identical implementations. The canonical shared
  widget now lives in `lib/ui/core/widgets/settings_section.dart`, and profile
  settings screens import that copy directly.
- `lib/ui/profile/view/settings_screen.dart` had redundant nested `Column` and
  `ListenableBuilder` layers around the Appearance section. The theme controls
  now live in `_AppearanceSettingsContent`, leaving `SettingsScreen` focused on
  section ordering.
- `lib/ui/profile/view/block_settings_screen.dart` counted custom-carousel
  usage by walking layout sections directly. The query now lives on
  `LayoutRepository.countCustomCarouselUsage`, so the UI only renders the
  repository result in the delete confirmation.
- `settings_screen.dart` shipped with a duplicate `theme_settings.dart`
  import, a `widget:` typo on `SettingsSection` (which broke the
  build), and an unused `_ExpansionTitle` widget. All three swept in
  one analyzer-clean commit.
- `TextBlockWidget` and `TextSectionWidget` duplicated their
  `TextEditingController` lifecycle verbatim. Extracted
  `TextContentControllerMixin` in `lib/ui/blocks/widgets/` so both
  widgets share `initState` / `didUpdateWidget` / `dispose` / `emitText`.
- Two near-identical icon-title-caret `ListTile` rows in Settings
  (Manage templates / Configure blocks) collapsed into a reusable
  `SettingsNavTile` in `lib/ui/core/widgets/`. `settings_screen.dart`
  loses its `go_router` import as a side effect.
- Three near-identical debug color-picker `ListenableBuilder` blocks
  (Override surface, Free-pick secondary HSL, Free-pick accent HSL)
  folded into a private `_DebugColorPickerTile` widget in
  `settings_screen.dart`. Three independent builders preserved.
- Removed the Text block character-limit feature outright. Settings
  no longer surfaces a Text section; `BlockSettings.textCharLimit`
  and the `block.text.charLimit` storage key are gone.
- Replaced the three-option Pick Strategy `SegmentedButton`
  (`daily` / `random` / `manual`) with a `Random Prompts`
  `SwitchListTile` (default ON = auto-rotate, OFF = manual). Enum
  renamed `daily` → `random`; legacy stored values fall through.
- Carousel titles collapsed onto one global "Show titles above
  carousels" toggle in Block Settings → Carousel Blocks. Predefined
  carousels (mood, manual weather) now use hardcoded conversational
  labels (`How are you feeling?` / `Today's weather`) instead of
  user-typed strings. Custom carousels keep their per-definition
  title but obey the same global toggle.
- `LayoutRepository.seedDefaultIfEmpty` and `SwatchResult` gained
  why-they-exist docstrings (first-launch invariant; three-valued
  picker sentinel contract).
