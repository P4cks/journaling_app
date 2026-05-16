# lib/ui/blocks/text_section — Full-width text section widget

The widget used for `SectionKind.text` sections in the journal pager.
Renders a multi-line text region that grows with content, with no
`BlockCard` chrome — visually distinct from the 1×1 `TextBlockWidget`
that lives in block-grid sections.

## Files

- [text_section_widget.dart](text_section_widget.dart) —
  `TextSectionWidget`. Stateful (owns its `TextEditingController`,
  mounted in `initState`, swapped in `didUpdateWidget` on `data.id`
  change, disposed in `dispose`).

## Content shape

Backed by a `JournalBlockData(type: BlockType.textBlock)` — the same
`TextBlockContent` (`{"text": "..."}`) used by the 1×1 text block. This
trick lets the section reuse the existing JSON path and the
`JournalBlockEmptiness` check without introducing a new content type.
Unlike `TextBlockWidget`, text sections **do not** enforce
`BlockSettings.textCharLimit` — that cap exists to keep 1×1 tiles
visually contained, but sections are full-width and meant for
longer-form writing.

## Modes

- `BlockMode.readOnly` — plain `Text` in the same padded container.
  Empty text shows "No text yet" in italic + `disabledColor`.
- `BlockMode.editable` — `TextField` with `maxLines: null`, `minLines: 4`,
  no `expands`. Grows with content. No `maxLength` cap and no
  character counter — text sections intentionally ignore
  `BlockSettings.textCharLimit`.

## Gotchas

- **No `SizedBox.expand` / `expands: true`** — that's the `TextBlockWidget`
  recipe for filling a 1×1 cell. A text section is bounded by content,
  not the parent.
- **Same emit pattern as `TextBlockWidget`** — `onChanged` fires per
  keystroke and emits a new `JournalBlockData`. The section-aware
  journal pager funnels these through
  `MainJournalViewModel.updateBlock`, which walks the entry's sections
  to find the matching block by id.
- **Character counter uses `_controller.text.characters.length`**
  (grapheme clusters) to match `TextField.maxLength` semantics.

## When to update this file

- The text section gains structure (rich text, attachments) — bump
  the entries box if the persisted shape changes.
- The chrome diverges from `TextBlockWidget` significantly (markdown
  preview toggle, e.g.) — keep the contract with the 1×1 variant in
  sync where it matters.
