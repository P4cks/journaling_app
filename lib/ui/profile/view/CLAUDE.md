# lib/ui/profile/view — Profile + Settings screens

See [../CLAUDE.md](../CLAUDE.md) for the screen overview. The hamburger
app menu in the main screen's AppBar
([../../journal/widgets/app_menu_button.dart](../../journal/widgets/app_menu_button.dart),
`AppMenuButton`) pushes Settings / Manage Layout / Manage Blocks. The
older `ProfileMenuButton` is retained unused for future user profiles.

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
  (`StatelessWidget`) + the Post-it style section + destructive-action
  helpers. The Appearance section is now a single `SettingsNavTile`
  ("Theme") that pushes `/theme-settings`; the inline theme controls,
  the `_AppearanceSettingsContent` wrapper, the theme-editor sheet, and
  the three debug color-override pickers all moved out / were deleted
  (GUS-27). Pushed via `/settings` from the profile dropdown.
- [theme_settings_screen.dart](theme_settings_screen.dart) — public
  `ThemeSettingsScreen` (`StatelessWidget`, GUS-27). The dedicated
  theming page pushed from Settings → Appearance → "Theme". Body
  (inside `ListenableBuilder(Listenable.merge([themeSettings,
  subscriptionRepository]))`): a **live preview** (`ThemeMockPreview` —
  a mock journal entry wrapped in `Theme(data: buildAppTheme(palette))`:
  date header + text-block card + mood/post-it row, all self-contained,
  no repositories) over the **vertical** `PalettePicker` + Add theme.
  Owns the custom-theme add/edit handlers (`showThemeEditorSheet` →
  `theme.addCustomPalette`/`updateCustomPalette`/`deleteCustomPalette`)
  and the `_ThemeEditorSheet` (name + brightness `SegmentedButton` +
  surface/secondary/accent/text color pickers). Pro-gates custom
  customization via `requirePro`; built-in Light/Dark stay free.
- [custom_block_editor_screen.dart](custom_block_editor_screen.dart) —
  public `CustomBlockEditorScreen({String? definitionId})`. Create
  (`null` id) or edit (existing id) a `CustomCarouselDefinition`.
  Same draft + Cancel/Discard/Save-on-leave shape as the layout
  editor and the block-settings screen. Body: title `TextField` +
  `ReorderableListView` of items + a single "Add item" outlined
  button. Pushed via `/custom-block/new` or `/custom-block/edit/:id`.
  - Private `_ItemRow` — `Card` with leading preview (`Text` for
    emoji / `AppIcon` for icon), label, kind subtitle, X-remove,
    and a `ReorderableDragStartListener` drag handle.
  - `_addItem` — opens the shared
    [showIconEmojiPicker](../../core/widgets/icon_emoji_picker.dart)
    with `allowEmoji: true` over `kCarouselIcons`; an emoji pick
    becomes `CarouselItem.emoji(...)`, an icon pick
    `CarouselItem.icon(...)` (GUS-44). Replaced the former separate
    "Add emoji" (typed into an `_AddEmojiDialog` `TextField`) and
    "Add icon" buttons — both that dialog and the local icon-picker
    sheet are gone.
- [habit_editor_screen.dart](habit_editor_screen.dart) — public
  `HabitEditorScreen({String? definitionId})` (GUS-13). Create (`null`
  id) or edit (existing id) a `HabitDefinition` (title + single icon).
  Same draft + Cancel/Discard/Save-on-leave `PopScope` shape as the
  custom-block editor but simpler: a title `TextField` (maxLength 40,
  `errorText: vm.titleError`) + one icon-picker `InkWell` row (48×48
  preview via `carouselIconFor`; `HugeIcons.strokeRoundedAdd01` when
  unset). Constructs `HabitEditorViewModel` in `didChangeDependencies`.
  Pushed via `/habit-block/new` or `/habit-block/edit/:id` from the
  add-block sheet's Habits tab and the Block Settings "Habit Blocks"
  section. `_pickIcon` opens the shared
  [showIconEmojiPicker](../../core/widgets/icon_emoji_picker.dart)
  (icon-only — `allowEmoji` defaults false) over `kCarouselIcons`,
  passing `selectedIconName: vm.iconName`, and writes back the picked
  `PickerIconResult.name` (GUS-44; the former local `_showIconPicker`
  sheet is gone).
- [wannado_editor_screen.dart](wannado_editor_screen.dart) — public
  `WannadoEditorScreen({String? definitionId})` (GUS-42/GUS-45). Create
  (`null` id) or edit a `WannadoDefinition` (title + ordered text items).
  Same draft + Cancel/Discard/Save-on-leave `PopScope` shape as the
  custom-block editor: a title `TextField` (maxLength 40, `errorText:
  vm.titleError`) + a `ReorderableListView` of text items, each editable
  via a single-field `_WannadoItemDialog` (maxLength 80) and reorderable
  via a drag handle. Items are free text (no icon/emoji). Constructs
  `WannadoEditorViewModel` in `didChangeDependencies`. Pushed via
  `/wannado/new` or `/wannado/edit/:id` from the Block Settings
  "Wanna-do Carousels" section and the layout add-section sub-picker.
- [block_settings_screen.dart](block_settings_screen.dart) — public
  `BlockSettingsScreen` (`StatefulWidget`). Top-level
  `SettingsSection`s:
    1. **Prompt Block** — embeds `PromptBlockSettings(vm)`.
    2. **Carousel Blocks** — a single `SwitchListTile`
       ("Show titles above carousels") bound to
       `vm.carouselTitlesEnabled`, followed by the inlined
       `_CustomCarouselList` (per-definition Edit / Delete rows + an
       "Add custom block" button at the bottom).
    3. **Wanna-do Carousels** (GUS-8/GUS-42/GUS-45, PRO) — the inlined
       `_WannadoCarouselList`, mirroring `_CustomCarouselList` /
       `_HabitList`. Subscribes to `BlockSettings` via `ListenableBuilder`
       (writes go straight through `BlockSettings`, not the VM draft).
       Renders one `_WannadoDefinitionRow` per
       `BlockSettings.wannadoDefinitions` (title + item count + Edit /
       Delete buttons), a `ProLimitHint(max: kFreeMaxWannados, noun:
       'wanna-do carousels')`, and an `AddCustomBlockButton(max:
       kFreeMaxWannados, label: 'Add wanna-do carousel')` at the bottom.
       Edit / Add run the parent's `_maybeSaveOnLeave` then push
       `Routes.newWannado` / `Routes.editWannadoFor(id)` (the dedicated
       `WannadoEditorScreen`); editing a definition reflects in every
       section that references it. Delete confirms with a usage count
       from `LayoutRepository.countWannadoUsage(id)` before calling
       `BlockSettings.deleteWannadoDefinition`.
       - **Free cap (GUS-42/GUS-45).** The wanna-do *section* is fully
         Pro (gated in the layout add-section sheet). On top of that free
         users may define at most `kFreeMaxWannados` (1) carousels — the
         `AddCustomBlockButton` greys + badges and routes through the
         paywall past the cap. (No per-row downgrade locking like the old
         global list — the section gate already covers the Pro story.)
    4. **Memory Block** — its existing settings.
  Built-in fields live on `BlockSettingsViewModel` as drafts;
  `PopScope` runs `_maybeSaveOnLeave` which mirrors
  `LayoutEditorScreen`'s Cancel / Discard / Save dialog. The save
  dialog surfaces a toast ("Fix the highlighted fields before
  saving") and stays on the screen when `vm.canSave` is false
  (currently never — no validation gates). Text blocks have no
  per-type-global settings, and predefined carousel titles (mood,
  manual weather) are hardcoded in their widgets — not editable
  here. Pushed via `/block-settings`.
  - Private `_CustomCarouselList` subscribes to `BlockSettings`
    directly via `ListenableBuilder` (NOT through the VM — the
    custom-block editor screen writes through `BlockSettings`
    immediately on save, not as a draft). It renders a stack of
    `_CustomDefinitionRow`s inside the parent "Carousel Blocks"
    section — no per-definition `SettingsSection` chrome any
    longer. Edit pushes `/custom-block/edit/<id>`; Delete asks
    `LayoutRepository` for the usage count across layouts before
    showing the confirm dialog ("Used in N layouts — existing
    entries keep their pick…"). Before pushing the editor route
    the parent's `_maybeSaveOnLeave` runs so a dirty built-in
    draft isn't silently buried under another screen. The "Add
    custom block" affordance is the shared `AddCustomBlockButton`
    (see [../../core/widgets/CLAUDE.md](../../core/widgets/CLAUDE.md)),
    with a `ProLimitHint` above it — both gate new-block creation at
    `kFreeMaxCustomBlocks` for free users (GUS-40). `_navigateToEditor`
    no longer gates; the button owns the paywall-at-cap.
  - Private `_CustomDefinitionRow` renders the per-definition body
    (title label + item count + Edit / Delete actions).
  - Private `_HabitList` mirrors `_CustomCarouselList` for the Habit
    Blocks section: subscribes to `BlockSettings` directly, renders a
    stack of `_HabitDefinitionRow`s, the shared `AddCustomBlockButton`
    (`label: 'Add habit'`) + `ProLimitHint` gating new habits at the
    **shared** `kFreeMaxCustomBlocks` budget. Edit pushes
    `/habit-block/edit/<id>` after the parent's `_maybeSaveOnLeave`.
  - Private `_HabitDefinitionRow` renders the per-definition body
    (icon + title + Edit / Delete actions).

## SettingsScreen composition

| Block                       | Listens to              | Notes                              |
|-----------------------------|-------------------------|------------------------------------|
| `SettingsSection` "Appearance" | —                  | single `SettingsNavTile` "Theme" → `/theme-settings` (GUS-27) |
| `SettingsSection` "Journal templates" | —             | "Manage Layout" (dashboard-setting icon) → `/layouts` |
| `SettingsSection` "Blocks" | —                      | "Manage Blocks" (block-game icon) → `/block-settings` |
| `SettingsSection` "Beta testing" | `debugSettings` | **BETA-ONLY, always visible (incl. release)** — a single "Unlock all days" `SwitchListTile` bound to `debug.unlockAllDays`. Surfaces the unlock outside the `kDebugMode` gate so beta testers can reach it. Remove this section before 1.0 |
| `SettingsSection` "Debug" | `debugSettings`         | **`kDebugMode`-gated** — the whole section (incl. the "Show debug menu" toggle) is absent from the tree in release builds; inner rows still gated by the `debugMenuVisible` toggle |
| `_VersionFooter`            | —                       | Always-visible footer pinned to the bottom of the list. `FutureBuilder<PackageInfo>` (`package_info_plus`) renders "Version `<version>` (`<buildNumber>`)"; appends a red **DEBUG** badge when `kDebugMode` (dev builds only) |
| `_PostItStyleSection`       | `themeSettings`         | Three toggles — "Block rotation" / "Block offset" / "Block color" `SwitchListTile`s (GUS-58) — + post-it palette `Wrap` (`_PostItSwatch` + `_AddPostItSwatch`). Palette greyed out when the **color** toggle is off |
| `SwitchListTile` "Show debug menu" | `debugSettings` | persisted; gates debug rendering   |
| `SwitchListTile` "Unlock all days" | `debugSettings`  |                                    |
| `SwitchListTile` "Simulate free account" | `subscriptionRepository` | masks `isPro` → false via `setDebugForceFree`; local-only, doesn't cancel real sub |
| `ListTile` "Generate sample entries" | —          | debug (GUS-35); non-destructive; `JournalRepository.debugGenerateSampleEntries` then a count toast |
| `ListTile` "Delete all entries"  | —             | destructive; confirm dialog; calls `JournalRepository.deleteAllEntries` |
| `ListTile` "Delete all layouts"  | —             | destructive; confirm dialog; calls `LayoutRepository.deleteAllLayouts` (re-seeds default) |
| `ListTile` "Reset streak reward" | —             | GUS-22; non-destructive (no confirm); calls `StreakRewardSettings.reset()` so the milestone is claimable again; count toast |
| `ListTile` "Reset everything"    | —             | destructive; confirm dialog; `deleteAllEntries` + `deleteAllLayouts` + `streakRewardSettings.reset()` in one shot |

## Top-level helpers (settings_screen.dart)

- `_confirmDestructive(context, {title, message, confirmLabel})` —
  shared confirm dialog with a red `FilledButton`. Returns true on
  confirm. Used by the two "Delete all …" debug actions.
- `_confirmAndDeleteAllEntries(context)` /
  `_confirmAndDeleteAllLayouts(context)` — confirm + call repository
  + show a toast with the deleted count. The layouts variant
  surfaces "default restored" because the repository re-seeds.
- `_generateSampleEntries(context)` — debug (GUS-35); no confirm
  (non-destructive) — calls `JournalRepository.debugGenerateSampleEntries`
  and toasts the created count. Lets you populate the statistics
  charts with ~400 days of random mood + text data.
- `_resetStreakReward(context)` — debug (GUS-22); no confirm
  (non-destructive to journal content) — calls
  `streakRewardSettings.reset()` so the 7-day milestone is claimable
  again, then toasts. Lets you re-test the claim flow.
- `_confirmAndResetEverything(context)` — debug (GUS-22); destructive,
  confirm-gated — `deleteAllEntries` + `deleteAllLayouts` (re-seeds
  default) + `streakRewardSettings.reset()`, then a combined-count
  toast. The "nuke all test data" button.

## Debug menu visibility (GUS-10 follow-up)

The entire Settings → "Debug" `SettingsSection` is wrapped in a
collection-`if (kDebugMode)` (from `package:flutter/foundation.dart`),
so in release builds it — including the "Show debug menu" toggle — is
absent from the tree and a production user can never reach the
destructive actions or the "simulate free account" override. Inside a
debug build the existing `debugMenuVisible` toggle still gates the
detailed rows. (The three surface/secondary/accent color-override
pickers were removed in GUS-27.)

The former per-block input-limit tuning tiles (`_DebugLimitTile`, the
italic caption, the `BlockInputLimits` scaffold) were **removed** —
text blocks/sections/prompt answers/todo items are now uncapped; only
the header keeps a fixed 60-char cap.

## Private widgets

### settings_screen.dart

- `_VersionFooter` — bottom-of-list app version indicator. Reads
  `PackageInfo.fromPlatform()` via a `FutureBuilder` and shows
  "Version `<version>` (`<buildNumber>`)"; in `kDebugMode` builds it
  appends a small red **DEBUG** badge (errorContainer chip). Depends on
  the `package_info_plus` direct dependency added to `pubspec.yaml`.
- `_PostItStyleSection` / `_PostItSwatch` / `_AddPostItSwatch` — the
  Post-it style section (toggle + post-it palette `Wrap`). Unchanged by
  GUS-27. (The former `_AppearanceSettingsContent`, `_ThemeEditorSheet`,
  `_ThemePreview`, `_ColorTile`, `_ColorChip`, and `_DebugColorPickerTile`
  were removed or moved to `theme_settings_screen.dart`.)

### theme_settings_screen.dart (GUS-27)

- `ThemeMockPreview` — the live preview. Wraps `Theme(data:
  buildAppTheme(palette))` around a self-contained mock journal entry
  (date header + text-block card + mood/post-it row via `_GreekLine` /
  `_MiniBlock`). No repositories — renders the candidate `ThemeData`
  directly so theme edits show immediately.
- `_ThemeEditorSheet` / `showThemeEditorSheet` — half-sheet add/edit UI
  for custom themes; edits name, **brightness** (a `SegmentedButton`),
  surface, secondary, accent, and text colour. Returns a `SurfacePalette`
  for `ThemeSettings` to persist (`copyWith(brightness:, surface:, …)`).
- `_ThemePreview` — small color-swatch preview inside the editor sheet.
- `_ColorTile` / `_ColorChip` — color-row + 28×28 chip used by the
  editor sheet.
- `SectionHeaderPlain` — thin wrapper over the shared `SectionHeader`.

## Gotchas

- **`SwatchResult` handling**: every callback that consumes a picker
  result follows the same pattern: `null` → do nothing, `isReset` →
  call `setXxx(null)`, otherwise → call `setXxx(result.color)`.
  Preserve this — `isReset` is the only way to distinguish reset from
  cancel.
- **Debug is conditionally rendered, not just collapsed.** When
  `debugMenuVisible` is false, the debug controls are absent from the
  tree so casual users do not see the destructive actions.
- **Deleting the active custom theme falls back to the Light default.**
  `ThemeSettings.deleteCustomPalette` owns the fallback
  (`kLightDefaultPalette.id`).

## When to update this file

- A new section or Profile entry row is added (and update the relevant
  composition table here).
- A row is moved between sections — the `SettingsSection` grouping should
  still match the composition table above.
