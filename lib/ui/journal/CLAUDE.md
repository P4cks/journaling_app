# lib/ui/journal — Main journal screen (merged home + editor)

The single landing screen of the app. Merges what used to be the
Home screen and the fullscreen entry editor: a day's journal entry
opens directly with the editable title in the AppBar, the blocks
below as the editable body, a swipe pager between adjacent existing
entries, and a sticky bottom calendar for jumping to any day.

```
journal/
├── view/         MainJournalScreen — AppBar + pager/empty-state + bottom calendar
├── view_model/   MainJournalViewModel — selected date, entries list, mutations
└── widgets/      JournalTitle, EditorTitle, MakeEntryCta, NoEntryReadOnly,
                  CalendarBottomBar, JournalPager, ProfileMenuButton
```

## Behaviour

- **Selected date** drives both the AppBar title region and the body.
  Default: today. Changing via the calendar or a horizontal swipe
  updates `_selectedDate` in the VM.
- **Body** — when the selected date has an entry, renders
  `JournalPager` (a `PageView.builder` over `vm.entries`, sorted
  ascending). Each page renders the entry's sections vertically: a
  text section becomes a full-width `TextSectionWidget`; a block-grid
  section becomes a non-scrolling `BlockGrid`. The whole stack scrolls
  together inside a single outer `SingleChildScrollView`. Editable for
  today (or when `DebugSettings.unlockAllDays` is on), read-only for
  past days.
- **Empty-day body** — today shows `MakeEntryCta`; past empty days
  show `NoEntryReadOnly`. Matches the pre-merge behaviour exactly.
- **AppBar** — `JournalTitle` (editable title + date subtitle) on
  the left; right actions are the Change-layout icon (when editable +
  hasEntry), a Statistics icon (pushes `/statistics`), and the
  `ProfileMenuButton` (PopupMenu with streak + auth header, then
  Settings / Layouts / Block settings rows that push the
  corresponding screens). The Statistics icon replaced the former
  Entries icon; `/entries` is still reachable by URL but no AppBar
  action links to it.
- **Bottom calendar bar** — `CalendarBottomBar`. Sticky compact week
  strip; the trailing month-icon opens a draggable bottom sheet with
  a full month view. Collapses to zero height when the keyboard is up.
- **Layout change** is destructive (replaces the entry's sections
  list, re-materializing from the new layout). Confirmed via a dialog
  before applying.
- **Swipe semantics** — left/right only between adjacent existing
  entries. Skips empty days. Selecting an empty day in the calendar
  takes the body out of the pager and into the CTA / read-only state.

## Subdirectory CLAUDE.md files

- [view/CLAUDE.md](view/CLAUDE.md) — `MainJournalScreen`
- [view_model/CLAUDE.md](view_model/CLAUDE.md) — `MainJournalViewModel`
- [widgets/CLAUDE.md](widgets/CLAUDE.md) — the per-screen widgets

## Routing contract

- `/` → `MainJournalScreen()` (defaults to today)
- `/journal/yyyy-mm-dd` → `MainJournalScreen(initialDate: parsed)`

Both routes resolve to the same widget; the path-parameter form is
used for deep-linking and by the entries-list tile taps.

## Gotchas

- **The PageView's `selectedDate` sync is two-way**. Calendar →
  `vm.setSelectedDate` → `JournalPager.didUpdateWidget` animates the
  controller. Swipe → `PageView.onPageChanged` → `vm.setSelectedDate`
  notifies the calendar. Don't trigger both paths for the same gesture
  or you'll get a re-entrant animateToPage.
- **`MakeEntryCta` only renders for today.** Past-day empty entries
  show `NoEntryReadOnly`. Match the editability gate
  (`_isToday(date) || debug.unlockAllDays`) before deciding which to
  show — the rule that lets `unlockAllDays` edit past days also lets
  it Make-entry on past days.
- **`CalendarBottomBar` rebuilds on `entriesByDay` set identity.**
  The VM rebuilds the set on every repository change, so the dots
  refresh automatically. The set is `const <DateTime>{}` when empty
  to avoid allocation churn on cold start.
- **Title editing is suppressed when no entry exists.** No entry =
  nothing to attach the title to. The screen shows date-only in the
  AppBar in that state; the title becomes editable once the user
  taps Make-entry and creates the entry.

## When to update this file

- The screen's composition changes (a new top-bar action, a new
  body branch, a new calendar position).
- The swipe-sync semantics change.
- A new screen-private widget is added to `widgets/`.
