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
- `BlockMode.editable` — the `Text.rich` float-wrap is **not** used (an
  editable `TextField` can't live inside a `WidgetSpan`). Instead the
  float block sits in a `Row` as a left square (~42% width, clamped
  120–200, sized via a `LayoutBuilder` that **wraps the whole Row** —
  a `LayoutBuilder` placed directly as a Row child gets unbounded
  width), still tappable to configure (double-tap → `onRequestBlockEdit`),
  with the `TextSectionWidget` in an `Expanded` **to its right** (its
  own in-place/expanded edit path via `onRequestTextSectionEdit` +
  `textEditing`). The text grows vertically beside the block rather
  than wrapping under it. When `floatBlock` is null, the text is
  full-width (no Row). `TextSectionWidget`'s own 16px horizontal
  padding doubles as the gap to the block + the right margin.

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
