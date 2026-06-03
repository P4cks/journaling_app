# lib/ui/blocks/block_text_section — Block + text body section

The widget for `SectionKind.blockTextBody` sections (GUS-9, PRO): a
photo/memory block floated top-left with text wrapping to its right and
then full-width beneath it — the magazine `float: left` look.

## Files

- [block_text_section_widget.dart](block_text_section_widget.dart) —
  `BlockTextSectionWidget` (stateless). Composes an existing
  `BlockWidget` (the float block) and `TextSectionWidget` (the text).

## Content shape

The `EntrySection` carries **two** blocks:
- a **float block** — a `photoBlock` or `memoryBlock` (or none), the
  same single-slot machinery as `featureBlock`. Stored in the layout
  template (0 or 1 `BlockTemplate`).
- a **text block** — a `textBlock` reusing `TextBlockContent`,
  materialized fresh + empty (like a `text` section).

The widget receives the two blocks **separately** (`floatBlock`
nullable, `textBlock` required); the journal pager looks each up by
type, so their order inside `EntrySection.blocks` is irrelevant.

## Modes

- `BlockMode.readOnly` — the float-wrap. A `LayoutBuilder` sizes the
  float block to a square (~42% of width, clamped 120–200), wrapped in
  a `WidgetSpan(alignment: PlaceholderAlignment.top)` as the first
  inline element of a `Text.rich`; the text `TextSpan` flows to its
  right and wraps full-width once it passes the block's bottom. Empty
  text shows "No text yet" italic + `disabledColor`. When `floatBlock`
  is null, falls back to a plain padded `Text` (like a text section).
- `BlockMode.editable` — the float-wrap is **not** used. The float
  block renders as a left-aligned square (~50% width, clamped 140–220),
  still tappable to configure (double-tap → `onRequestBlockEdit`),
  above a full-width `TextSectionWidget` (its own in-place/expanded
  edit path via `onRequestTextSectionEdit` + `textEditing`). This
  mirrors how text sections separate edit (field) from display.

The float block subtree mirrors the journal pager's `featureBlock`
case: `Hero(tag: blockHeroTag(block.id))` → `Material` →
`BlockChrome(visuals:)` → `BlockWidget`, with `onChanged` /
`onJumpToDate` / `onInteractionLockChanged` / `onDoubleTap` wired the
same way (double-tap only when editable && `usesEditMode`).

## Gotchas

- **`Text.rich` float-wrap needs a fixed-size `WidgetSpan` child** —
  hence the `LayoutBuilder` + `SizedBox`. A fractional/unbounded child
  can't be inline-laid-out and throws. `BlockChrome`'s `FittedBox`
  scales the block content to whatever square we hand it.
- **The text block is not an editor slot.** It's materialized fresh by
  `JournalRepository.materializeLayout`; only the float block lives in
  `SectionDraft.slots` / the layout template. Don't try to round-trip
  the text through the layout.

## When to update this file

- The float arrangement changes (e.g. float-right option, configurable
  block size).
- The editable layout diverges from "block stacked above field".
