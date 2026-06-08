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
- **Settings** (`/settings`) — Appearance / Post-it style / Journal
  templates / Blocks / Debug. **No auth UI** — `/profile` is the
  canonical sign-in surface; `/settings` is appearance and
  configuration only. The profile dropdown's "Sign in" row pushes
  `/profile` directly.
- **Theme** (`/theme-settings`) — dedicated theming page (GUS-27),
  pushed from Settings → Appearance → "Theme" nav tile. A live
  mock-journal-entry preview (`ThemeMockPreview`) at the top + a
  vertical `PalettePicker` + the custom-theme editor sheet
  (`showThemeEditorSheet`). See
  [view/theme_settings_screen.dart](view/theme_settings_screen.dart).
- **Block-settings** (`/block-settings`) — block-type-global
  configuration inline on one screen. Sections: **Prompt Block**
  (the prompt list + the Random Prompts toggle), **Carousel
  Blocks** (a single global "Show titles above carousels" switch +
  the custom-carousel definition list with Edit / Delete / Add),
  **Wanna-dos** (the global wanna-do bucket-list editor — add / edit /
  delete items the wannado carousel section renders across all entries;
  GUS-8), and **Memory Block**.
  Built-in field edits are kept as drafts in `BlockSettingsViewModel`;
  a Cancel /
  Discard / Save dialog runs on leave, mirroring the layout editor.
  No more per-type push-into-sub-screen routes. **No text-block
  config**, **no per-type mood / weather title fields** — text and
  predefined carousel titles are not user-editable; the carousel
  toggle is the only knob.

Settings contains:

1. **Appearance** — a single `SettingsNavTile` ("Theme", paint-brush
   icon) that pushes `/theme-settings` (GUS-27). All the theme controls
   (mode/brightness is now baked into the Light/Dark default themes —
   there is no System/Light/Dark selector anymore; vertical palette
   picker; custom-theme editor; Apple-style color picker) live on that
   dedicated page. **Theming customization is Pro-gated (GUS-26):** the
   built-in Light/Dark defaults stay free and selectable; only custom
   tiles + the Add-theme tile present the paywall.
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
5. **Subscription** — a `SettingsNavTile` (crown icon) that pushes
   `/subscription`. Wrapped in a `ListenableBuilder` on
   `subscriptionRepository` so the title flips between "Upgrade to Pro"
   (free) and "Manage subscription" (Pro). See
   [../subscription/CLAUDE.md](../subscription/CLAUDE.md).
6. **Beta testing** — **BETA-ONLY, always visible (including release
   builds)**: a single "Unlock all days" `SwitchListTile` bound to
   `debug.unlockAllDays`. It deliberately surfaces the unlock outside
   the `kDebugMode`-gated Debug section so beta testers can reach it.
   **Remove this whole section before the 1.0 launch.**
7. **Debug** — the whole section is **`kDebugMode`-gated** (absent in
   release builds). In a debug build: `Show debug menu` toggle plus,
   when on, `unlockAllDays`, `Simulate free account` (a `SwitchListTile`
   bound to `subscriptionRepository.debugForceFree` / `setDebugForceFree`;
   masks `isPro` to false locally to test the free experience — it does
   NOT cancel or touch the real RevenueCat subscription, which has no
   client cancel API), **Generate sample entries** (GUS-35 — a
   non-destructive action that fills ~400 past days with random mood +
   text entries so the statistics charts have data to render), surface
   override, HSL free-pick for secondary/accent, **Reset streak reward**
   (GUS-22 — non-destructive; calls `StreakRewardSettings.reset()` so the
   7-day milestone is claimable again for testing) and **Reset everything**
   (destructive, confirm-gated — wipes all entries + layouts and resets the
   streak reward in one shot). (The former GUS-10 per-block input-limit
   tuning tiles were removed when the char-cap scaffold was deleted.)

Block-settings is rendered inline by `BlockSettingsScreen` —
sections: **Prompt Block** (the prompt list + the Random Prompts
toggle), **Carousel Blocks** (the "Show titles above carousels"
switch + the custom-carousel definition list), **Wanna-dos** (the
global wanna-do bucket-list editor; GUS-8), and **Memory Block**. The
Wanna-dos list writes through `BlockSettings` immediately (not a
draft). Text blocks have no
per-type-global settings here — text input is uncapped (the GUS-10
char-cap scaffold was removed; only the header keeps a fixed 60-char
cap), so there is no char-limit field. Edits go into
draft state in `BlockSettingsViewModel`; the screen prompts Cancel /
Discard / Save on leave. Saves write back to
[BlockSettings](../../data/services/block_settings.dart).

```
profile/
├── view/         SettingsScreen, ProfileScreen, ThemeSettingsScreen,
│                 BlockSettingsScreen
├── view_model/   BlockSettingsViewModel
└── widgets/      palette_picker, swatch_grid_picker,
                  profile_auth_card, prompt_block_settings
```

## Screen patterns

`SettingsScreen` and `ProfileScreen` are `StatelessWidget`s. They
pull settings/repositories from `AppDependencies` and sprinkle
`ListenableBuilder`s where each section needs to react:

- The optional auth card listens to `authRepository`.
- The Post-it style section listens to `themeSettings`.
- The `Show debug menu` and `unlockAllDays` switches listen to
  `debugSettings`.

`ThemeSettingsScreen` (`/theme-settings`) is also a `StatelessWidget`;
it listens to `Listenable.merge([themeSettings, subscriptionRepository])`
so the live preview + vertical `PalettePicker` restyle on theme select
and un-grey on purchase.

`BlockSettingsScreen` follows the **VM + save-on-leave** pattern
instead, mirroring [`LayoutEditorScreen`](../layouts/view/layout_editor_screen.dart):
- `StatefulWidget`; constructs `BlockSettingsViewModel` in
  `didChangeDependencies`.
- `PopScope(canPop: false, onPopInvokedWithResult: _handlePop)` runs
  `_maybeSaveOnLeave` when the user tries to leave dirty.
- `PromptBlockSettings` is **controlled by the VM** — it takes a
  `BlockSettingsViewModel` and binds to its controllers. No internal
  Save button, no `ScaffoldMessenger` "Saved" toast (the save dialog
  is screen-wide now).

## Subdirectory CLAUDE.md files

- [view/CLAUDE.md](view/CLAUDE.md) — `SettingsScreen`, `ProfileScreen`,
  `BlockSettingsScreen`.
- [view_model/CLAUDE.md](view_model/CLAUDE.md) —
  `BlockSettingsViewModel`.
- [widgets/CLAUDE.md](widgets/CLAUDE.md) — `PalettePicker`,
  `showSwatchPicker` (the color dialog), `ProfileAuthCard`,
  `PromptBlockSettings`. Note: `StreakStatCard` lives in
  [../core/widgets/](../core/widgets/) and is reused by the entries list
  and the profile dropdown.

## Theme semantics (GUS-27)

- **Themes** — two built-in defaults (Light / Dark) plus user-created
  custom themes, shown in a **vertical** list on the dedicated
  `/theme-settings` page. Each theme bakes in its own brightness, so
  selecting Light vs Dark flips the whole app — there is no
  System/Light/Dark mode selector. Custom themes are edited through the
  `showThemeEditorSheet` half-sheet (name + brightness toggle + surface
  / secondary / accent / text colors) and can be deleted; deleting the
  active custom theme falls back to the Light default.
- **Color picker** — `showSwatchPicker` returns a `SwatchResult`
  sentinel that distinguishes "picked a color" (`SwatchResult.color(c)`),
  "reset to default" (`SwatchResult.reset()`), and "dismissed" (`null`).
  With `allowFreePick: true` an Apple-style Advanced expander reveals a
  color wheel; the old debug surface/secondary/accent override pickers
  and HSL sliders were removed.
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
