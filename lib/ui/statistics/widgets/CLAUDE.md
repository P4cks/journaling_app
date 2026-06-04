# lib/ui/statistics/widgets — Statistics screen widgets

See [../CLAUDE.md](../CLAUDE.md) for how these compose into the screen.

## Files

- [stat_range_selector.dart](stat_range_selector.dart) —
  `StatRangeSelector`. A bordered, left-aligned `DropdownButton<StatRange>`
  (inside `DropdownButtonHideUnderline`) over the four
  `StatRangeDisplay.label`s. Takes a `SubscriptionRepository`. `Year`
  and `All` (`isProOnly`) render a trailing `ProLockBadge` in their menu
  items for free users; `_onSelected` runs `requirePro` for a locked
  pick and only calls `onChanged` for an already-Pro user or a
  successful purchase. `selectedItemBuilder` shows the bare label on the
  button face (no badge), since a free user can never have a locked
  range selected. (Replaced the former `SegmentedButton` switcher.)
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
  `EntryFrequencyChart`. fl_chart `BarChart` over `List<FreqBucket>`
  (`bucketStart` + `count`) plus a `FreqGranularity` (`week`/`month`/
  `year`). One bar per bucket; bar width and `_bottomInterval` thinning
  adapt to the bucket count. The card title is granularity-driven
  ("Entries per week / month / year"). `_bottomLabel` formats by
  granularity: weekly `M/D`, monthly bare `MMM` (**no year suffix** —
  the 365-day Year range always straddles two calendar years, so a
  `'YY` suffix widened every label enough to overlap; GUS-17), yearly
  `YYYY`. `_bottomInterval` thins labels (12 monthly bars → interval 3
  → ~4 labels) and `SideTitles.minIncluded/maxIncluded: false` keeps
  the first/last labels off the chart edges. The VM (`StatisticsViewModel`) owns
  bucketing + granularity selection — see
  [../view_model/CLAUDE.md](../view_model/CLAUDE.md).
- [stats_empty_state.dart](stats_empty_state.dart) — `StatsEmptyState`.
  Reused for the page-level empty state and per-chart inline empty
  state (`compact: true`).
- [streak_reward_card.dart](streak_reward_card.dart) — `StreakRewardCard`
  (`{required StreakResult streak, required StreakRewardSettings
  rewards}`). The GUS-22 celebratory card. Returns `SizedBox.shrink()`
  unless `rewards.isRewardUnclaimed(streak)`. Styled like
  `StreakStatCard` (`surfaceContainerHigh` + `outlineVariant`, radius
  14); gift icon + "7-day streak reward!" title + a "Claim your reward"
  `FilledButton.icon` that calls `showClaimRewardSheet`.
- [claim_reward_sheet.dart](claim_reward_sheet.dart) —
  `Future<void> showClaimRewardSheet(context, {required
  StreakRewardSettings rewards})`. Built on the shared
  [showDraggableSheet](../../core/widgets/bottom_sheet_scaffold.dart).
  Lists the still-locked Pro blocks (`kProOnlyBlockTypes` minus
  already-unlocked, via `BlockTypeDisplay.icon/label/description`) and
  the 3 Pro sections (`featureBlock` / `blockTextBody` / `wannado`,
  with label/icon/description **inlined to match `add_section_sheet`'s
  `_SectionTile` copy** — keep the two in sync). Tapping a tile awaits
  `rewards.claimBlock` / `claimSection` and pops. The claim methods
  guard the one-token spend, so a double-open can't over-claim.

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
