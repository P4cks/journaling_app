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
- [app_scaffold_shell.dart](app_scaffold_shell.dart) — `AppScaffoldShell`.
  The shell for `StatefulShellRoute.indexedStack`. Three tabs:
  Profile / Home / Entries. Tapping the active tab pops the branch to
  its root (the `initialLocation: index == navigationShell.currentIndex`
  arg). The bottom-nav theme (`backgroundColor`, selected/unselected
  colors) is set in `buildAppTheme` so each `AppIcon` here just inherits.
  - **Tap handler awaits `NavigationGuard.canLeave()`** before calling
    `goBranch`. `PopScope` only intercepts pops — tab switches in
    `StatefulShellRoute` don't go through it, so a registered guard
    is the only way to prompt for unsaved state on tab switch.
- [navigation_guard.dart](navigation_guard.dart) — `NavigationGuard`.
  Single-slot registry for an async "may I leave?" handler. Screens
  with unsaved state register via `navigationGuard.register(handler)`
  in `didChangeDependencies` and clear with `register(null)` in
  `dispose`. The shell awaits `canLeave()` on each bottom-nav tap.
  - One handler at a time — only one editor screen with dirty state
    is mounted at any moment in this app. Re-registering replaces the
    previous handler (last-write-wins).
  - The handler decides what UI to show (typically a save/discard
    `AlertDialog`) and returns `true` to allow the navigation or
    `false` to block it.

## Gotchas

- **`AppDependencies.of` must run after the widget is mounted** —
  call from `didChangeDependencies`, not `initState`. The
  `InheritedWidget` lookup throws otherwise.
- **Bottom-nav order is hardcoded to match the router branches** —
  index 0 = Profile, 1 = Home, 2 = Entries. Changing the order here
  requires changing the branch order in `appRouter` too, or the
  tabs jump to the wrong screen.
- **Always unregister the navigation guard in `dispose`** (call
  `register(null)`). It's a singleton — leaking a handler from a
  disposed screen will keep blocking tab switches with a context
  that's no longer mounted.

## When to update this file

- A new shared widget is added.
- The DI surface in `AppDependencies` changes.
- The bottom-nav structure changes (item count, ordering, icons).
