# lib/ui/blocks/habit_tracker — Habit tracker block widget (GUS-13)

Renders a user-defined habit — each block instance points at a
[HabitDefinition](../../../data/model/habit_definition.dart) in the
`BlockSettings` registry (title + icon), and the widget reads them at
render time. Definitions are shared across every block that references
the same id; editing one propagates live. Each block carries a per-day
`completed` flag; the **streak** (consecutive crossed-off days) is
*derived*, never stored.

Content shape (per block):
`{"definitionId": "uuid", "completed": true}` (both omitted when null /
false). Typed wrapper:
[HabitBlockContent](../../../data/model/block_content/habit_block_content.dart).

## Files

- [habit_tracker_widget.dart](habit_tracker_widget.dart) —
  `HabitTrackerWidget`. Stateless. Subscribes to both `BlockSettings`
  (definition edits) and `JournalRepository` (streak recompute) via
  `ListenableBuilder(Listenable.merge([...]))`. Resolves the definition
  for title (`BlockWithTitle`) + icon (`carouselIconFor`, shared
  catalogue). Big `_HabitCheckBubble` toggles `completed` on tap in
  editable mode; `_StreakBadge` (flame + count) shows only when the
  streak is > 0. Orphan / preview handling lives here (`_DeletedPlaceholder`).

## Streak rule

`_computeStreak` walks `JournalRepository.getAllEntries()` once,
building the set of normalized dates on which any habit block with this
`definitionId` is `completed`, while simultaneously locating this
block's own entry date by matching `block.id == data.id` (block ids are
globally-unique uuids). The in-hand `completed` value overrides the
anchor day's membership so an unsaved toggle is reflected immediately.

The streak = consecutive completed days ending at the anchor date when
today is crossed off, otherwise the run ending the day before (so the
user still sees the streak they're about to lose). Day stepping uses
`DateTime(y, m, d - 1)` (not `Duration(days: 1)`) to stay correct across
DST boundaries — the membership set is keyed on normalized midnights.

## Modes

- `BlockMode.readOnly` — non-interactive bubble showing the stored
  state; streak still rendered.
- editable (`onChanged != null`) — tap toggles `completed`. `onDoubleTap`
  is forwarded so the host can push the expanded route.

## Orphan & preview states

- **Missing definition** (`definitionId` present but `findHabit` returns
  null — deleted out from under the block): dimmed italic "Deleted
  block" placeholder. The entry keeps its logged `completed` flag on
  disk; the sweep treats an unchecked orphan as empty.
- **`definitionId == null`**: the preview / `sampleData` path only (real
  materialized blocks always carry the slot's definitionId). Renders a
  generic checkbox with the default check glyph, no title, no streak.

## Gotchas

- **Streak is O(entries × blocks) per build.** Fine at journaling scale
  (hundreds of entries). If entry counts ever explode, memoize or push
  the computation into the repository.
- **The widget self-locates its entry date** by scanning for its own
  block id rather than having the date threaded through `BlockWidget` —
  this keeps the many preview call sites (layout editor, add-block
  sheet) free of a date they don't have. Preview/sample ids that match
  no entry fall back to `DateTime.now()`.
- **Icon catalogue is shared with custom carousel** (`kCarouselIcons`).
  Removing a catalogue entry orphans the icon → fallback check glyph,
  not a crash.

## When to update this file

- The streak rule changes (anchor semantics, gap tolerance).
- A new orphan / preview branch is added.
- The habit gains configurable fields beyond title + icon.
