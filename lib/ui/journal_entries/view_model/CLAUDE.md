# lib/ui/journal_entries/view_model — Entries-list view model

See [../CLAUDE.md](../CLAUDE.md) for the screen overview.

## Files

- [journal_entries_view_model.dart](journal_entries_view_model.dart) —
  `JournalEntriesViewModel extends ChangeNotifier` + `MonthSection`
  value class.

## State

- `_sections` — `List<MonthSection>` (newest-month-first, entries
  within each section newest-first). Rebuilt fully on every repository
  notification.

## `_rebuild()`

1. Pull all entries from the repository.
2. Sort descending by `date`.
3. Bucket into a `Map<int, List<JournalEntry>>` keyed by
   `year * 100 + month`. Maintain insertion order of keys in a parallel
   list so the output respects the sorted-newest-first order from
   step 2.
4. Build `_sections` from the ordered keys.

## Subscriptions

- Subscribes to `JournalRepository` in the constructor; rebuilds and
  notifies on every change.
- Unsubscribes in `dispose`.

## Gotchas

- **Full rebuild on every notification.** Fine while entry counts stay
  modest. If this becomes a hotspot, switch to maintaining the
  `_sections` structure incrementally on per-entry events from a
  richer repository notification model.
- **`MonthSection.entries` is a `List`, not unmodifiable.** Callers
  must not mutate it; the VM hands out the same reference it stored.

## When to update this file

- The grouping scheme changes.
- The repository starts emitting incremental events.
