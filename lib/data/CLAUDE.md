# lib/data — Data layer

Everything below the UI: models, persistence services, auth services, and
repositories. **No Flutter widgets live here.** Pure Dart + Firebase SDK
wrappers + `hive_ce` + `package:uuid` + `flutter/foundation.dart` (only for
`ChangeNotifier` / `debugPrint`).

## Layered shape

```
data/
├── model/           plain Dart classes — fields, copyWith, toString
│   └── block_content/  typed wrappers over JournalBlockData.contentJson
├── services/        thin Hive box wrappers + ChangeNotifier settings
└── repositories/    domain operations that compose services
```

Read order if you're new: `model/` → `services/` → `repositories/`.

## Who notifies whom

- `JournalRepository` extends `ChangeNotifier`. It notifies on every
  create / save / delete and on a non-zero sweep. View models subscribe
  to it instead of plumbing manual refresh calls.
- `AuthRepository` extends `ChangeNotifier`. It listens to the auth
  service stream and exposes optional sign-in state to Profile. UI
  should depend on `AppUser.uid` for future cloud/profile features,
  never on `FirebaseAuth.instance` directly.
- `SubscriptionRepository` extends `ChangeNotifier`. It listens to the
  RevenueCat customer-info update listener and exposes a single `isPro`
  flag (the `pro` entitlement). UI should gate features on
  `subscriptionRepository.isPro`, never on `Purchases` / `CustomerInfo`
  directly. The live entitlement is SDK-cached + listener-driven; on top
  of that the repo persists two booleans in the settings box — a
  last-known-Pro **offline failsafe** (so an offline cold start still
  honours an existing subscription) and a debug `forceFree` override
  (Settings → Debug "Simulate free account"). See
  [repositories/CLAUDE.md](repositories/CLAUDE.md).
- `DebugSettings` and `ThemeSettings` are `ChangeNotifier`s — they
  notify on every setter. The root `MaterialApp` and several screens
  rebuild via `ListenableBuilder` against them.
- `BlockSettings` is a `ChangeNotifier` holding block-type-global
  configuration (prompt list + strategy, carousel titles, custom
  carousels, habits, wanna-do carousel definitions, memory eligible
  types). Read by
  `JournalRepository.materializeLayout` at entry creation and edited
  from Profile → Block settings. (Text input is uncapped — the former
  char-limit field was removed.)
- `StreakRewardSettings` is a `ChangeNotifier` holding the GUS-22
  one-time streak-reward state (the unlocked blocks + sections). Every
  claim unlocks the display-only `streakBlock` for everyone; free users
  also pick one Pro block/section, Pro users also get `quoteBlock`. It
  notifies on each `claimBlock` / `claimSection` / `claimAsPro`.
  The Statistics reward card + journal AppBar badge subscribe via
  `ListenableBuilder`; the add-block sheet reads it to reveal the
  streak block once unlocked and to bypass a single Pro item's lock. See
  [services/streak_reward_settings.dart](services/streak_reward_settings.dart).
- `LayoutRepository` is **not** a `ChangeNotifier`. Layout edits are
  rare and happen on the Layouts screen, which refreshes its VM
  manually when a pushed editor pops. If you start needing cross-screen
  reactivity for layouts, change this to ChangeNotifier rather than
  inventing a side-channel.

## Date handling

The repository normalizes everything to local-midnight before keying
storage (`DateTime(y, m, d)`). Callers may pass any `DateTime`; the
time-of-day is discarded. The Hive box key is the ISO-8601 string of
the normalized date.

Streak math (in [services/streak_service.dart](services/streak_service.dart))
uses the same calendar-day arithmetic — never timestamp differences —
so DST transitions don't break a streak.

## Subdirectory CLAUDE.md files

- [model/CLAUDE.md](model/CLAUDE.md) — entry / block / layout / app user data classes
- [model/block_content/CLAUDE.md](model/block_content/CLAUDE.md) — typed wrappers over the JSON content of each block type
- [services/CLAUDE.md](services/CLAUDE.md) — Hive box wrappers + settings ChangeNotifiers + pure streak math
- [repositories/CLAUDE.md](repositories/CLAUDE.md) — AuthRepository + JournalRepository + LayoutRepository + SubscriptionRepository

## When to update this file

- A new top-level concept enters the data layer (e.g. a sync service, a
  cache, a migration runner).
- The "who notifies whom" wiring changes — that contract is what UI
  layers rely on.
