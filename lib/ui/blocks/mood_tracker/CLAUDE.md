# lib/ui/blocks/mood_tracker — Mood tracker block widget

One `BlockType.moodTracker` block. Content shape: `{"moodId": "happy"|"neutral"|"sad"}`
(absent → no mood selected). Typed wrapper: [MoodBlockContent](../../../data/model/block_content/mood_block_content.dart).

## Files

- [mood_tracker_widget.dart](mood_tracker_widget.dart) — `MoodTrackerWidget`.
  Stateless (the selection lives in `widget.data.content`).

## Modes

- `BlockMode.readOnly` — renders a `Row` with the selected mood's
  filled Phosphor icon + label. When `mood == null`, shows "No mood"
  in italic + `disabledColor`.
- `BlockMode.editable` — renders a `Wrap` of `ChoiceChip`s, one per
  `Mood` value. Tapping a chip emits a new `JournalBlockData`:
  - Picking a new mood → `MoodBlockContent(mood: m)`.
  - Tapping the currently-selected chip → emits `MoodBlockContent()`
    (clears the selection).
  `FocusScope.of(context).unfocus()` runs on every selection to dismiss
  any text-field keyboard from a neighboring block.

## Icon mapping

Per-mood icon swaps between Phosphor duotone (unselected) and fill
(selected):

| Mood    | duotone           | fill           |
|---------|-------------------|----------------|
| happy   | `smiley`          | `smiley`       |
| neutral | `smileyMeh`       | `smileyMeh`    |
| sad     | `smileySad`       | `smileySad`    |

Add a new `Mood` enum case → add a case to both `_iconFor` and
`_labelFor`. The `JournalBlockEmptiness` extension only cares whether
`mood == null`, so new moods don't change emptiness semantics.

## Gotchas

- **Adding a `Mood` enum value** changes the wire format only via the
  new id string. Existing entries with old ids stay valid; entries
  with the new id won't decode on an older app version (returns `null`
  → "No mood"). Same forward/backward story as `BlockType` itself.
- **Persisted ids are the enum `name`s**, not indices. Don't reorder
  the enum and don't rename a value — that *would* break existing data.

## When to update this file

- A new `Mood` value is added or one is renamed (the latter needs a
  `fromMap` fallback or a box bump).
- The chip layout changes (e.g. radio behavior, multi-select).
