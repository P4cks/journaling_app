# lib/ui/core/format — Formatting helpers

Tiny utility module. **No `intl` dependency** — the app is English-only
for now and the formats here are simple enough to spell by hand. If we
need localization, this directory is the first thing to rewrite.

## Files

- [date_format.dart](date_format.dart) — two top-level functions:
  - `formatEntryDate(DateTime d)` → e.g. `"May 11, 2026"`. Used for
    AppBar titles and list-tile dates.
  - `formatMonthHeader(int year, int month)` → e.g. `"May 2026"`. Used
    for the section header on the entries list.
  Backed by two private `const` arrays (`_monthsShort`, `_monthsLong`)
  indexed by `month - 1`. The function signatures take month as 1-based
  to match `DateTime.month`.

## Gotchas

- **`month - 1` indexing**. Passing `0` or `13` would crash. Callers
  always derive from a `DateTime`, so this is safe — but if a JSON
  field ever feeds in, validate upstream.

## When to update this file

- A new formatter is added (time-of-day, durations, relative).
- We adopt `intl`/`flutter_localizations` — at that point this whole
  directory probably collapses into thin wrappers.
