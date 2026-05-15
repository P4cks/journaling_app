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
  icon. Header (non-clickable items): compact streak summary + auth
  status row. Below a divider: Settings, Layouts, Block settings.
  Replaces the former Profile tab.
- [calendar_bottom_bar.dart](calendar_bottom_bar.dart) —
  `CalendarBottomBar`. Sticky compact week strip via `TableCalendar`
  in `CalendarFormat.week`, plus a trailing IconButton that opens a
  draggable bottom sheet with the full-month view. Collapses to zero
  height when the keyboard is up (`AnimatedSize` + `viewInsetsOf`).
- [journal_pager.dart](journal_pager.dart) — `JournalPager`. The
  swipe pager: `PageView.builder` over `vm.entries` sorted ascending.
  Two-way sync with `vm.selectedDate` — external changes animate the
  controller; user swipes call `vm.setSelectedDate`. Each page is the
  existing `BlockGrid` in mode chosen by the screen's `modeFor` callback.
  Holds a `Set<String> _lockedBlockIds` populated by
  `onInteractionLockChanged` from `BlockGrid`. When non-empty, the
  outer `PageView` swaps to `NeverScrollableScrollPhysics` so an
  inner mood/weather carousel wins the horizontal drag.

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
