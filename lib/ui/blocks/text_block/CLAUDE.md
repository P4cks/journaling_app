# lib/ui/blocks/text_block — Text block widget

One `BlockType.textBlock` block. Renders inside a `BlockCard` (square
1×1 cell in the staggered grid). Content is `{"text": "..."}` JSON
stored in `JournalBlockData.contentJson`; the typed wrapper is
[TextBlockContent](../../../data/model/block_content/text_block_content.dart).

## Files

- [text_block_widget.dart](text_block_widget.dart) — `TextBlockWidget`.
  Stateful so it can hold its own `TextEditingController` (mounted in
  `initState`, swapped in `didUpdateWidget` on `data.id` change,
  disposed in `dispose`). Takes an `expanded` bool (default `false`,
  threaded from `BlockWidget`) that controls grid-vs-expanded scroll
  behaviour.

## Modes

- `BlockMode.readOnly` — renders a `Text` inside a `LayoutBuilder`.
  Input is **uncapped**, so the read-only display computes
  `maxLines = (constraints.maxHeight / lineHeight).floor()` (line
  height from a `TextPainter` over the resolved `bodyMedium` style) and
  renders with that `maxLines` + `overflow: TextOverflow.ellipsis` —
  a clean truncation that fills the fixed 1×1 cell. Empty text shows
  "No text yet" in italic + `disabledColor`.
- `BlockMode.editable` — renders a multi-line `TextField` filling the
  square cell. **Required field config**:
  - `expands: true`
  - `maxLines: null`
  - `minLines: null`
  - `scrollPhysics: expanded ? ClampingScrollPhysics() : NeverScrollableScrollPhysics()`
  - inside a `SizedBox.expand`
  Input is **uncapped** — no `maxLength`, no enforcement, no counter
  (the GUS-10 char-cap scaffold was removed). In the grid host
  (`expanded == false`) `NeverScrollableScrollPhysics` disables the
  TextField's internal scroll so overflow content is clipped by the
  chrome's `clipBehavior: Clip.antiAlias`. In the **expanded route**
  (`expanded == true`) `ClampingScrollPhysics` lets the field scroll
  through the full text. Without `expands` / `maxLines: null` the field
  tries to grow with content and blows out the 1×1 cell. The hint is
  "Write something…". `onChanged` fires per keystroke and emits a new
  `JournalBlockData` via the parent's `onBlockChanged` callback —
  `JournalEntryEditorViewModel.updateBlock` saves every keystroke.

The `TextEditingController` lifecycle (build from content, swap on
`data.id` change, dispose) and the per-keystroke `emitText` come from
[TextContentControllerMixin](../widgets/text_content_controller_mixin.dart),
shared with `TextSectionWidget`.

## Gotchas

- **Don't bind the controller's text to `widget.data.content` on every
  build** — that would race the per-keystroke save+notify cycle and
  thrash the caret. The mixin only resyncs when `data.id` actually changes.
- **The widget assumes it's inside a square parent** (the `BlockCard`
  in the 1×1 staggered tile). If you reuse it outside that context,
  drop the `SizedBox.expand` or it'll demand infinite height.
- **Read-only blocks truncate with no escape hatch.** Read-only past
  entries don't open the expanded route, so a 1×1 text block holding
  more than a cell's worth of text shows only the ellipsized portion
  with no way to read the rest. This is intentional — long-form
  content belongs in a text **section** (full-width, always fully
  visible). Revisit only if read-only blocks should become openable.

## When to update this file

- The text block gains structure (rich text, attachments) — that
  changes the persisted shape; update [block_content/CLAUDE.md](../../../data/model/block_content/CLAUDE.md)
  too, and either add a read-fallback in `TextBlockContent.fromMap` or
  bump the entries box name.
