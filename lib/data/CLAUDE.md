# lib/data — Data layer

Everything below the UI: models, persistence services, and repositories.
**No Flutter widgets live here.** Pure Dart + `hive_ce` + `package:uuid`
+ `flutter/foundation.dart` (only for `ChangeNotifier` / `debugPrint`).

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
- `DebugSettings` and `ThemeSettings` are `ChangeNotifier`s — they
  notify on every setter. The root `MaterialApp` and several screens
  rebuild via `ListenableBuilder` against them.
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

- [model/CLAUDE.md](model/CLAUDE.md) — entry / block / layout data classes
- [model/block_content/CLAUDE.md](model/block_content/CLAUDE.md) — typed wrappers over the JSON content of each block type
- [services/CLAUDE.md](services/CLAUDE.md) — Hive box wrappers + settings ChangeNotifiers + pure streak math
- [repositories/CLAUDE.md](repositories/CLAUDE.md) — JournalRepository + LayoutRepository

## When to update this file

- A new top-level concept enters the data layer (e.g. a sync service, a
  cache, a migration runner).
- The "who notifies whom" wiring changes — that contract is what UI
  layers rely on.
