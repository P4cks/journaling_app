# lib/ui/blocks/memory_block — Memory block widget

One `BlockType.memoryBlock` block. Surfaces a single, locked-in
memory: a random non-empty block from a past entry, displayed in
miniature with a "from <date>" caption and tap-to-navigate. Content
shape:
`{"sourceEntryDate": "yyyy-MM-dd", "sourceBlockId": "...", "sourceType": "textBlock|moodTracker|photoBlock|promptBlock", "snapshotJson": "..."}`.
Typed wrapper:
[MemoryBlockContent](../../../data/model/block_content/memory_block_content.dart).

## Files

- [memory_block_widget.dart](memory_block_widget.dart) —
  `MemoryBlockWidget`. Stateful — owns the in-flight pick flag and the
  "no-eligible-history" terminal state.

## Pick lifecycle

- **First build with unseeded content** → asks
  [`JournalRepository.pickRandomEligibleBlock`](../../../data/repositories/journal_repository.dart)
  for a non-empty block of one of the *eligible* types from any entry
  strictly before today. The eligible set is user-configurable in
  Block-settings → Memory; the selectable list is
  `_MemoryEligibleTypesPicker._supportedTypes` (`textBlock`,
  `moodTracker`, `photoBlock`, `promptBlock`), and `textBlock` /
  `moodTracker` / `photoBlock` are on by default (`promptBlock` opt-in
  — see `BlockSettings.defaultMemoryEligibleTypes`).
  Self-referential memory blocks are excluded
  by the eligibility set, not by id. Photos from 2×2 feature-section
  photo blocks are eligible too — they snapshot the same way (path
  + JSON content) and render in this 1×1 tile as a cropped thumbnail.
- **On pick** → emits a new `JournalBlockData` via `onChanged` that
  bakes the snapshot, source id, source date, and source type into the
  entry's content. The memory is now **locked for the lifetime of this
  entry** — re-opening never re-rolls.
- **No eligible past block** → renders a dimmed "No memories yet"
  placeholder. The block stays unseeded so a later entry creation
  (after the user has more history) can fall into the same code path.

## Rendering

- **Caption** — `from <Month D, YYYY>` in primary color, semibold.
  Built via `formatEntryDate` from
  [ui/core/format/date_format.dart](../../core/format/date_format.dart).
- **Body** — switches on `sourceType`:
  - `textBlock` → scrollable `Text` with the snapshot's text.
  - `moodTracker` → large centred emoji.
  - `promptBlock` → scrollable column: the prompt question (italic,
    muted) above the user's answer text.
  - `photoBlock` → `Image.file(path)` clipped with a rounded corner,
    filling the tile with `BoxFit.cover`. Missing-path / read-failure
    falls through an `errorBuilder` to a dimmed italic "Photo missing"
    placeholder so a deleted source photo doesn't throw.
  - Anything else → "Memory" fallback (shouldn't render in practice
    given the eligibility set).
- **Tap target** — the whole card; pushes `Routes.journalEntryFor(parsed)`
  via `context.push`.

## Snapshotting

The widget stores the source block's `contentJson` verbatim in
`snapshotJson`. That insulates this entry from later schema changes to
the source block's content shape — old memories keep rendering even if
e.g. `TextBlockContent` gains new fields. To render, the widget
`jsonDecode`s the snapshot and runs the source-type-specific content
wrapper on the decoded map.

## Gotchas

- **Don't widen `_MemoryEligibleTypesPicker._supportedTypes` without
  updating `_renderSnapshot`.** Adding a new selectable type without a
  matching `switch` case results in the fallback "Memory" being shown —
  confusing.
- **Eligibility uses `JournalBlockEmptiness`** so e.g. an empty text
  block from a past entry never surfaces as a memory.
- **`MemoryBlockContent.isSeeded`** is the emptiness check, which means
  an entry whose only block is an un-pickable memory (no eligible
  history yet) WILL be swept. That's intentional — a memory-only entry
  with no memory is genuinely empty.
- **`onJumpToDate` is optional.** In the layout editor preview, no
  callback is wired — the rendered memory tile is non-interactive
  rather than throwing. The journal pager always provides a real
  callback, so tap-to-navigate works there. Don't re-add `required` or
  force-unwrap it in the dispatcher.

## When to update this file

- The eligibility set changes.
- A new source type is supported (also touch `_renderSnapshot`).
- The pick semantics change (e.g. one-per-week instead of locked-once).
