# lib/ui/journal/widgets — Main-journal-screen widgets

See [../CLAUDE.md](../CLAUDE.md) for the screen overview.

## Files

- [journal_title.dart](journal_title.dart) — `JournalTitle`. Stacks
  [EditorTitle](editor_title.dart) on top of a smaller date subtitle
  via `formatEntryDate`. When no entry exists, falls back to a
  non-editable date-only title.
- [editor_title.dart](editor_title.dart) — `EditorTitle`
  (StatefulWidget) + internal `_InlineTitleField`. Tap-to-edit inline
  title field; commits on submit / blur, cancels via Escape. The
  parent VM normalizes empty/whitespace → null (date fallback).
- [make_entry_cta.dart](make_entry_cta.dart) — `MakeEntryCta`. Centered
  icon + title + subtitle + tonal button. Used when today has no entry.
- [no_entry_read_only.dart](no_entry_read_only.dart) — `NoEntryReadOnly`.
  Centered "No entry was made on this day." message for past days
  with no entry.
- [profile_menu_button.dart](profile_menu_button.dart) —
  `ProfileMenuButton`. `PopupMenuButton` anchored on a userCircle
  icon (filled-check variant when signed in). The button wraps in a
  `ListenableBuilder(listenable: authRepository)` so the icon and
  menu items react to sign-in / sign-out without requiring a manual
  reopen. Items, top-to-bottom:
  1. **Streak header** (always; non-clickable) — current + longest
     streak via `computeStreak`.
  2. **Signed-in header** (only when `currentUser != null`;
     non-clickable) — renders `displayName ?? email ?? 'Signed in'`.
     Replaces the old "Not signed in / Auth disabled" placeholder
     header — those states are now expressed by which action row is
     shown instead.
  3. **Divider**.
  4. **Sign out** (when signed in) — opens a confirm `AlertDialog`
     ("Sign out of <name/email>?") with Cancel / Sign out; on
     confirm calls `authRepository.signOut()`. Or **Sign in** (when
     signed out *and* `isConfigured == true`) — pushes `/profile`.
     When `isConfigured == false` (Firebase init failed →
     `DisabledAuthService`), neither row renders — the dropdown is
     local-journaling-only with no dead end.
  5. **Settings**, **Layouts**, **Block settings** — push the
     corresponding routes.
  Both `onOpened` and `onSelected` call
  `FocusManager.instance.primaryFocus?.unfocus()` so navigating to
  one of the items (which pushes a new route) doesn't leave focus
  parked on a block — and `onSelected` also unfocuses *again* after
  the `await context.push(...)` returns, because Flutter's automatic
  focus restoration would otherwise re-show the keyboard when the
  previously-focused TextField becomes visible again on pop. The
  Statistics action does the same dance in its `onPressed`. The
  Change-layout action only unfocuses on open because it opens a
  sheet (no route push, no auto-restoration risk).
- [calendar_bottom_bar.dart](calendar_bottom_bar.dart) —
  `CalendarBottomBar`. Sticky compact week strip via `TableCalendar`
  in `CalendarFormat.week`, plus a trailing IconButton that opens a
  draggable bottom sheet with the full-month view. Collapses to zero
  height when the keyboard is up (`AnimatedSize` + `viewInsetsOf`).
- [journal_pager.dart](journal_pager.dart) — `JournalPager` plus the
  private `_SectionsBody`. The swipe pager: `PageView.builder` over
  `vm.entries` sorted ascending. Two-way sync with `vm.selectedDate`
  — external changes animate the controller; user swipes call
  `vm.setSelectedDate`. Pass `externalLock: true` to forcibly disable
  the horizontal swipe (used by `MainJournalScreen` while a TextField
  is focused — the screen also collapses the AppBar to a single Done
  action in that state). Each page is a `_SectionsBody` that iterates
  the entry's `sections` and renders them vertically in a single
  outer `SingleChildScrollView`:
    - `SectionKind.text` → `TextSectionWidget` (full-width, no card).
    - `SectionKind.blockGrid` → `BlockGrid(scrollable: false)` with
      the section's blocks.
  Mode is chosen by the screen's `modeFor` callback. Holds a
  `Set<String> _lockedBlockIds` populated by `onInteractionLockChanged`
  forwarded from each `BlockGrid`. When non-empty, the outer
  `PageView` swaps to `NeverScrollableScrollPhysics` so an inner
  mood/weather carousel wins the horizontal drag.

  **`SectionKind.featureBlock`** → renders the section's single block
  inside a full-width `AspectRatio(1, BlockCard(...))` (i.e. 2×2 in
  block-grid terms — same height as a 2-row block-grid section
  filled with one tile). Empty feature sections (no template) render
  nothing.

  **Empty blockGrid sections render nothing** — when a section's
  `blocks` list is empty (e.g. a kind-B layout saved with zero filled
  slots), `_SectionsBody` returns `SizedBox.shrink()` for that
  section so the entry doesn't have awkward padding around an empty
  grid. Text sections are still rendered even when their
  `TextBlockContent` is empty (the user might be about to start
  typing).

## Sentinel: TableCalendar `eventLoader`

The week strip and the month sheet both use the same `_kHasEntry` /
`_kNoEntries` const-list sentinels. `TableCalendar` only cares about
list length when deciding whether to paint a dot, so the element value
is irrelevant — `const Object()` keeps allocation flat. Don't replace
with per-day lists; doing so would walk the entry set per cell.

## Gotchas

- **`PageController.animateToPage` must run after the build.**
  `JournalPager.didUpdateWidget` schedules it in `addPostFrameCallback`
  so it doesn't fire during a `notifyListeners → setState` re-entrant
  build. Don't move it back into the synchronous didUpdateWidget body.
- **`PopupMenuButton` headers must use `enabled: false`** so they
  render but don't dismiss the menu on tap. The streak/auth rows are
  status-only and have no action.
- **`CalendarBottomBar` reads `MediaQuery.viewInsetsOf(context)`** to
  detect keyboard visibility — `viewInsets.bottom > 0` is the
  conventional test. Don't switch to `viewPaddingOf` (that's the
  inverse — system insets like the bottom nav-bar).
- **The week strip and the month sheet each keep their own focused
  day**, so paging within the strip doesn't pollute the sheet's view
  (or vice versa). The shared state is `selectedDate`, not focus.
- **`JournalPager`'s lock-set keys are block IDs**, not a bool flag.
  If two carousels are expanded simultaneously (mood + manual weather
  on the same day), collapsing one keeps the other's lock in place.
  The block widgets release on `_collapse()` and again, defensively,
  in `dispose()` to avoid a stuck `NeverScrollableScrollPhysics`.

## When to update this file

- A new widget is added.
- The PopupMenuButton items change (e.g. an "Export" entry).
- The sync model between calendar and pager changes.
- A new gesture (long-press, double-tap) is wired in.
