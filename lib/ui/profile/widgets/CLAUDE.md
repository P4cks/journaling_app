# lib/ui/profile/widgets — Profile-area widgets

See [../CLAUDE.md](../CLAUDE.md) for the screen overview.

## Files

- [theme_mode_selector.dart](theme_mode_selector.dart) —
  `ThemeModeSelector`. `SegmentedButton<ThemeMode>` with three options
  (System / Light / Dark), each with a Phosphor duotone icon. Pure
  presentation — driven by `value` and `onChanged`.
- [palette_picker.dart](palette_picker.dart) — `PalettePicker`.
  Horizontal `ListView` of theme tiles plus an Add theme tile at the end.
  Graphite renders as the protected default with no actions. User themes
  show surface + color dots, right-aligned name text, and edit/delete
  icon actions. Calls back for select/add/edit/delete; persistence stays
  in `ThemeSettings`.
- [swatch_grid_picker.dart](swatch_grid_picker.dart) —
  `Future<SwatchResult?> showSwatchPicker(...)` + `SwatchResult` value
  class + private `_SwatchDialog`, `_Swatch`, `_LabelSlider`.
  - **Result sentinel**:
    - `SwatchResult.color(c)` — user applied a color.
    - `SwatchResult.reset()` — user pressed Reset.
    - `null` — user dismissed without applying.
  - Modal dialog: large color preview strip + 12-swatch grid; with
    `allowFreePick: true`, HSL sliders appear underneath.
  - The 12 curated swatches are a private `_kSwatches` list — tuned
    to read well against the dimmed dark surfaces. Don't promote
    them to the public palette list; they're for picker-only use.
  - `_isClose` uses an `< 0.01` per-channel threshold against the
    M3 `Color.r/.g/.b` floats to highlight the currently-selected
    swatch when the user hasn't moved far in HSL space.
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

## Gotchas

- **`PalettePicker` reads `Theme.of(context).brightness` per tile**
  to decide which surface (dark or light) to render. If the user is
  in `ThemeMode.system`, the displayed swatches follow the system
  brightness — picking a palette while the OS is light will preview
  the light surface even if the user runs in dark all evening.
  Acceptable.
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

- The horizontal theme tile actions/layout change.
- A new pickable swatch is added (or the 12-swatch palette is retuned).
- A new picker variant is introduced (e.g. transparency).
- The streak card gains new metrics (e.g. average per week).
- The auth card adds providers, profile fields, or account actions.
