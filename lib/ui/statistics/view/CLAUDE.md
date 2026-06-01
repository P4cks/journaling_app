# lib/ui/statistics/view — Statistics screen widget

See [../CLAUDE.md](../CLAUDE.md) for the screen overview.

## Files

- [statistics_screen.dart](statistics_screen.dart) — `StatisticsScreen`
  (StatefulWidget). Standard VM-binding pattern (see
  [ui/CLAUDE.md](../../CLAUDE.md)). Also stashes
  `deps.subscriptionRepository` in `didChangeDependencies` so the
  range-selector's Pro gate can read live `isPro`.

## Composition

```
Scaffold
├── AppBar("Statistics")
└── body: CustomScrollView
          ├── SliverToBoxAdapter: ListenableBuilder(_subscriptions)
          │     → StatRangeSelector(vm.range, vm.setRange, subscriptions)
          ├── if (vm.isEmpty) SliverFillRemaining: StatsEmptyState
          └── else: SummaryNumbersCard
                    + SectionHeader("Streak") + StreakStatCard
                    + SectionHeader("Mood") + MoodDistributionChart + MoodOverTimeChart
                    + SectionHeader("Frequency") + EntryFrequencyChart
                    + trailing safe-area spacer
```

## Gotchas

- **Empty state goes through `SliverFillRemaining(hasScrollBody: false)`**
  so the empty centered widget aligns with the available space below
  the range selector. Don't switch to `SliverToBoxAdapter` — the
  empty state would top-align awkwardly.
- **The range selector is rendered even when `vm.isEmpty`.** The user
  can still switch ranges (in case a different range happens to have
  data).

## When to update this file

- The screen composition gains or loses a card.
- An empty-state branch changes shape.
