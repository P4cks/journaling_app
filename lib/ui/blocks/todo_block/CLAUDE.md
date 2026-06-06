# lib/ui/blocks/todo_block — Todo block widget

One `BlockType.todoBlock` block. Renders a checklist inside the 1×1
cell — in the grid, items that exceed the cell height are clipped
(matching the text block's bounded behaviour); in the expanded route
the list scrolls. Content shape:
`{"items": [{"id": "...", "text": "...", "done": true}]}` (the
`done` key is omitted when false). Typed wrapper:
[TodoBlockContent](../../../data/model/block_content/todo_block_content.dart).

## Files

- [todo_block_widget.dart](todo_block_widget.dart) — `TodoBlockWidget`
  + private `_TodoRow` and `_CheckBubble`. Stateful because it owns one
  `TextEditingController` per item (keyed by item id) so the caret
  position survives the per-keystroke save → rebuild cycle.

## Modes

- `BlockMode.readOnly` — `Column` of bullet rows: small bubble (filled
  when done) + the item text (struck-through + dimmed when done). Each
  row's text is `maxLines: 1` + `overflow: TextOverflow.ellipsis`.
  Empty list → "No todos" italic placeholder. In the grid the Column
  is wrapped in `ClipRect` so excess rows clip to the cell; in the
  **expanded route** (`expanded == true`) it's wrapped in a
  `SingleChildScrollView` so every item is reachable.
- `BlockMode.editable` — `Column` of rows, each a single-line
  `TextField` plus a tiny ✕ button. Tapping the bubble toggles done.
  In the grid the rows sit inside a `ClipRect`; when `expanded` they
  sit inside a `SingleChildScrollView`. The "+ Add item" InkWell lives
  OUTSIDE that wrapper at the natural bottom of the outer Column so it
  stays visible even when items overflow.
  **Char input is uncapped** (the GUS-10 per-item char cap + counter
  was removed). The only remaining cap is the **item count**:
  `kTodoMaxItems` = 8, a plain local constant in
  `todo_block_widget.dart` (a count, not a char cap; UI-enforced, no
  Hive bump). `_add` no-ops at the cap; the "Add item" control greys
  out and an `n/max tasks` label sits to its right (turning
  `error`-coloured at the cap).

## Implementation details

- **Items live in the entry, not the layout.** Each entry's todo block
  starts with `items: []`. Users add/remove per-entry. No layout-level
  template list. (If you want a recurring checklist later, move it to
  `BlockSettings` like the prompt list.)
- **Per-keystroke save.** Every text change emits a new
  `JournalBlockData`, same pattern as `TextBlockWidget`. The widget's
  `_controllers` map keeps each item's `TextEditingController` alive
  across rebuilds; we only overwrite a controller's value when the
  *model* value diverges from the controller's value (i.e. when the
  change came from outside this widget). Without that guard, every
  keystroke would reset the cursor to the end.
- **Item ids are uuids generated client-side** when "+ Add item" is
  tapped. The id is the row's `ValueKey` and the controller-map key —
  it must be stable for the lifetime of the item.
- **Emptiness**: empty list OR every item has empty-after-trim text.
  A list of empty rows doesn't count as content for sweep purposes.

## Gotchas

- **Don't reuse `TextEditingController`s across item ids.** The
  `_controllers` map disposes the old controller when an item is
  removed; that's important to avoid leaks on heavy churn.
- **The "+ Add item" affordance is intentionally below the list, not
  in the AppBar.** Keeps every interaction inside the cell so the
  block works identically in the fullscreen editor and the home
  preview.

## When to update this file

- The item shape gains fields (due date, priority, sub-items).
- A bulk action is added (clear completed, reorder items).
- The empty-row "still counts as empty" rule changes — also touch
  [journal_entry_emptiness.dart](../../../data/model/journal_entry_emptiness.dart).
