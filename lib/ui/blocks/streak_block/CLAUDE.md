# lib/ui/blocks/streak_block — Streak block widget

One `BlockType.streakBlock` block (GUS-22). A display-only 1×1 tile that
shows the streak **as of its own entry's date** prominently (fire icon +
big number + "day streak") with the **best streak up to that date** in
small text beneath ("Best: N days").

## Files

- [streak_block_widget.dart](streak_block_widget.dart) —
  `StreakBlockWidget` (stateless) + private `_StreakBody` + the
  `_entryDateFor` / `_normalizeDay` helpers. Reads `JournalRepository`
  from `AppDependencies` and wraps the body in a
  `ListenableBuilder(listenable: repository)`. On every notify it
  **self-locates** the hosting entry by matching `data.id` against
  `getAllEntries()` (`_entryDateFor` scans `entry.sections[].blocks[]`)
  to find that entry's date (`asOf`), then calls
  `computeStreak(entries.where(date <= asOf), now: asOf)` so **both** the
  current run and the best run read "as of that day" — July 1 → 1, July
  2 → 2, etc. **Falls back to the live, today-anchored
  `computeStreak(entries)` when the block isn't in any saved entry**
  (e.g. the layout-editor preview, where the sample block id matches
  nothing). `_StreakBody` lays the column out at natural size inside a
  `FittedBox(fit: scaleDown)` so it never overflows the tile.

## Content shape

**There is none.** Unlike every other block, the streak block stores no
per-entry content — the streak is a global derived stat, so there's no
`block_content/` wrapper. `BlockType.sampleData` / the materializer seed
it with an empty `const {}` content map. Consequences:

- `JournalBlockData.isEmpty` is hard-coded `false` (it always renders a
  value), and `BlockType.isUserInteractive` is `false` (auto-seeded — a
  streak-only entry is genuinely empty and stays sweepable at midnight).
  Both live in [journal_entry_emptiness.dart](../../../data/model/journal_entry_emptiness.dart).
- `_materializeOne` puts it in the empty-content fallthrough group.
- `_renderSnapshot` in the memory block lists it in the generic "Memory"
  fallback case (a memory should never snapshot a streak block, but the
  switch is exhaustive).

## Unlock / availability

Unlocked at the 7-day milestone for **everyone** (free + Pro) — every
`StreakRewardSettings` claim path adds `BlockType.streakBlock`. It is
deliberately **NOT** in `kProOnlyBlockTypes`: once unlocked it renders
free for all. The add-block sheet **hides** the streak-block cell
entirely until `rewards.isBlockUnlocked(BlockType.streakBlock)` (rather
than showing it greyed with a paywall — its unlock path is the milestone
reward, not a purchase).

## Gotchas

- **No content wrapper on purpose.** Don't add a `block_content/`
  class or a per-entry field — the streak is global. If you ever need
  per-entry config (e.g. "show best only"), add it via `visualsJson` or
  a new content map, not by making the live read per-entry.
- **The streak is scoped to the entry's own date, not today.** A naïve
  `computeStreak(getAllEntries())` shows *today's* streak echoed across
  every day's block (the original bug). The widget resolves the
  block's hosting-entry date and scopes the entries to `date <= asOf`
  before computing, so each day reads its own streak. The block id
  (`data.id`) is the only handle it has — no entry date is threaded
  through `BlockWidget`, so the self-lookup is deliberate. If you ever
  start threading the entry date down the dispatcher chain, prefer that
  over the O(entries) scan.
- **`onDoubleTap` is the only gesture.** It's a pure-display block;
  single taps are inert (consistent with quote / weather-api).

## When to update this file

- The streak block gains visible content or config.
- The unlock/visibility rule changes (e.g. it becomes free-by-default
  or Pro-gated).
