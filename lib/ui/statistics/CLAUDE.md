# lib/ui/statistics — Statistics screen

Aggregate view over the user's entries: streak, mood distribution,
mood-over-time, entry frequency, and total counters. Pushed from the
main screen's top-bar Statistics icon (replacing the former Entries
push — the entries list screen still exists at `/entries` for future
reuse but is no longer linked from the AppBar).

```
statistics/
├── view/         StatisticsScreen — Scaffold + range selector + cards in a CustomScrollView
├── view_model/   StatisticsViewModel — subscribes to JournalRepository, computes aggregates
└── widgets/      StatRangeSelector, SummaryNumbersCard, MoodDistributionChart,
                  MoodOverTimeChart, EntryFrequencyChart, StatsEmptyState
```

## Behaviour

- Top of page: a left-aligned **dropdown** (`StatRangeSelector`) with
  `Week | Month | Year | All`. **`Year` and `All` are Pro-locked**
  (`StatRangeDisplay.isProOnly`) — those menu items carry a
  `ProLockBadge` and selecting one as a free user presents the
  RevenueCat paywall via `requirePro`; the range only changes for an
  already-Pro user or on a successful purchase. The selector takes a
  `SubscriptionRepository`, and the screen wraps it in a
  `ListenableBuilder` so the badges clear live when `isPro` flips.
  (Replaced the former `SegmentedButton` switcher.)
  Window definitions (relative to today):
  - `week` — last 7 days inclusive
  - `month` — last 30 days inclusive
  - `year` — last 365 days inclusive
  - `all` — no filter; uses the earliest-entry → today span for the
    time-series charts.
- Streak card is **range-independent** — `computeStreak` always
  considers all entries (it's a lifetime stat).
- Mood distribution is a vertical bar per emoji in `moodEmojis` order
  (stable X-axis regardless of which moods were picked).
- Mood-over-time is a line chart with score 0–5. Days with no mood
  emit `null` from the VM and break the line into multiple
  `LineChartBarData` segments.
- Entry frequency is weekly bars; week start is Monday to match
  `table_calendar`'s default.
- Empty state: page-level `SliverFillRemaining` when no entries fall
  in the range. Per-chart inline empty state when entries exist but
  no mood data.

## Subdirectory CLAUDE.md files

- [view/CLAUDE.md](view/CLAUDE.md) — `StatisticsScreen`
- [view_model/CLAUDE.md](view_model/CLAUDE.md) — `StatisticsViewModel`, `StatRange`, `MoodPoint`, `WeekBucket`
- [widgets/CLAUDE.md](widgets/CLAUDE.md) — the chart + range + summary widgets

## Mood score scale

Subjective valence; positive ≈ 4–5, neutral ≈ 2.5–3, negative ≈ 0–1.

```
😍 → 5.0   😄 → 4.5   😊 → 4.0   😌 → 3.5
🤔 → 3.0   😐 → 2.5
😢 → 1.5   😠 → 1.0   😩 → 0.5
```

Unknown emojis (e.g. an emoji removed from `moodEmojis` but still
present in old data) return `null`, treated as "no mood that day".

## Gotchas

- **Days with no mood emit `null`, never `0`.** A `0` would look
  indistinguishable from 😩 (score 0.5). The line chart splits the
  series into segments so gaps render as gaps.
- **`window` is recomputed each `_recompute` call from `DateTime.now()`.**
  If the user lingers on the page across midnight, the range slides
  to include the new day. This is fine — `repository.addListener`
  will refire on the next entry change.
- **`StreakStatCard` is re-used unchanged from `lib/ui/core/widgets/`.**
  Don't fork a parallel implementation.
- **The repository listener is mandatory.** Without it, adding a
  mood block won't update the charts until the user navigates away
  and back. `dispose` must `removeListener` to avoid a leak.
- **Entries page (`/entries`) is intentionally kept** in the codebase.
  Do not delete `lib/ui/journal_entries/` — the user wants the option
  to restore the list view later without git archaeology.

## When to update this file

- A new chart is added or removed.
- The mood-score scale changes (the table above is the source of truth).
- The range definitions change (e.g. calendar-month vs rolling-30-day).
- A new visualization library is introduced (currently `fl_chart`).
