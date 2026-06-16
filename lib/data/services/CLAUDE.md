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
    `debug.unlockAllDays`, `theme.paletteId`, `theme.customPalettes`,
    `theme.blockRotation` / `theme.blockOffset` /
    `theme.blockColor` (each `true`/`false`; absent → default `true`;
    the three independent post-it visual toggles split out of the
    former single `theme.postItMode` master in GUS-58),
    `theme.postItPalette` (JSON-encoded
    list of `#RRGGBB` hex strings; absent → ships with the
    `kDefaultPostItPalette` muted pastels), `block.prompt.list`
    (JSON-encoded list of strings), `block.prompt.strategy`
    (`random` | `manual`), `block.carousel.titlesEnabled`
    (`true`/`false`; absent → default `true`),
    `block.customCarousel.definitions` (JSON-encoded list of
    `CustomCarouselDefinition`s; absent means no user-defined
    carousels yet), `block.habit.definitions` (JSON-encoded list of
    `HabitDefinition`s — the user-defined habit "types" (title + icon)
    referenced by `BlockType.habitTracker` blocks; absent means no
    user-defined habits yet; mirrors the custom-carousel storage pair),
    `block.wannado.definitions` (JSON-encoded list of
    `WannadoDefinition`s — the user-created "Wanna-do Carousel" lists
    (title + text items) referenced by `SectionKind.wannado` sections via
    `definitionId`; absent → empty), `block.expandOnEdit` (`true`/`false`; absent →
    default `true`; gates the expanded-block overlay vs in-place
    edit mode), `debug.expandedBlock.showDoneButton` (`true`/`false`;
    absent → default `false`; developer affordance that adds a Done
    button to the expanded block route),
    `subscription.lastKnownPro` (`true`/`false`; absent → `false`;
    persisted snapshot of the **real** `pro` entitlement so an offline
    cold start can still honour an existing subscription — written by
    `SubscriptionRepository` on every customer-info update),
    `subscription.debugForceFree` (`true`/`false`; absent → `false`;
    debug "simulate free account" override),
    `streak.reward.unlockedBlocks` (JSON list of `BlockType.name`s the
    user spent their streak-reward token on; absent → none),
    `streak.reward.unlockedSections` (JSON list of `SectionKind.name`s
    unlocked the same way; absent → none — see
    [streak_reward_settings.dart](streak_reward_settings.dart)).
  - **Removed keys (GUS-27):** `theme.mode`, `theme.secondary`,
    `theme.accent`, `theme.debugSurface` and their accessors are gone —
    brightness is now baked into the selected palette and the debug
    surface/secondary/accent overrides were deleted. Per the pre-1.0
    backwards-compat policy stale values left on disk are harmless and
    simply stop being read; no migration.
    If you add another, give it a namespaced key and add a typed
    accessor pair. Abandoned legacy keys (`block.mood.title`,
    `block.weather.title`, `block.text.charLimit`, the former
    `debug.limit.*` per-block input-limit overrides — all removed when
    the GUS-10 char-cap scaffold was deleted — and `theme.postItMode`,
    the single master post-it toggle split into the three
    `theme.block{Rotation,Offset,Color}` keys in GUS-58) are
    intentionally not read by the service anymore and may still be
    present on existing
    users' disks; per the pre-1.0 backwards-compatibility policy in the
    root `CLAUDE.md` we do not migrate them.
- [debug_settings.dart](debug_settings.dart) — `DebugSettings extends ChangeNotifier`.
  Stores debug-facing switches via `SettingsStorageService`:
  - `debugMenuVisible` gates whether the Settings screen renders the
    Debug `ExpansionTile`.
  - `unlockAllDays` bypasses both the calendar's future-day disable
    and the editor's read-only-for-past guard.
  - `expandBlockOnEdit` (default `true`) — gates the new
    double-tap-to-edit dispatch: ON pushes `ExpandedBlockRoute` over a
    blurred entry; OFF flips the in-place `_editingBlockId` and shows
    the scale + outline affordance on the active tile. Despite the
    "Debug" file location this is a user-facing toggle shown in
    Settings → Blocks.
  - `showExpandedBlockDoneButton` (default `false`) — developer-only
    affordance that overlays a Done button on the expanded route.
    Lives in the Settings → Debug section.
  - The per-block input-limit overrides (GUS-10:
    `textBlockCharLimit`, `textSectionCharLimit`, `promptCharLimit`,
    `todoItemCharLimit`, `todoMaxItems`) have been **removed** along
    with the `BlockInputLimits` scaffold — text blocks/sections are
    now uncapped (only the header keeps a fixed 60-char cap).
- [photo_storage_service.dart](photo_storage_service.dart) — `PhotoStorageService`.
  Copies `image_picker` results into `<app-docs>/photos/<uuid>.<ext>`
  and exposes:
  - `savePickedFile(XFile)` → `Future<String>` (absolute path).
  - `deleteAtPath(path)` → best-effort delete; swallows
    `FileSystemException` so cleanup paths can call it without guarding.
  Photo bytes are **never stored in Hive** — only the path string is
  persisted via `PhotoBlockContent`.
- [video_storage_service.dart](video_storage_service.dart) — `VideoStorageService`.
  Mirror of `PhotoStorageService` for the video block (GUS-16). Copies
  `image_picker` `pickVideo` results into `<app-docs>/video/<uuid>.<ext>`
  (extension whitelist `{.mp4, .mov, .m4v}`, fallback `.mp4`) and exposes
  the same `savePickedFile(XFile) → Future<String>` + best-effort
  `deleteAtPath(path)` pair. Video bytes are **never stored in Hive** —
  only the path string is persisted via `VideoBlockContent`.
- [audio_storage_service.dart](audio_storage_service.dart) — `AudioStorageService` (GUS-12).
  Owns `<app-docs>/audio/`. **Unlike `PhotoStorageService` it does not
  copy bytes** — `package:record` writes the file itself, so this service
  just hands out a fresh destination path and cleans up:
  - `newRecordingPath()` → `Future<String>` — a fresh
    `<app-docs>/audio/<uuid>.m4a` (the `.m4a` ext matches the AAC-LC
    encoder). Lazily ensures the dir (caches the `Directory`).
  - `deleteAtPath(path)` → best-effort delete; swallows
    `FileSystemException` like the photo service.
  Audio bytes are **never stored in Hive** — only the path string (+
  measured `durationMs`) is persisted via `VoiceBlockContent`.
  Constructed in `main.dart`, exposed via `AppDependencies.audioStorage`.
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
  - `promptStrategy` (`PromptStrategy` enum: `random` | `manual`) —
    how `pickPromptFor` chooses a prompt. `manual` is the "user picks
    per entry" mode: `pickPromptFor` returns `null` and the
    [prompt block widget](../../ui/blocks/prompt_block/CLAUDE.md) opens
    its picker sheet on first build.
  - `carouselTitlesEnabled` (`bool`, default `true`) — global show /
    hide for the title row above every carousel block (mood, manual
    weather, custom). When `false`, the three carousel widgets pass
    `null` to `BlockWithTitle` and the row collapses. Predefined
    titles are hardcoded in the widgets (`"How are you feeling?"`
    for mood, `"Today's weather"` for manual weather); custom
    carousels still take their title from
    `CustomCarouselDefinition.title`.
  - `customCarousels` (`List<CustomCarouselDefinition>`) — registry
    of user-defined carousel "types" (title + ordered items, each
    emoji or curated icon). `addCustomCarousel`, `updateCustomCarousel`,
    `deleteCustomCarousel`, and `findCustomCarousel` mutate / look up.
    Caller owns id generation and uniqueness validation. Persisted as
    a JSON list; orphan-tolerant (delete doesn't cascade into layouts
    / entries — the widget renders a "deleted block" placeholder).
  - `habits` (`List<HabitDefinition>`) — registry of user-defined
    habit "types" (title + icon, each icon a `kCarouselIcons` name),
    referenced by `BlockType.habitTracker` blocks via `definitionId`.
    `addHabit`, `updateHabit`, `deleteHabit`, and `findHabit` mutate /
    look up (each mutator notifies + `debugPrint`s). Caller owns id
    generation and uniqueness validation. Persisted as a JSON list
    (`block.habit.definitions`); orphan-tolerant — delete doesn't
    cascade into layouts / entries; the widget renders a "deleted
    block" placeholder. Mirrors the `customCarousels` pattern exactly.
    Free/Pro split is by *combined count* with `customCarousels`
    against `kFreeMaxCustomBlocks`, not a blanket flag.
  - `wannadoDefinitions` (`List<WannadoDefinition>`) — the user's
    "Wanna-do Carousel" definitions (title + ordered text items, GUS-42/
    GUS-45), each referenced by a `SectionKind.wannado` section via
    `definitionId`. `addWannado(def)`, `updateWannado(def)`,
    `deleteWannadoDefinition(id)`, and `findWannadoDefinition(id)` mutate /
    look up (each mutator notifies + `debugPrint`s). **No toggle / done
    state** — items are pure display (text only). Caller owns id
    generation + title uniqueness. Persisted as a JSON list
    (`block.wannado.definitions`); orphan-tolerant — delete doesn't
    cascade into layouts / entries, the section renders an empty
    placeholder. Mirrors the `customCarousels` / `habits` registry
    pattern exactly.
  - `pickPromptFor({date, slotIndex})` — used by
    `JournalRepository.materializeLayout`. In `random` mode the pick
    is deterministic from `(daysSinceEpoch + slotIndex) mod N`, so
    multiple prompt blocks on the same day get *different* prompts
    and each prompt rotates through every slot evenly over time
    ("random" describes the user-perceived rotation, not the
    determinism). In `manual` mode it returns `null` so the widget
    can prompt the user.
  - Setters guard against no-op assignment and persist atomically.
- [theme_settings.dart](theme_settings.dart) — `ThemeSettings extends ChangeNotifier`.
  Mirrors a `ColorScheme` configuration (GUS-27 — **no** `themeMode` and
  **no** surface/secondary/accent overrides anymore):
  - `paletteId` (`'light'`/`'dark'` built-in, or a generated user-theme
    id; default `kLightDefaultPalette.id`)
  - `palettes` (`[...kBuiltInPalettes, ...customPalettes]`)
  - `palette` getter resolves the selected `SurfacePalette` (falls back
    to `kLightDefaultPalette`). Each palette bakes in its own
    `brightness` + single `surface`, so the selection alone drives the
    app's light/dark.
  - `blockRotationEnabled` / `blockOffsetEnabled` / `blockColorEnabled`
    (each `bool`, default `true`) — the three independent post-it
    visual toggles split out of the former single `postItModeEnabled`
    master (GUS-58). Each gates one effect in `BlockChrome`
    (rotation transform / offset translate / palette-color tint).
    When all three are off the grid renders flat cards (the
    pre-post-it look). `BlockChrome` derives `anyPostIt =
    rotation || offset || color` for the radius/curve flourish.
  - `postItPalette` (`List<String>`) — user-managed list of `#RRGGBB`
    hex strings. Random-picked per block at materialization. Defaults
    to `kDefaultPostItPalette` (7 muted pastels) on first launch.
  - User themes are persisted as a single `theme.customPalettes` JSON
    list. Each item stores `id`, `name`, `brightness` (`'light'`/
    `'dark'`), and `#RRGGBB` `surface`, `secondary`, `accent`, and
    `text` values. Decode is tolerant — a missing `brightness` is
    inferred from the surface luminance. `customPaletteTemplate()` mints
    a new dark-brightness template. Post-it palette is **separate** — a
    flat list of single colors, not surface palettes.
  - `setBlockRotationEnabled`, `setBlockOffsetEnabled`,
    `setBlockColorEnabled`, `addPostItColor`, `removePostItColorAt`,
    `setPostItPalette` mutate the post-it state and notify.
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
- [streak_reward_settings.dart](streak_reward_settings.dart) —
  `StreakRewardSettings extends ChangeNotifier` + top-level
  `kStreakRewardMilestone = 7`. Backs the GUS-22 one-time streak reward.
  When the user's **lifetime-best** streak (`StreakResult.longest`)
  reaches 7 they earn **one** reward. **Every claim path unlocks the new
  display-only `BlockType.streakBlock` for everyone (free + Pro)** — the
  "new block everyone gets". On top of that:
  - **Free users** also spend the token on one Pro block **or** Pro
    section to unlock it permanently (the picker).
  - **Pro users** also get `BlockType.quoteBlock` automatically (no
    picker — they own everything; the quote block is downgrade insurance
    if they later drop to free).
  - State is two `Set`s (`_unlockedBlocks`, `_unlockedSections`),
    persisted as the two `streak.reward.*` JSON-list keys above (decoded
    by enum `.name`, tolerating unknown/corrupt → skip).
  - "Claimed" is **derived**: `claimedCount = unlockedBlocks.length +
    unlockedSections.length`; every claim path unlocks ≥1 block (always
    the streak block), so `claimedCount > 0` ⇒ spent. No separate
    `claimed` flag.
  - `isRewardUnclaimed(StreakResult) => streak.longest >= 7 &&
    claimedCount == 0` — the single source of truth for both UI
    surfaces (Statistics reward card + AppBar badge).
  - Three claim methods, each **guarding `if (claimedCount > 0)
    return;`** (one token), then persist + notify:
    - `claimBlock(type)` — free path: unlocks `type` + `streakBlock`.
    - `claimSection(kind)` — free path: unlocks `kind` (section) +
      `streakBlock` (block).
    - `claimAsPro()` — Pro path: unlocks `streakBlock` + `quoteBlock`.
    - `reset()` — debug-only: clears both sets + deletes both keys +
      notifies, so the milestone is claimable again (Settings → Debug →
      "Reset streak reward" / "Reset everything"). No-op when empty.
  - Read by the Statistics reward card + claim sheet, the journal
    AppBar badge, the add-block sheet (hides `streakBlock` until
    unlocked) and the add-block / add-section gating seams (a
    reward-unlocked Pro item bypasses its lock — count caps are
    unaffected). Constructed in `main.dart`, exposed via
    `AppDependencies`.
- [auth_service.dart](auth_service.dart) — `AuthService` interface,
  `AuthFailure`, and `DisabledAuthService`. **This is the only auth
  implementation right now.** `main.dart` always constructs a
  `DisabledAuthService` so the app runs as a local-first journal with
  the Profile auth buttons inert. Firebase (`firebase_core` /
  `firebase_auth`) and `google_sign_in` were removed for now — the old
  `firebase_auth_service.dart` (`FirebaseAuthService`) is gone. Re-add a
  real `AuthService` implementation here when auth is reinstated.
- [subscription_service.dart](subscription_service.dart) —
  `SubscriptionService`. The **only** class that imports
  `purchases_flutter` (RevenueCat). Static `configure()` calls
  `Purchases.configure(...)` exactly once (from `main.dart`, before any
  other Purchases call) with a **build-mode-aware** key (`_apiKey`
  getter): non-release builds (debug/profile) use the Test Store key
  `test_…`; release builds use the platform-specific production key
  (`appl_…` on iOS, `_googleApiKey` on Android). The Android production
  key is **still a placeholder** (currently aliased to the Apple key) —
  RevenueCat rejects an `appl_` key on Android, so a real `goog_…` key
  must be set before the first Play Store release. Instance methods wrap
  `getCustomerInfo`,
  `getOfferings`, `restorePurchases`, add/remove customer-info listener,
  and `logIn`/`logOut` (the last two unused until auth↔subscription
  linking is enabled). Also exports `kProEntitlementId = 'pro'` — the
  single source of truth for the Pro entitlement identifier (change
  here if the dashboard identifier differs). Consumed only by
  [SubscriptionRepository](../repositories/subscription_repository.dart).

## Implementation details

- Storage services are **synchronous reads, async writes** — that
  matches Hive's API. Repositories `await` the write futures; UI
  shouldn't.
- `ChangeNotifier` setters guard against no-op assignment (`if (x == value) return;`)
  to avoid spurious notifications. Keep this when adding new settings.
- `debugPrint` with a `[ClassName]` prefix on every state transition.
  This is intentional — the bottom-of-the-stack log makes drag/drop
  and sweep behavior debuggable from the console.
- Auth is **optional and currently disabled**. The `DisabledAuthService`
  disables only the Profile auth buttons, not app startup or local Hive
  journaling. (Firebase was removed; see `auth_service.dart`.)

## Gotchas

- **Don't read or write the settings box directly from UI.** Always go
  through `SettingsStorageService` so the keys stay centralized.
- **`Box<String>.get(key)` returns `null` for missing keys.** The
  service handles this in every getter — don't bypass it.
- **`computeStreak` allocates a `Set<DateTime>` of normalized days.**
  Don't pass un-normalized `DateTime`s and expect dedup — the function
  normalizes internally, but the caller may still get hashing surprises
  if they reuse the same set elsewhere.
- **Don't couple widgets or repositories to any auth SDK directly.**
  Auth currently runs through `DisabledAuthService` (Firebase removed).
  When auth is reinstated, future code should hang off
  `AuthRepository.currentUser.uid` behind the `AuthService` interface
  rather than importing an SDK directly.

## When to update this file

- A new box is added (and added to the table above).
- A new setting key is added to `SettingsStorageService` (add it to
  the "Known keys" list).
- A new auth provider or Firebase-facing auth method is added.
- A box name is bumped — update the table.
- `streak_service.dart` changes shape (e.g. tracking longest-by-month,
  weekly streaks) — describe the new semantics here so callers don't
  have to read the function.
