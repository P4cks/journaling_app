# lib/ui/statistics/widgets — Statistics screen widgets

See [../CLAUDE.md](../CLAUDE.md) for how these compose into the screen.

## Files

- [stat_range_selector.dart](stat_range_selector.dart) —
  `StatRangeSelector`. Wraps `SegmentedButton<StatRange>` with the
  four labels from `StatRangeDisplay.label`. `showSelectedIcon: false`
  keeps each segment label-only.
- [summary_numbers_card.dart](summary_numbers_card.dart) —
  `SummaryNumbersCard`. Four cells (Entries / Words / Moods / Streak)
  separated by 1px vertical dividers in a single row. Large numbers
  format compactly: `1.2k`, `12k`, `1.0M`. Use this format helper
  consistently if you add more counters.
- [mood_distribution_chart.dart](mood_distribution_chart.dart) —
  `MoodDistributionChart`. fl_chart `BarChart`; one bar per emoji
  in `moodEmojis` order. X-axis labels are the emojis themselves;
  Y-axis grid step adapts to max count.
- [mood_over_time_chart.dart](mood_over_time_chart.dart) —
  `MoodOverTimeChart`. fl_chart `LineChart`; multiple `LineChartBarData`
  segments split on null-score days so gaps render as gaps.
  X-axis label step adapts to the number of points (1-day step for a
  week, ~5-day for a month, ~30-day for a year).
- [entry_frequency_chart.dart](entry_frequency_chart.dart) —
  `EntryFrequencyChart`. fl_chart `BarChart`; one bar per ISO week.
  Bar width and bottom-label step adapt to the number of buckets.
- [stats_empty_state.dart](stats_empty_state.dart) — `StatsEmptyState`.
  Reused for the page-level empty state and per-chart inline empty
  state (`compact: true`).

## Card shell duplication

Each of the three chart widgets defines its own private `_Card`
wrapper (title row + bordered rounded container) because the chart
files are visually parallel and the wrapper is ~30 lines. **If a
fourth chart is added**, extract `_Card` to a shared widget in this
directory instead of triple-duplicating.

## Gotchas

- **`fl_chart` axes use `Y`/`X` in their data model, not Material
  conventions.** `BarChartRodData.toY` is the bar height. Don't try
  to flip orientation by swapping axis titles.
- **Y-axis grid intervals must be integers** for clean readable labels.
  `_gridInterval()` enforces this by `ceilToDouble` after dividing.
- **The "Months" cell label in `SummaryNumbersCard` was specifically
  shortened to "Moods"** so the row fits on narrow phones. Don't
  rename to "Mood entries" without checking the row width.

## When to update this file

- A new widget is added.
- The card-shell duplication is removed (extract `_Card` to its own file).
- The `fl_chart` major version is bumped (signature breaks in 1.x — verify charts still build).
