# lib/ui/profile/widgets — Profile-area widgets

See [../CLAUDE.md](../CLAUDE.md) for the screen overview.

## Files

- [palette_picker.dart](palette_picker.dart) — `PalettePicker`.
  **Vertical**, non-scrolling `Column` of full-width theme tiles plus an
  Add-theme tile at the bottom (GUS-27) — it renders inside the Theme
  settings page's own scroll view. The two built-in Light/Dark defaults
  render without edit/delete actions; custom themes show surface + color
  dots, name text, a selected check, and edit/delete icon actions. Calls
  back for select/add/edit/delete; persistence stays in `ThemeSettings`.
  - **Pro gating (GUS-26 + GUS-27 fix).** A `locked` flag + an async
    `Future<bool> Function()? onUnlock` callback. The built-in Light/Dark
    defaults stay **free and selectable** even when `locked` so free
    users can still switch base brightness; only **custom** tiles (when
    not the active one) and the Add-theme tile gate
    (`tileLocked = locked && palette.isCustom && !selected`), greying out
    with a `ProLockBadge`. A shared `_guard` helper runs the gated action
    only after `onUnlock()` (wired to `requirePro(subscriptions)`)
    resolves `true`.
- [swatch_grid_picker.dart](swatch_grid_picker.dart) —
  `Future<SwatchResult?> showSwatchPicker(...)` + `SwatchResult` value
  class + private `_SwatchDialog`, `_Swatch`. Apple-style picker
  (GUS-27), built on the `flutter_colorpicker` package.
  - **Result sentinel**:
    - `SwatchResult.color(c)` — user applied a color.
    - `SwatchResult.reset()` — user pressed Reset.
    - `null` — user dismissed without applying.
  - Modal dialog (in a `SingleChildScrollView`): large color preview bar
    + the 12 standard `_kSwatches`, then a **"Shades"** row — ~7
    lightness variants (`_kShadeLightness`) of the currently-picked hue
    generated via `HSLColor` (saturation floored to 0.45 so near-greys
    still spread). With `allowFreePick: true`, an **"Advanced"**
    `ExpansionTile` reveals a `HueRingPicker` color wheel
    (`enableAlpha: false`). This replaced the always-on HSL sliders.
  - The 12 curated swatches are a private `_kSwatches` list — tuned
    to read well against the dimmed dark surfaces. Don't promote
    them to the public palette list; they're for picker-only use.
  - `_isClose` uses an `< 0.01` per-channel threshold against the
    M3 `Color.r/.g/.b` floats to highlight the currently-selected
    swatch.
- [streak_stat_card.dart](streak_stat_card.dart) — `StreakStatCard` +
  private `_StatsRow`, `_StatColumn`, `_NudgeRow`.
  - Renders a `StreakResult` (from
    [data/services/streak_service.dart](../../../data/services/streak_service.dart)).
  - When `current > 0`: shows Current / Best side-by-side with a
    flame icon and a divider between them.
  - When `current == 0`: shows a nudge ("Make an entry today …"),
    optionally mentioning the longest streak if there is one.
- [profile_auth_card.dart](profile_auth_card.dart) — `ProfileAuthCard`
  plus the email auth bottom sheet. Signed-out state offers Email,
  Google, and Apple buttons when Firebase is configured; otherwise it
  shows the disabled configuration message. Signed-in state shows the
  user's name/email, provider label, optional email verification hint,
  and sign-out.
- [prompt_block_settings.dart](prompt_block_settings.dart) — section
  widget for `BlockSettingsScreen`. **Controlled by**
  `BlockSettingsViewModel` (passed in via the `vm` ctor param): binds
  `vm.promptsController` + reads/writes `vm.promptStrategy` via the
  manual-mode toggle. Does not own its own controller, has no internal
  Save button, and shows no "Saved" toast — the screen-level Cancel /
  Discard / Save dialog handles persistence.

## Gotchas

- **`PalettePicker` tiles render `palette.surface` directly** — each
  palette bakes in its own brightness (GUS-27), so a tile shows its own
  light/dark surface regardless of the active theme.
- **`showSwatchPicker` returns `null` on dismiss**, but `Reset` and
  `Apply` both pop with a non-null result. **Cancel** also pops with
  `null`. Callers must distinguish all three cases — see the
  Settings screen for the canonical pattern.
- **`StreakStatCard` is pure**; passing a fresh `StreakResult` on
  every build is fine because the function is cheap.
- **`ProfileAuthCard` talks only to `AuthRepository`.** Keep Firebase
  SDK imports out of widgets so later Firestore/Storage profile work
  can attach behind the same `AppUser.uid` boundary.

## When to update this file

- The vertical theme tile actions/layout change.
- A new pickable swatch is added (or the 12-swatch palette is retuned),
  or the shades-row / Advanced wheel behaviour changes.
- A new picker variant is introduced (e.g. transparency).
- The streak card gains new metrics (e.g. average per week).
- The auth card adds providers, profile fields, or account actions.
