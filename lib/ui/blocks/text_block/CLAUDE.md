# lib/ui/blocks/text_block — Text block widget

One `BlockType.textBlock` block. Renders inside a `BlockCard` (square
1×1 cell in the staggered grid). Content is `{"text": "..."}` JSON
stored in `JournalBlockData.contentJson`; the typed wrapper is
[TextBlockContent](../../../data/model/block_content/text_block_content.dart).

## Files

- [text_block_widget.dart](text_block_widget.dart) — `TextBlockWidget`.
  Stateful so it can hold its own `TextEditingController` (mounted in
  `initState`, swapped in `didUpdateWidget` on `data.id` change,
  disposed in `dispose`).

## Modes

- `BlockMode.readOnly` — renders a `Text`. Empty text shows "No text yet"
  in italic + `disabledColor`.
- `BlockMode.editable` — renders a multi-line `TextField` filling the
  square cell. **Required field config** for in-cell scrolling:
  - `expands: true`
  - `maxLines: null`
  - `minLines: null`
  - inside a `SizedBox.expand`
  Without all four, the field tries to grow with content and blows out
  the 1×1 cell. The hint is "Write something…".
  `onChanged` fires per keystroke and emits a new `JournalBlockData`
  via the parent's `onBlockChanged` callback — `JournalEntryEditorViewModel.updateBlock`
  saves every keystroke. (`copyWith(lastModified: DateTime.now())` runs
  per save; this is fine in practice but worth knowing if you start
  profiling.)

## Implementation details

- The controller's text is **only** reset when `data.id` changes
  (i.e. the block was replaced, not edited in place). That keeps the
  caret position stable across notifications.
- The widget is keyed by `ValueKey(block.id)` from `BlockGrid`, so a
  reorder unmounts/remounts cleanly.

## Gotchas

- **Don't bind the controller's text to `widget.data.content` on every
  build** — that would race the per-keystroke save+notify cycle and
  thrash the caret.
- **The widget assumes it's inside a square parent** (the `BlockCard`
  in the 1×1 staggered tile). If you reuse it outside that context,
  drop the `SizedBox.expand` or it'll demand infinite height.

## When to update this file

- The text block gains structure (rich text, attachments) — that
  changes the persisted shape; update [block_content/CLAUDE.md](../../../data/model/block_content/CLAUDE.md)
  too, and either add a read-fallback in `TextBlockContent.fromMap` or
  bump the entries box name.
- A new mode is added (e.g. preview-with-link-resolution).
