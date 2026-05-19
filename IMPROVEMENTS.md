# Improvements

Refactor observations that are worth preserving, but should stay separate from
small behavior-preserving cleanup commits.

## Open

- Several UI files are large enough to hide responsibilities
  (`layout_editor_screen.dart`, `settings_screen.dart`, `block_grid.dart`,
  `profile_auth_card.dart`). Split them only when touching their feature areas,
  so behavior stays easy to verify commit by commit.
- **Plain menu-style bottom sheets (9 call sites).** The three
  draggable sheets now share `showDraggableSheet`. The remaining
  plain sheets are a different visual contract (small list, no drag
  handle, mostly no title): prompt picker
  (`lib/ui/blocks/prompt_block/prompt_picker_sheet.dart`), photo
  source + manage-photo (`lib/ui/blocks/photo_block/`), custom-block
  icon picker (`lib/ui/profile/view/custom_block_editor_screen.dart`),
  layout icon picker, layout kind picker, add-section sheet, theme
  editor (`showThemeEditorSheet` in `settings_screen.dart`), profile
  auth email sheet. A `showMenuSheet` companion to
  `showDraggableSheet` could standardise these — defer until the
  next time one of them is touched. `showSwatchPicker` is a
  `showDialog`, not a bottom sheet — out of scope.
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
- `ProfileAuthCard` was already retired from `/settings`; the
  remaining false claim in `lib/ui/profile/CLAUDE.md` was fixed.
  `/profile` is the canonical sign-in surface.
- The three carousel widgets (mood, manual weather, custom carousel)
  collapsed onto a shared `CarouselBlockScaffold<T>` in
  `lib/ui/blocks/widgets/`. Each block now supplies its options
  list, glyph renderer, and content encoder; the scaffold owns the
  `BlockWithTitle` wrap, the read-only em-dash placeholder, and the
  `AnimatedScale + AnimatedOpacity` focus animation around
  `CollapsibleCarouselBlock<T>`. Custom-carousel orphan handling
  stays local.
- The three `DraggableScrollableSheet` call sites
  (`calendar_bottom_bar`, `layout_picker_sheet`, `add_block_sheet`)
  collapsed onto `showDraggableSheet<T>` in
  `lib/ui/core/widgets/bottom_sheet_scaffold.dart`. The shared
  scaffold owns the drag handle, the optional title row, and the
  `DraggableScrollableSheet` chrome.
