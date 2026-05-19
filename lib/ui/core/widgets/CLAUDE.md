# lib/ui/core/widgets — Shared widgets

Cross-screen widgets and helpers used everywhere. See [../CLAUDE.md](../CLAUDE.md)
for how they fit together; this file is per-file notes.

## Files

- [app_dependencies.dart](app_dependencies.dart) — `AppDependencies extends InheritedWidget`.
  DI root. Constructed once in `main.dart`. `static of(context)` is
  guarded by `assert(widget != null)` so a missing ancestor fails
  loudly in dev rather than NPE-ing at first use. `updateShouldNotify`
  compares every dependency reference — bumping a repository (which
  we don't currently do at runtime) would re-trigger dependants.
- [app_icon.dart](app_icon.dart) — `AppIcon`. Phosphor wrapper. Pulls
  `size` and `color` from the surrounding `IconTheme` when unset, and
  defaults `duotoneSecondaryColor` to `colorScheme.primary` (the user's
  accent). The reason `secondaryColor` is exposed as a prop: the streak
  card overrides it to match the primary tone so flame icons read
  monochrome.
- [section_header.dart](section_header.dart) — `SectionHeader`.
  Accent-tinted titleSmall label used by Settings and the entries list.
- [settings_section.dart](settings_section.dart) — `SettingsSection`.
  Canonical grouped-settings wrapper: `label` renders through
  `SectionHeader`, and `children` are padded rows/controls followed by
  a divider. Import this file directly for settings-style groups.
- [settings_nav_tile.dart](settings_nav_tile.dart) — `SettingsNavTile`.
  Icon + title + caret-right `ListTile` that pushes a named `route`
  via `context.push`. Used for navigation rows inside settings
  sections that only route to another screen (e.g. Settings → Manage
  templates / Configure blocks).
- [bottom_sheet_scaffold.dart](bottom_sheet_scaffold.dart) —
  `Future<T?> showDraggableSheet<T>(context, {title, initialChildSize,
  minChildSize, maxChildSize, required slivers})`. Single helper that
  composes `showModalBottomSheet<T>(isScrollControlled: true,
  useSafeArea: true)` with a `DraggableScrollableSheet`, a 36×4
  rounded drag handle, and an optional left-aligned `titleMedium`
  header. The caller's `slivers` builder receives the inner
  `ScrollController` (which the helper wires to the wrapping
  `CustomScrollView`). Used by the three draggable sheets — calendar
  month sheet, layout picker, add-block sheet. Plain menu-style
  bottom sheets intentionally don't go through this helper.
- [streak_stat_card.dart](streak_stat_card.dart) — `StreakStatCard` +
  private nudge widget. Renders a `StreakResult` from
  [services/streak_service.dart](../../../data/services/streak_service.dart).
  Reused by the entries list and by the profile dropdown's header
  (in compact form).

## Gotchas

- **`AppDependencies.of` must run after the widget is mounted** —
  call from `didChangeDependencies`, not `initState`. The
  `InheritedWidget` lookup throws otherwise.
- **No more app-shell.** The bottom navigation is gone; the
  `AppScaffoldShell` and `NavigationGuard` files have been removed.
  Screens push directly to top-level routes from the main screen's
  top-bar buttons / profile dropdown. The layout editor still uses
  `PopScope` for its dirty-state Back-press dialog, which is
  sufficient since no tab switches happen anymore.

## When to update this file

- A new shared widget is added.
- The DI surface in `AppDependencies` changes.
