# lib/ui/blocks/block_text_section — Block + text body section

The widget for `SectionKind.blockTextBody` sections (GUS-9, PRO): a
photo/memory block floated top-left with text wrapping to its right and
then full-width beneath it — the magazine `float: left` look.

## Files

- [block_text_section_widget.dart](block_text_section_widget.dart) —
  `BlockTextSectionWidget` (StatelessWidget). Composes a `BlockWidget`
  (the float block) with measured wrapping text; editing is delegated
  to the expanded route.

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

## Display — the multi-line float

The text genuinely wraps around the block over **multiple** lines, then
flows full-width beneath it. This is done by **measuring**, NOT by a
`Text.rich` `WidgetSpan`:

- A `LayoutBuilder` (hoisted ABOVE the horizontal padding, so
  `maxWidth` is the full section width) computes `blockSize =
  _gridTileSize(maxWidth) = ((maxWidth - 44) / 2).clamp(120, 220)` —
  the width one tile occupies in a 2-column `BlockGrid` (16px left +
  16px right padding + 12px inter-column spacing, ÷2). Don't
  reintroduce the old `* 0.42` proportional size; it did NOT match a
  grid tile.
- `_buildFloatWrap` lays the text out with a `TextPainter` at the
  **narrow beside-width** (`contentWidth - blockSize - 12`) and walks
  `painter.computeLineMetrics()`, accumulating each line's height, to
  find the first line whose **top** is `>= blockSize` (the block's own
  height; `_bottomGap` is padding *below* the block and deliberately
  excluded). That line — and everything after it — flows full-width
  below; the lines before it stay beside the block. The split character
  offset is read via `getPositionForOffset(Offset(0, lineTop +
  height/2))`; because `x == 0` it snaps to the **start of that line**,
  so the split lands on a clean line boundary. The text is then split:
  - `beside` → rendered in a `Row` next to the block (`Expanded` text).
  - `below` → rendered full-width underneath the `Row`.
  - **Why walk line metrics instead of one `getPositionForOffset(
    Offset(0, blockSize))`?** (GUS-43, two rounds.) That single call
    returns the line *containing* `y = blockSize`. A line whose top is
    still beside the block but whose bottom dips past it (e.g. top
    140 px, block 150 px) gets pushed into the below region — wasting
    the space to its right. That was the reported bug ("the last line
    is always rendered underneath the block even if there's still space
    to the right"). Tweaking the offset (`blockSize` vs `blockSize +
    _bottomGap`) doesn't help: both land *inside* that straddling line.
    The line-metrics walk splits on the first line whose **top** clears
    the block, keeping the straddling line beside. Don't collapse it
    back to a single `getPositionForOffset`.
- Guard: when `besideWidth < 48` (block ≈ as wide as the section, e.g.
  a very narrow viewport) it falls back to stacking the block above
  full-width text instead of cramming text into a sliver.

**Why not `WidgetSpan`?** Flutter's `WidgetSpan(alignment:
PlaceholderAlignment.top)` only wraps text beside the block on the
**first** line — every subsequent line drops to `x = 0` *under* the
block even when there's room to its right. That was the user-visible
bug this widget originally shipped with ("the next line is directly
positioned underneath the block while there is still enough space to
the right"). The measure-and-split approach is the fix; do not revert
to a single `Text.rich` float.

## Modes & editing

- `BlockMode.readOnly` — the float-wrap is inert. Empty text shows
  "No text yet" italic + `disabledColor`. `floatBlock == null` →
  plain padded `Text`.
- `BlockMode.editable` — a tap on the text opens the **expanded
  route** for editing. The display (float-wrap, or full-width `Text`
  when `floatBlock == null`) is wrapped in a `GestureDetector(behavior:
  translucent, onTap: → onRequestTextSectionEdit)`. The float block
  sits deeper in the gesture arena (its own `GestureDetector` inside
  `BlockWidget`), so the translucent tap only fires for the surrounding
  text — taps on the block engage it (double-tap → `onRequestBlockEdit`).

  **Why delegate instead of editing in place?** A `TextField` can't
  flow around the inline block, so an in-place editor has to drop the
  wrap. The only stable layout (block-left + narrow field-right) then
  reflows the text awkwardly when the field loses focus and the
  display re-wraps it under the block. Sending the tap straight to the
  expanded route gives the text the full width and avoids that reflow
  surprise — this was a deliberate call after trying the inline editor.

The float block subtree mirrors the journal pager's `featureBlock`
case: `Hero(tag: blockHeroTag(block.id))` → `Material` →
`BlockChrome(visuals:)` → `BlockWidget`, with `onChanged` /
`onJumpToDate` / `onInteractionLockChanged` / `onDoubleTap` wired the
same way (double-tap only when editable && `usesEditMode`).

## Gotchas

- **The split is line-aligned via `getPositionForOffset(Offset(0,
  …))`.** Using a non-zero `x` would snap to the *end* of the line at
  that height and could split mid-line, leaving a ragged seam between
  the beside text and the below text. Keep `x == 0`.
- **The beside/below boundary is chosen by walking
  `computeLineMetrics()`, not by a single `getPositionForOffset(
  Offset(0, blockSize))`.** The single call returns the line
  *containing* `blockSize` and pushes a line whose top is still beside
  the block into the below region (GUS-43 bug: last beside line dropped
  underneath despite room to its right). Split on the first line whose
  **top** is `>= blockSize`. Don't "simplify" it back to one
  `getPositionForOffset` call.
- **Editing is delegated, not in place.** A `TextField` can't flow
  around the inline block, and the stable in-place layout (block-left +
  narrow field-right) reflows the text on blur. So the widget is
  stateless and a tap just calls `onRequestTextSectionEdit` → expanded
  route. There is no `editingBlockId`/`textEditing` flag (the pager no
  longer passes one). If you re-add an inline editor, you must solve the
  on-blur reflow first.
- **The text block is not an editor slot.** It's materialized fresh by
  `JournalRepository.materializeLayout`; only the float block lives in
  `SectionDraft.slots` / the layout template. Don't try to round-trip
  the text through the layout.

## When to update this file

- The float arrangement changes (e.g. float-right option, configurable
  block size), or the measure/split heuristic changes.
- The block-size formula diverges from a grid tile.
- The edit affordance changes (e.g. inline editing is reintroduced once
  the wrap/reflow problem is solved).
