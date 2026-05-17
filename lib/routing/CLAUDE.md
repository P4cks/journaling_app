# lib/routing — go_router config

Single-file router + path constants. `AppDependencies` (the DI
`InheritedWidget`) is set up *outside* the router in `main.dart`, so
every screen has access to repositories without per-route plumbing.

## Files

- [app_router.dart](app_router.dart) — `GoRouter appRouter`. Flat
  top-level routes, no `StatefulShellRoute`:
  - `/` → `MainJournalScreen()` (defaults to today)
  - `/journal/:date` → `MainJournalScreen(initialDate: parsed)`
    (deep-link / entries-list tap)
  - `/entries` → `JournalEntriesScreen` (kept for future reuse; no
    AppBar action links to it after the stats rewire — deep-link/URL
    still works)
  - `/statistics` → `StatisticsScreen` (linked from the main screen's
    top-bar Statistics icon)
  - `/settings` → `SettingsScreen`
  - `/profile` → `ProfileScreen` (linked from the profile dropdown's
    "Sign in" row when signed out; the screen itself shows the
    signed-in card when an account exists, so it's safe to deep-link
    in either state)
  - `/layouts` (+ `new`, `edit/:id`) → `LayoutsScreen` / `LayoutEditorScreen`
  - `/block-settings` (+ `text`, `prompt`) → block settings screens

  `initialLocation: Routes.home` so cold start lands on the merged
  main screen.

- [routes.dart](routes.dart) — `Routes` (paths) and `RouteNames` (named
  routes) constants. Use these everywhere; never inline path strings.
  - `Routes.journalEntryFor(DateTime)` builds the `/journal/yyyy-mm-dd`
    path with zero-padded segments. `DateTime.parse` on the other side
    expects exactly this shape.
  - `Routes.editLayoutFor(String id)` builds `/layouts/edit/<id>`.

## Implementation details

- **`rootNavigatorKey`** is exported as a top-level. Currently unused
  by callers but kept around for future dialogs/sheets that need to
  pop above the screen.
- **Path parameter parsing** for `/journal/:date` happens in the route
  builder: `DateTime.parse(state.pathParameters['date']!)`. If
  `Routes.journalEntryFor` is the only place that constructs that
  path, the format is guaranteed compatible.
- **All screens reached from the main screen are `push`ed** (not
  `go`-ed), so the Back button returns to `MainJournalScreen` on the
  same selected date.

## Gotchas

- **`/` and `/journal/:date` map to the same widget** —
  `MainJournalScreen`. The path-parameter form is the deep-link
  entry point; the bare path defaults to today. Both flows go
  through the same VM, so the rest of the app doesn't have to
  branch on which path it came from.
- **No more nested branches.** The old `StatefulShellRoute` is gone
  with the bottom nav. Don't reintroduce nested routes just to keep
  a chrome element pinned; the main screen owns its own AppBar and
  bottom calendar bar directly.

## When to update this file

- A new top-level route is added — add the constant to
  [routes.dart](routes.dart) and a `GoRoute` to
  [app_router.dart](app_router.dart).
- A nested sub-route is added beneath `/layouts` or `/block-settings`.
- The main screen's date model changes (e.g. range selection, week
  view of `:date`).
