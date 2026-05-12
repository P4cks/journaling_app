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
  square cell, wrapped in a `Stack` to overlay an optional character
  counter in the bottom-right corner. **Required field config** for
  in-cell scrolling:
  - `expands: true`
  - `maxLines: null`
  - `minLines: null`
  - inside a `SizedBox.expand`
  Without all four, the field tries to grow with content and blows out
  the 1×1 cell. The hint is "Write something…".
  `onChanged` fires per keystroke and emits a new `JournalBlockData`
  via the parent's `onBlockChanged` callback — `JournalEntryEditorViewModel.updateBlock`
  saves every keystroke.

## Character limit (optional, global)

When [BlockSettings.textCharLimit](../../../data/services/block_settings.dart)
is non-null, the field gains `TextField.maxLength = limit` (Flutter
enforces the hard cap by silently dropping further input), and a tiny
`N/limit` counter renders in the bottom-right corner of the cell. The
default Material counter widget is suppressed via
`buildCounter: (_) => null` so it doesn't reserve vertical space below
the input.

The limit is **block-type-global** and read live via a
`ListenableBuilder(listenable: blockSettings, ...)` — changing the
limit in Profile → Block settings → Text takes effect immediately
across every text block in every entry. It is **not** persisted in the
entry's content, so it doesn't bake into historical entries.

## Gotchas

- **Don't bind the controller's text to `widget.data.content` on every
  build** — that would race the per-keystroke save+notify cycle and
  thrash the caret.
- **The widget assumes it's inside a square parent** (the `BlockCard`
  in the 1×1 staggered tile). If you reuse it outside that context,
  drop the `SizedBox.expand` or it'll demand infinite height.
- **The character counter uses `_controller.text.characters.length`**
  (grapheme clusters), not `String.length`. Match `TextField.maxLength`'s
  semantics so a 200-cap shows `200/200` when full, not e.g. `203/200`
  for emoji-heavy text.

## When to update this file

- The text block gains structure (rich text, attachments) — that
  changes the persisted shape; update [block_content/CLAUDE.md](../../../data/model/block_content/CLAUDE.md)
  too, and either add a read-fallback in `TextBlockContent.fromMap` or
  bump the entries box name.
- The char-limit moves back to per-entry or grows additional global
  toggles — keep [BlockSettings](../../../data/services/block_settings.dart)
  and this file in sync.
