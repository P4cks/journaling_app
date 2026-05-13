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
| `_entries`             | Sorted ascending. Data source for `JournalPager`.    |
| `_entriesByDay`        | `Set<DateTime>` for the calendar's `eventLoader`.    |

All DateTimes are local-midnight normalized via `_dateOnly`.

## Methods

- `setSelectedDate(date)` — guard against no-op; notify.
- `entryForDate(date)` — repository passthrough (`getEntryForDate`).
  O(1) Hive lookup.
- `pageIndexForDate(date)` — linear scan of `_entries`; returns
  `int?` (null when no entry). The screen feeds this to `JournalPager`'s
  controller.
- `createWithLayout(layout)` — calls
  `JournalRepository.createEntryForDate`. The repository notifies; we
  rebuild `_entries` / `_entriesByDay` and notify. We also notify
  eagerly to avoid the async-tick gap (Home-VM precedent).
- `updateBlock(updated)` — locates the block by id within the current
  entry, swaps it, bumps `lastModified`, persists. The repository
  notification rebuilds our list.
- `updateTitle(newTitle)` — trim → empty becomes null. No-op on
  unchanged.
- `applyLayout(layout)` — destructive; re-materializes the entry's
  blocks. Caller must confirm.

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
