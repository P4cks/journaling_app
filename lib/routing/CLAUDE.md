# lib/routing — go_router config

Single-file router + path constants. `AppDependencies` (the DI
`InheritedWidget`) is set up *outside* the router in `main.dart`, so
every screen has access to repositories without per-route plumbing.

## Files

- [app_router.dart](app_router.dart) — `GoRouter appRouter`. One
  `StatefulShellRoute.indexedStack` with three branches:
  - Branch 0: `/profile` (and nested `/profile/settings`,
    `/profile/layouts`, `/profile/layouts/new`,
    `/profile/layouts/edit/:id`).
  - Branch 1: `/` (Home) (and nested `/journal/:date`).
  - Branch 2: `/journal-entries` (the sectioned list).

  Sub-routes (the journal editor, the layouts CRUD screens) **live
  inside the relevant branch**, not at the root, so the bottom nav
  stays visible while navigating them. Don't move them up — root
  CLAUDE.md gotcha territory.

  `initialLocation: Routes.home` so cold start lands on Home (Branch 1).

- [routes.dart](routes.dart) — `Routes` (paths) and `RouteNames` (named
  routes) constants. Use these everywhere; never inline path strings.
  - `Routes.journalEntryFor(DateTime)` builds the `/journal/yyyy-mm-dd`
    path with zero-padded segments. `DateTime.parse` on the other side
    expects exactly this shape.
  - `Routes.editLayoutFor(String id)` builds `/profile/layouts/edit/<id>`.
  - `Routes.settings` is the absolute path used by the Profile row;
    the router child path remains relative (`path: 'settings'`).

## Implementation details

- **`rootNavigatorKey`** is exported as a top-level. Currently unused
  by callers but kept around for future dialogs/sheets that need to
  pop above the shell.
- **Path parameter parsing** for the journal-entry screen happens in
  the route builder: `DateTime.parse(state.pathParameters['date']!)`.
  If `Routes.journalEntryFor` is the only place that constructs that
  path, the format is guaranteed compatible. Don't introduce alternative
  date-path constructors that disagree on padding or separator.
- **Editor screens are `push`ed, not `go`-ed**, so the back-stack within
  a branch is preserved. See `HomeScreen._openEditor` and
  `JournalEntriesScreen` (uses `context.push`).

## Gotchas

- **`StatefulShellRoute.indexedStack` keeps each branch's nav stack
  alive across tab switches.** If you push the editor on Home, switch
  to Profile, then come back, the editor is still on the Home stack.
  This is intentional UX.
- **The `path: 'layouts'` vs `path: '/profile/layouts'` distinction**:
  go_router treats a leading-slash path as absolute and a non-leading
  one as nested. The current config uses relative paths for sub-routes
  so they nest correctly under their parent — don't accidentally prefix
  a sub-route with `/`.

## When to update this file

- A new top-level route or branch is added.
- A new path is introduced — add the constant to [routes.dart](routes.dart)
  and update both the tree-of-branches list above and the cross-referenced
  screen CLAUDE.md.
- The shell behavior changes (e.g. tabs swapped for a drawer).
