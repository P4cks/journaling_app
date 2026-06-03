# lib/ui/journal/view_model — Main journal view model

See [../CLAUDE.md](../CLAUDE.md) for the screen overview.

## Files

- [main_journal_view_model.dart](main_journal_view_model.dart) —
  `MainJournalViewModel extends ChangeNotifier`.

## What it owns

Fuses the responsibilities of the pre-merge `HomeViewModel` and
`JournalEntryEditorViewModel`:

| State                  | Purpose                                              |
|------------------------|------------------------------------------------------|
| `_selectedDate`        | Drives the AppBar, the body branch, and the pager.   |
| `_entries`             | Sorted ascending. Calendar dots + entry lookups.     |
| `_entriesByDay`        | `Set<DateTime>` for the calendar's `eventLoader`.    |
| `_pagerDates`          | Normalized dates the pager renders (data source for `JournalPager`). |

All DateTimes are local-midnight normalized via `_dateOnly`.

## Methods

- `setSelectedDate(date)` — guard against no-op; notify.
- `entryForDate(date)` — repository passthrough (`getEntryForDate`).
  O(1) Hive lookup.
- `pagerDates` — the dates `JournalPager` iterates: entry dates,
  ascending, **plus today appended** when today has no entry yet (the
  trailing synthetic make-entry page; GUS-29). Today is always the max
  (entries are today-or-earlier), so appending keeps it sorted.
  Rebuilt in `_rebuildEntries` alongside `_entries`.
- `todayHasEntry` — `_entriesByDay.contains(today)`. False ⇒ the pager
  carries the synthetic today page.
- `pageIndexForDate(date)` — linear scan of `pagerDates`; returns
  `int?` (null when the date is neither an entry day nor the synthetic
  today page). Today resolves to the trailing index when empty. The
  screen uses non-null here both to position `JournalPager`'s
  controller and to decide whether to mount the pager at all.
- `defaultLayoutId` — `_layoutRepository.getDefault()?.id`, or `null`.
  Passed to `showLayoutPickerSheet` so the picker highlights the
  default row (GUS-28).
- `createWithLayout(layout)` — calls
  `JournalRepository.createEntryForDate`. The repository notifies; we
  rebuild `_entries` / `_entriesByDay` and notify. We also notify
  eagerly to avoid the async-tick gap (Home-VM precedent).
- `updateBlock(updated)` — walks **every section** of the current
  entry to find the matching block by id, swaps it, bumps
  `lastModified`, persists. The repository notification rebuilds our
  list. Sections that don't own the updated block are copied with an
  unchanged blocks list (cheap; the comprehension reuses references).
- `updateTitle(newTitle)` — trim → empty becomes null. No-op on
  unchanged.
- `reorderBlockInSection(sectionId, from, to)` — moves the block at
  `from` to `to` within the matching section's `blocks` list, bumps
  `lastModified`, persists via `saveJournalEntry`. Insertion
  semantics match `LayoutEditorViewModel.moveSlotInSection` — the
  caller (`BlockGrid` via `JournalPager`'s drag-drop) already adjusts
  the target index for the post-remove list. Used by the journal
  pager's drag-and-drop in editable entries.
- `applyLayout(layout)` — destructive; re-materializes the entry's
  **sections** from the new layout (calls
  `JournalRepository.materializeLayout`). Caller must confirm.

## Subscriptions

- Subscribes to `JournalRepository` in the constructor. `_onRepositoryChanged`
  re-runs `_rebuildEntries` (sort + set rebuild) and notifies.
- Unsubscribes in `dispose`.

## Gotchas

- **`_rebuildEntries` runs on every repository notification.** It sorts
  the full list (`O(n log n)`) and builds a fresh set. Fine for
  personal-journal data volumes (a few thousand entries at most).
  Don't add a sweep call here — sweeps trigger the same notification
  we're listening to, and we're already idempotent.
- **`updateBlock` / `updateTitle` write to the repository, not to a
  local `_entry`.** The repository's notification is what rebuilds our
  `entries` list, which is what the pager renders. There is no
  per-entry mutable copy held in the VM — the repository is the
  single source of truth.
- **`pageIndexForDate` is `O(n)` (linear scan).** For the volumes we
  expect this is fine. If we ever care, hold a `Map<DateTime, int>`
  alongside `_entries` and update both in `_rebuildEntries`.

## When to update this file

- New state is added (e.g. selection mode, filter).
- The mutation surface changes (debounce, undo, batch save).
- The repository notification contract changes.
