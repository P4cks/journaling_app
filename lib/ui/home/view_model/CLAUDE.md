# lib/ui/home/view_model — Home view model

See [../CLAUDE.md](../CLAUDE.md) for the screen overview.

## Files

- [home_view_model.dart](home_view_model.dart) — `HomeViewModel extends ChangeNotifier`.

## State

| Field           | Type                | Purpose                                              |
|-----------------|---------------------|------------------------------------------------------|
| `selectedDate`  | `DateTime` (date-only) | The day the calendar highlight + preview shows.   |
| `focusedDate`   | `DateTime` (date-only) | What `TableCalendar` is centered on. Tracks page swipes. |
| `currentEntry`  | `JournalEntry?`     | The entry for `selectedDate`, or null.               |
| `entriesByDay`  | `Set<DateTime>`     | Days with entries — feeds `eventLoader` for dots.    |

All `DateTime`s here are local-midnight normalized via `_dateOnly`.

## Methods

- `selectDate(date)` — calendar tap. Normalizes, no-ops on unchanged.
  Reloads the entry, notifies.
- `updateFocusedDate(date)` — calendar page-change. No-op on unchanged.
  **Does not notify** — focused-date alone doesn't drive any UI outside
  `TableCalendar`'s internal state.
- `reload()` — re-pulls entry + entries-by-day. Called from
  `HomeScreen._openEditor` after the editor pops.
- `createEntryWithLayout(layout)` — creates and persists a new entry
  for `selectedDate`, sets `_currentEntry`, notifies. The repository
  will *also* notify (which calls `_onRepositoryChanged`); the double-
  notify is intentional so the screen renders the new entry without
  waiting for the async tick.

## Subscriptions

- Subscribes to `JournalRepository` in the constructor. `_onRepositoryChanged`
  re-reads the entry for `selectedDate` (it may have been mutated /
  swept elsewhere) and recomputes `entriesByDay`.
- Unsubscribes in `dispose`.

## Gotchas

- **`updateFocusedDate` deliberately doesn't notify.** Notifying would
  trigger an extra rebuild on every calendar swipe. The state is read
  back on the next user tap (`selectDate`).
- **`entriesByDay` is recomputed in full on every notification.** Fine
  while the entries set is small. If we ever cross a few thousand
  entries, consider an incremental delta update from the repository.

## When to update this file

- New state is added to the VM.
- The notification model changes (e.g. partial notifications).
- The repository starts emitting per-entry change events.
