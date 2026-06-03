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
  (`StatelessWidget`) + private appearance/theme and color helpers.
  Pushed via `/settings` from the profile dropdown.
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
  `BlockSettingsScreen` (`StatefulWidget`). Top-level
  `SettingsSection`s:
    1. **Prompt Block** — embeds `PromptBlockSettings(vm)`.
    2. **Carousel Blocks** — a single `SwitchListTile`
       ("Show titles above carousels") bound to
       `vm.carouselTitlesEnabled`, followed by the inlined
       `_CustomCarouselList` (per-definition Edit / Delete rows + an
       "Add custom block" button at the bottom).
    3. **Wanna-dos** (GUS-8) — the inlined `_WannadoList` over the
       **global** wanna-do bucket list. Subscribes to `BlockSettings`
       directly via `ListenableBuilder` (NOT the VM — wanna-do edits
       write through `BlockSettings` immediately, not as drafts). Each
       item is a `ListTile` with Edit / Delete `IconButton`s; an "Add
       wanna-do" `OutlinedButton` sits at the bottom. Add / edit open a
       top-level `_showEditDialog` (an `AlertDialog` with a maxLength-80
       `TextField` returning trimmed text); `_add` mints a
       `WannadoItem(id: _uuid.v4(), text: …)`, `_edit` calls
       `item.copyWith(text: …)`. The list is the same one the wannado
       carousel section renders in entries — edits reflect everywhere
       immediately. The module-level `_uuid = Uuid()` backs new ids.
    4. **Memory Block** — its existing settings.
  Built-in fields live on `BlockSettingsViewModel` as drafts;
  `PopScope` runs `_maybeSaveOnLeave` which mirrors
  `LayoutEditorScreen`'s Cancel / Discard / Save dialog. The save
  dialog surfaces a SnackBar ("Fix the highlighted fields before
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

## SettingsScreen composition

| Block                       | Listens to              | Notes                              |
|-----------------------------|-------------------------|------------------------------------|
| `SettingsSection` "Appearance" | `themeSettings`      | mode selector + palette strip      |
| `ThemeModeSelector`         | `themeSettings`         | system/light/dark segmented        |
| "Theme" + `PalettePicker` | `themeSettings` + `subscriptionRepository` | horizontal Graphite/user-theme strip; Pro-gated (GUS-26) |
| `showThemeEditorSheet`    | —                       | add/edit user themes                |
| `SettingsSection` "Journal templates" | —             | pushes `/layouts`                  |
| `SettingsSection` "Blocks" | —                      | pushes `/block-settings`           |
| `SettingsSection` "Debug" | `debugSettings`         | debug rows render only when enabled |
| `_PostItStyleSection`       | `themeSettings`         | "Playful post-it style" `SwitchListTile` + post-it palette `Wrap` (`_PostItSwatch` + `_AddPostItSwatch`). Greyed out when toggle is off |
| `SwitchListTile` "Show debug menu" | `debugSettings` | persisted; gates debug rendering   |
| `SwitchListTile` "Unlock all days" | `debugSettings`  |                                    |
| `SwitchListTile` "Simulate free account" | `subscriptionRepository` | masks `isPro` → false via `setDebugForceFree`; local-only, doesn't cancel real sub |
| Input-limit caption + 5 `_DebugLimitTile`s | `debugSettings` | tune per-block char/item caps; see below |
| `ListTile` "Override surface color" | `themeSettings` | `showSwatchPicker(allowFreePick: true)` |
| `ListTile` "Free-pick secondary (HSL)" | `themeSettings` |                                |
| `ListTile` "Free-pick accent (HSL)"    | `themeSettings` |                                |
| `ListTile` "Generate sample entries" | —          | debug (GUS-35); non-destructive; `JournalRepository.debugGenerateSampleEntries` then a count SnackBar |
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
- `_generateSampleEntries(context)` — debug (GUS-35); no confirm
  (non-destructive) — calls `JournalRepository.debugGenerateSampleEntries`
  and SnackBars the created count. Lets you populate the statistics
  charts with ~400 days of random mood + text data.

## Debug input-limit controls (GUS-10)

Inside `if (debug.debugMenuVisible) ...[` (above the surface-color
overrides) sits an italic caption — *"Input-limit tuning — these
override the per-block character caps for testing. Once you settle on
good values, hard-code them into `BlockInputLimits` defaults and drop
the debug overrides."* — followed by 5 `_DebugLimitTile`s bound to
`DebugSettings`' nullable-int override getters/setters
(`textBlockCharLimit`, `textSectionCharLimit`, `promptCharLimit`,
`todoItemCharLimit`, `todoMaxItems`). Each tile's `defaultValue` is the
matching `BlockInputLimits` constant (`kTextBlockMaxChars`,
`kTextSectionMaxChars`, `kPromptAnswerMaxChars`, `kTodoItemMaxChars`,
`kTodoMaxItems`). The blocks resolve the effective value via
`BlockInputLimits.of(debugSettings)` (override ?? default) and rebuild
live through `ListenableBuilder(listenable: debugSettings)`, so editing
a value here updates any open block immediately.

- `_DebugLimitTile` (`StatelessWidget`) — `ListTile` showing the
  effective value (trailing) and an "override N / default M" subtitle.
  `_edit` opens an `AlertDialog` with a numeric `TextField` and three
  actions: **Reset to default** pops the sentinel `-1`, **Cancel** pops
  `null`, **Save** pops the parsed int (or `null` when blank/invalid/≤0).
  `onChanged` maps `< 0` → `null` (clear override) so a reset restores
  the default; a positive int sets the override.

## Private widgets

- `_AppearanceSettingsContent` — owns the Appearance section's live
  `ThemeSettings` listener, mode selector, palette strip, and add/edit/delete
  custom-theme callbacks. `SettingsScreen` only decides where the section sits
  in the list. Takes a `SubscriptionRepository` (passed from
  `AppDependencies`) and listens to it alongside `ThemeSettings` via
  `Listenable.merge`, so the palette strip un-greys immediately after a
  purchase. Passes `locked: !isPro` + `onUnlock: () =>
  requirePro(subscriptions, context:)` into `PalettePicker` (GUS-26).
  Theme mode stays free.
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
- A row is moved between sections — the `SettingsSection` grouping should
  still match the composition table above.
