# lib/ui/core — Cross-screen UI primitives

Widgets and helpers consumed by every screen. Nothing here is
screen-specific.

## Subdirectories

- [widgets/](widgets/) — `AppDependencies` (DI), `AppIcon` (HugeIcons wrapper),
  `SectionHeader`, `SettingsSection`, `StreakStatCard`.
- [format/](format/) — small date formatters (no `intl` dependency).

## widgets/

- [widgets/app_dependencies.dart](widgets/app_dependencies.dart) —
  `AppDependencies extends InheritedWidget`. The DI root. Holds
  `AuthRepository`, `JournalRepository`, `LayoutRepository`,
  `SubscriptionRepository`, `DebugSettings`, `ThemeSettings`,
  `BlockSettings`, `StreakRewardSettings`, `QuoteService`,
  `WeatherService`, and `PhotoStorageService`. Accessed via
  `AppDependencies.of(context)`. The static accessor `assert`s that
  an ancestor exists — failing fast in development is better than
  mysterious nulls.
  - **Read from `didChangeDependencies`, never `initState`.**
    `InheritedWidget` lookup is not safe in `initState`. The screen
    pattern (see [ui/CLAUDE.md](../CLAUDE.md)) guards VM construction
    with `if (_viewModel == null)` so it runs exactly once.
  - **When you add a new repository / settings object**, add it here
    *and* construct it in `main.dart` in the right order.
- [widgets/app_icon.dart](widgets/app_icon.dart) — `AppIcon` +
  `HugeIconData` typedef. Wraps the `hugeicons` package's `HugeIcon`
  widget; inherits `size` and `color` from the surrounding
  `IconTheme` when unset. The free HugeIcons package ships only the
  `strokeRounded` family, so there is no secondary / fill variant —
  express selected / active states via `color`, not by swapping the
  glyph. `HugeIconData` aliases the SVG-JSON shape
  (`List<List<dynamic>>`) that `HugeIcons.strokeRoundedXxx` constants
  expose so call sites type their parameters cleanly. **Never use raw
  `Icons.*`** — analyzer won't catch it but it'll look out of place.
- [widgets/settings_section.dart](widgets/settings_section.dart) —
  canonical `SettingsSection` wrapper for settings-style groups. Use
  its `children` parameter for already-built rows or controls.

## format/

- [format/date_format.dart](format/date_format.dart) — two top-level
  helpers:
  - `formatEntryDate(DateTime)` → `"May 11, 2026"` (short month).
  - `formatMonthHeader(int year, int month)` → `"May 2026"` (long month).
  No `intl` dependency — English-only by design for now. Used by
  `EntryListTile`, `JournalEntriesScreen._MonthHeader`, and
  `EditorTitle`.

## When to update this file

- A new cross-screen widget or helper is added to `core/`.
- The DI surface (`AppDependencies`) grows or shrinks.
- We add `intl` / localization (rewriting `date_format` is the first
  step).
