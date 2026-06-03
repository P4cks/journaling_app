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

**Both modes render the SAME `Text.rich` float-wrap for display** so
the text genuinely wraps around the block in the entry (the user's
explicit requirement). The float block is the first inline element via
`WidgetSpan(alignment: PlaceholderAlignment.top)`; the text `TextSpan`
flows to its right and wraps full-width once it passes the block's
bottom.

- **Block size = a real grid tile.** A `LayoutBuilder` (hoisted ABOVE
  the horizontal padding, so `maxWidth` is the full section width)
  computes `_gridTileSize(maxWidth) = ((maxWidth - 44) / 2).clamp(120,
  220)` — the same width one tile occupies in a 2-column `BlockGrid`
  (16px left + 16px right padding + 12px inter-column spacing, ÷2).
  Don't reintroduce the old `* 0.42` proportional size; it did NOT
  match a grid tile.
- `BlockMode.readOnly` — the float-wrap is inert. Empty text shows
  "No text yet" italic + `disabledColor`. `floatBlock == null` →
  plain padded `Text`.
- `BlockMode.editable` — same float-wrap for display, but the whole
  padded `Text.rich` is wrapped in a
  `GestureDetector(behavior: HitTestBehavior.translucent, onTap:)`
  that calls `onRequestTextSectionEdit(textBlock)` → opens the
  expanded editor route (an editable `TextField` **can't** live inside
  a `WidgetSpan`, so editing is delegated, not inline). The float
  block sits deeper in the gesture arena (its own `GestureDetector`
  inside `BlockWidget` wins for taps on it), so the translucent tap
  only fires for the surrounding text. Empty text shows a "Tap to
  write…" italic hint. `floatBlock == null` → full-width plain `Text`
  wrapped in the same tap-to-edit `GestureDetector`.

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
- The block-size formula diverges from a grid tile, or the editable
  edit path stops delegating to the expanded route.
