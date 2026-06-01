# lib/ui/statistics/view_model — Statistics view-model

See [../CLAUDE.md](../CLAUDE.md) for the screen overview, including
the mood-score scale and range definitions.

## Files

- [statistics_view_model.dart](statistics_view_model.dart) — exports
  `StatisticsViewModel` plus the value types `StatRange`,
  `StatRangeDisplay` extension, `MoodPoint`, `WeekBucket`. The
  `StatRangeDisplay` extension carries `label` and `isProOnly` (true for
  `year` / `all`). The VM is **tier-agnostic** — `isProOnly` is consumed
  only by the UI gate (`StatRangeSelector`); `setRange` sets any range
  it's handed.

## Subscription model

- Constructor takes a `JournalRepository`, calls `addListener` and
  runs an initial `_recompute`.
- Every `notifyListeners` from the repository triggers `_recompute`
  followed by `notifyListeners` on this VM.
- `setRange` is the only user-facing mutator. It guards against no-op
  and only `notifyListeners` after a real change.
- `dispose` removes the repository listener — required to avoid
  rebuilding a torn-down widget.

## Computed aggregates

All cached after `_recompute`; getters just return the cached value.

| Getter             | Type                          | Recomputed when                  |
|--------------------|-------------------------------|----------------------------------|
| `totalEntries`     | `int`                         | range or repo change             |
| `totalWords`       | `int`                         | range or repo change             |
| `totalMoodEntries` | `int`                         | range or repo change             |
| `streak`           | `StreakResult`                | repo change (range-independent)  |
| `moodDistribution` | `Map<String, int>` ordered    | range or repo change             |
| `moodOverTime`     | `List<MoodPoint>`             | range or repo change             |
| `entryFrequency`   | `List<WeekBucket>`            | range or repo change             |
| `isEmpty`          | `bool` (totalEntries == 0)    | derived                          |

## Window semantics

- `week` / `month` / `year` → rolling N-day window ending today.
- `all` → no filter for inclusion; for time-series, span is
  earliest-entry → today (so the line/bar chart isn't a single point
  on a brand-new account).

## Gotchas

- **`_firstMoodEmoji` only inspects `BlockType.moodTracker` blocks.**
  Entries with multiple mood blocks (rare) take the first emoji
  found. Don't average across — the chart is one point per day.
- **Word count uses `RegExp(r'\s+')` after trim.** Empty text blocks
  are skipped to keep zero-word "I forgot to write today" entries
  from inflating counts.
- **`_weekStart` returns Monday-midnight.** Match `table_calendar`'s
  default. Switching to Sunday would also need updating the calendar
  bar and any week-keyed UI elsewhere.
- **Streak ignores the range.** It's a lifetime stat; computing it
  per-window would give surprising results (a 60-day streak in
  "Week" view becomes 7).

## When to update this file

- A new aggregate is added (declare its caching + recompute trigger).
- The window definitions or mood-score scale change.
- The subscription model changes (e.g. additional listeners,
  debouncing).
