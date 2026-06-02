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
  square cell. **Required field config**:
  - `expands: true`
  - `maxLines: null`
  - `minLines: null`
  - `scrollPhysics: NeverScrollableScrollPhysics()`
  - inside a `SizedBox.expand`
  The field is capped at `BlockInputLimits.of(debug).textBlockChars`
  (default `kTextBlockMaxChars` = 280, debug-overridable) with a
  **visible** `current/limit` counter via `buildCharCounter()`
  ([../widgets/block_input_limits.dart](../widgets/block_input_limits.dart)).
  The editable subtree is wrapped in
  `ListenableBuilder(listenable: debugSettings)` so debug tuning
  updates the cap live. Without `expands` /
  `maxLines: null` the field tries to grow with
  content and blows out the 1×1 cell. The `NeverScrollableScrollPhysics`
  disables the TextField's internal scroll so the block doesn't
  scroll within its cell — overflow content is clipped by the
  chrome's `clipBehavior: Clip.antiAlias`. Data is preserved (the
  controller's full text persists); only the visual presentation is
  bounded. The hint is "Write something…".
  `onChanged` fires per keystroke and emits a new `JournalBlockData`
  via the parent's `onBlockChanged` callback — `JournalEntryEditorViewModel.updateBlock`
  saves every keystroke.

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

## When to update this file

- The text block gains structure (rich text, attachments) — that
  changes the persisted shape; update [block_content/CLAUDE.md](../../../data/model/block_content/CLAUDE.md)
  too, and either add a read-fallback in `TextBlockContent.fromMap` or
  bump the entries box name.
