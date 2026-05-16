# lib/data/services — Storage + settings

Thin wrappers around `hive_ce`'s `Box<T>` (one service per box), Firebase Auth
service wrappers, two `ChangeNotifier` settings classes, and one pure function
(`computeStreak`). Repositories compose these; UI never touches a service
directly.

## Boxes (current names — bump these on schema changes)

`main.dart` opens three boxes:

| Box                  | Type                  | Wrapped by                  |
|----------------------|-----------------------|-----------------------------|
| `journalEntries_v6`  | `Box<JournalEntry>`   | `HiveStorageService`        |
| `journalLayouts_v6`  | `Box<JournalLayout>`  | `LayoutStorageService`      |
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
    `theme.secondary`, `theme.accent`, `theme.customPalettes`,
    `theme.debugSurface`, `block.prompt.list` (JSON-encoded list of
    strings), `block.prompt.strategy` (`daily` | `random` | `manual`),
    `block.text.charLimit` (positive int as string). If you add
    another, give it a namespaced key and add a typed accessor pair.
- [debug_settings.dart](debug_settings.dart) — `DebugSettings extends ChangeNotifier`.
  Stores debug-facing switches via `SettingsStorageService`:
  - `debugMenuVisible` gates whether the Settings screen renders the
    Debug `ExpansionTile`.
  - `unlockAllDays` bypasses both the calendar's future-day disable
    and the editor's read-only-for-past guard.
- [photo_storage_service.dart](photo_storage_service.dart) — `PhotoStorageService`.
  Copies `image_picker` results into `<app-docs>/photos/<uuid>.<ext>`
  and exposes:
  - `savePickedFile(XFile)` → `Future<String>` (absolute path).
  - `deleteAtPath(path)` → best-effort delete; swallows
    `FileSystemException` so cleanup paths can call it without guarding.
  Photo bytes are **never stored in Hive** — only the path string is
  persisted via `PhotoBlockContent`.
- [weather_service.dart](weather_service.dart) — `WeatherService`.
  Wraps `geolocator` + Open-Meteo's `/v1/forecast?current_weather=true`
  + OSM Nominatim's `/reverse` endpoint.
  Returns a `WeatherFetchResult` with one of four `WeatherFetchStatus`
  values: `ok`, `permissionDenied`, `locationDisabled`, `networkFailure`,
  plus optional `cityName` (best-effort).
  - Caches per `(date, ~10km location bucket)` in the `settings` Hive
    box under `weather.<yyyy-MM-dd>.<lat_lon>`. Cache payload now
    includes `cityName` so a hit doesn't re-call Nominatim.
  - The static `mapWeatherCode(int)` translates WMO codes onto the
    seven condition ids used by the manual weather block, so the
    icon-mapping helper is shared.
  - `_reverseGeocode(lat, lon)` calls Nominatim with a 6-second
    timeout and the app-identifying `User-Agent` header required by
    the Nominatim usage policy. Failure (rate limit, network, parse)
    returns `null` — the weather fetch still succeeds, just without
    a city name.
  - All `geolocator` calls are injectable for tests; defaults use
    `Geolocator.checkPermission` / `requestPermission` /
    `getCurrentPosition` with `LocationAccuracy.low`.
- [quote_service.dart](quote_service.dart) — `QuoteService`.
  Wraps ZenQuotes `/api/today`. Caches results in the `settings` Hive
  box under the key `quote.<yyyy-MM-dd>` so every entry created on the
  same calendar day sees the same quote. Methods:
  - `readCached(date)` → `DailyQuote?` (synchronous box read).
  - `getTodayQuote({now})` → `Future<DailyQuote?>`. Cache check first,
    then HTTP GET with an 8-second timeout. Returns `null` on any
    failure (HTTP non-200, parse error, network failure) — callers
    render a "couldn't fetch" placeholder.
  - The HTTP client is injectable for tests; defaults to a fresh
    `http.Client`.
- [block_settings.dart](block_settings.dart) — `BlockSettings extends ChangeNotifier`.
  Block-type-global configuration persisted in the `settings` Hive
  box:
  - `prompts` (`List<String>`) — the curated prompt list shown to
    every prompt block.
  - `promptStrategy` (`PromptStrategy` enum: `daily` | `random` |
    `manual`) — how `pickPromptFor` chooses a prompt. `manual` is the
    "user picks per entry" mode: `pickPromptFor` returns `null` and the
    [prompt block widget](../../ui/blocks/prompt_block/CLAUDE.md) opens
    its picker sheet on first build.
  - `textCharLimit` (`int?`) — optional hard cap on every text block.
  - `pickPromptFor({date, slotIndex})` — used by
    `JournalRepository.materializeLayout`. In `daily` mode the pick
    is deterministic from `(daysSinceEpoch + slotIndex) mod N`, so
    multiple prompt blocks on the same day get *different* prompts
    and each prompt rotates through every slot evenly over time.
  - Setters guard against no-op assignment and persist atomically.
- [theme_settings.dart](theme_settings.dart) — `ThemeSettings extends ChangeNotifier`.
  Mirrors a `ColorScheme` configuration:
  - `themeMode` (`ThemeMode`, default `system`)
  - `paletteId` (Graphite or a generated user-theme id)
  - `palettes` (Graphite plus persisted user themes)
  - `secondaryOverride`, `accentOverride`, `debugSurfaceOverride`
    (all nullable; `null` means "use the palette's default")
  - User themes are persisted as a single `theme.customPalettes` JSON
    list. Each item stores `id`, `name`, and `#RRGGBB` `surface`,
    `secondary`, `accent`, and `text` values. Legacy slot-map JSON is
    still decoded.
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
- [auth_service.dart](auth_service.dart) — `AuthService` interface,
  `AuthFailure`, and `DisabledAuthService`. The disabled service is used
  when Firebase options are missing or initialization fails so the app
  can keep running as a local-first journal.
- [firebase_auth_service.dart](firebase_auth_service.dart) —
  `FirebaseAuthService`. The only class that imports `firebase_auth` /
  `google_sign_in`. Maps Firebase `User` → `AppUser`, wraps Firebase
  exceptions in `AuthFailure`, and supports email/password, Google,
  Apple, password reset, and sign-out.

## Implementation details

- Storage services are **synchronous reads, async writes** — that
  matches Hive's API. Repositories `await` the write futures; UI
  shouldn't.
- `ChangeNotifier` setters guard against no-op assignment (`if (x == value) return;`)
  to avoid spurious notifications. Keep this when adding new settings.
- `debugPrint` with a `[ClassName]` prefix on every state transition.
  This is intentional — the bottom-of-the-stack log makes drag/drop
  and sweep behavior debuggable from the console.
- Firebase Auth is **optional**. Missing FlutterFire config should
  disable only the Profile auth buttons, not app startup or local Hive
  journaling.

## Gotchas

- **Don't read or write the settings box directly from UI.** Always go
  through `SettingsStorageService` so the keys stay centralized.
- **`Box<String>.get(key)` returns `null` for missing keys.** The
  service handles this in every getter — don't bypass it.
- **`computeStreak` allocates a `Set<DateTime>` of normalized days.**
  Don't pass un-normalized `DateTime`s and expect dedup — the function
  normalizes internally, but the caller may still get hashing surprises
  if they reuse the same set elsewhere.
- **Don't import Firebase Auth outside `FirebaseAuthService`.** Future
  Firestore/Storage code should hang off `AuthRepository.currentUser.uid`
  rather than coupling widgets or repositories to Firebase SDK state.

## When to update this file

- A new box is added (and added to the table above).
- A new setting key is added to `SettingsStorageService` (add it to
  the "Known keys" list).
- A new auth provider or Firebase-facing auth method is added.
- A box name is bumped — update the table.
- `streak_service.dart` changes shape (e.g. tracking longest-by-month,
  weekly streaks) — describe the new semantics here so callers don't
  have to read the function.
