# lib/data/services — Storage + settings

Thin wrappers around `hive_ce`'s `Box<T>` (one service per box) plus two
`ChangeNotifier` settings classes and one pure function (`computeStreak`).
Repositories compose these; UI never touches a service directly.

## Boxes (current names — bump these on schema changes)

`main.dart` opens three boxes:

| Box                  | Type                  | Wrapped by                  |
|----------------------|-----------------------|-----------------------------|
| `journalEntries_v5`  | `Box<JournalEntry>`   | `HiveStorageService`        |
| `journalLayouts_v4`  | `Box<JournalLayout>`  | `LayoutStorageService`      |
| `settings`           | `Box<String>`         | `SettingsStorageService`    |

The two model boxes are versioned (`_vN` suffix). The settings box is
**not** versioned — its values are plain strings keyed by string, so
schema-change risk is near zero. Bump the model box name when you change
the shape of `JournalEntry` or `JournalLayout` (see root CLAUDE.md).

## Files

- [hive_storage_service.dart](hive_storage_service.dart) — `HiveStorageService`.
  Wraps the entries box. Keys are ISO-8601 strings of local-midnight
  dates (the repository computes them, not the service). Methods:
  `getJournalEntry`, `saveJournalEntry`, `deleteJournalEntry`,
  `getAllJournalEntries`. Trivial and intentionally so — domain
  logic lives in `JournalRepository`.
- [layout_storage_service.dart](layout_storage_service.dart) — `LayoutStorageService`.
  Wraps the layouts box. Keys are the layout's own `id`. Exposes
  `isEmpty` so `LayoutRepository.seedDefaultIfEmpty` can detect first
  launch.
- [settings_storage_service.dart](settings_storage_service.dart) —
  `SettingsStorageService`. Wraps the settings box. Knows the **string
  keys** for every setting (one private `static const _xxxKey`
  per setting). Stores booleans as `"true"`/`"false"` and colors as
  `#RRGGBB` hex (via [ui/theme/color_hex.dart](../../ui/theme/color_hex.dart)).
  Setters that take `null` (e.g. `setThemeSecondary(null)`) `delete`
  the key — distinguishes "user reset to default" from "user picked
  the same value as default".
  - Known keys: `defaultLayoutId`, `debug.menuVisible`,
    `debug.unlockAllDays`, `theme.mode`, `theme.paletteId`,
    `theme.secondary`, `theme.accent`,
    `theme.debugSurface`. If you add another, give it a namespaced key
    and add a typed accessor pair.
- [debug_settings.dart](debug_settings.dart) — `DebugSettings extends ChangeNotifier`.
  Stores debug-facing switches via `SettingsStorageService`:
  - `debugMenuVisible` gates whether the Settings screen renders the
    Debug `ExpansionTile`.
  - `unlockAllDays` bypasses both the calendar's future-day disable
    and the editor's read-only-for-past guard.
- [theme_settings.dart](theme_settings.dart) — `ThemeSettings extends ChangeNotifier`.
  Mirrors a `ColorScheme` configuration:
  - `themeMode` (`ThemeMode`, default `system`)
  - `paletteId` (string id into `kSurfacePalettes`)
  - `secondaryOverride`, `accentOverride`, `debugSurfaceOverride`
    (all nullable; `null` means "use the palette's default")
  - `effectiveSecondary` / `effectiveAccent` getters resolve override →
    palette default. Use these from non-debug UI; the raw `*Override`
    getters are for the Profile screen to show "is overridden".
  - Persists every setter to `SettingsStorageService`. Subscribed to by
    `main.dart`'s root `ListenableBuilder` so a setter call rebuilds
    the entire `MaterialApp.router` with the new theme.
- [streak_service.dart](streak_service.dart) — `computeStreak(entries, {now})`
  pure function + `StreakResult` value class. **Not a service in the
  Hive-wrapper sense** — just lives here for proximity.
  - DST-safe: all date math is `DateTime(y, m, d + delta)` re-normalized,
    never timestamp differences. A US "fall back" day is 25 hours, a
    "spring forward" day is 23, both count as one calendar day.
  - Filters out empty entries via `JournalEntry.hasNoContent` before
    counting.
  - `current` starts from today (or yesterday if today has no entry),
    so the streak doesn't break until the user misses a full day.
  - Pass `now` in tests; defaults to `DateTime.now()`.

## Implementation details

- Storage services are **synchronous reads, async writes** — that
  matches Hive's API. Repositories `await` the write futures; UI
  shouldn't.
- `ChangeNotifier` setters guard against no-op assignment (`if (x == value) return;`)
  to avoid spurious notifications. Keep this when adding new settings.
- `debugPrint` with a `[ClassName]` prefix on every state transition.
  This is intentional — the bottom-of-the-stack log makes drag/drop
  and sweep behavior debuggable from the console.

## Gotchas

- **Don't read or write the settings box directly from UI.** Always go
  through `SettingsStorageService` so the keys stay centralized.
- **`Box<String>.get(key)` returns `null` for missing keys.** The
  service handles this in every getter — don't bypass it.
- **`computeStreak` allocates a `Set<DateTime>` of normalized days.**
  Don't pass un-normalized `DateTime`s and expect dedup — the function
  normalizes internally, but the caller may still get hashing surprises
  if they reuse the same set elsewhere.

## When to update this file

- A new box is added (and added to the table above).
- A new setting key is added to `SettingsStorageService` (add it to
  the "Known keys" list).
- A box name is bumped — update the table.
- `streak_service.dart` changes shape (e.g. tracking longest-by-month,
  weekly streaks) — describe the new semantics here so callers don't
  have to read the function.
