# lib/ui/blocks/block_text_section — Block + text body section

The widget for `SectionKind.blockTextBody` sections (GUS-9, PRO): a
photo/memory block floated top-left with text wrapping to its right and
then full-width beneath it — the magazine `float: left` look.

## Files

- [block_text_section_widget.dart](block_text_section_widget.dart) —
  `BlockTextSectionWidget` (StatefulWidget, uses
  `TextContentControllerMixin`). Composes a `BlockWidget` (the float
  block) with measured wrapping text + an inline editor.

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
  **narrow beside-width** (`contentWidth - blockSize - 12`) and calls
  `getPositionForOffset(Offset(0, blockSize + 8))` to find the
  character offset where the text passes the block's bottom. Because
  `x == 0`, that offset always snaps to the **start of a line**, so the
  split lands on a clean line boundary. The text is then split:
  - `beside` → rendered in a `Row` next to the block (`Expanded` text).
  - `below` → rendered full-width underneath the `Row`.
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
- `BlockMode.editable` — single tap edits **in place**, double tap
  opens the expanded route. This matches every other block:
  - The display (float-wrap, or full-width `Text` when `floatBlock ==
    null`) is wrapped in a `GestureDetector(behavior: translucent,
    onTap: _enterEdit, onDoubleTap: → onRequestTextSectionEdit)`. The
    float block sits deeper in the gesture arena (its own
    `GestureDetector` inside `BlockWidget`), so the translucent tap
    only fires for the surrounding text. The `GestureDetector` with
    both `onTap`+`onDoubleTap` is what delays the single tap by the
    double-tap timeout, so a double tap doesn't first flash the
    keyboard.
  - `_enterEdit` flips a local `_editing` flag → the build swaps to
    `_buildEditor`, an `autofocus: true` `TextField` (block stays
    floated-left, the field fills the column to its right; no jump). A
    `TextField` **can't** flow around an inline block, so editing
    intentionally does NOT wrap — it returns to the wrapping display on
    blur.
  - A `focusNode` listener flips `_editing` back to false when the
    field loses focus (Done / tap-outside), so the float-wrap display
    (which reflows text under the block) reappears.

The controller / focus / per-keystroke emit come from
`TextContentControllerMixin` (shared with the 1×1 text block and the
full-width text section). The char cap + visible counter come from
`BlockInputLimits.of(debug).textSectionChars` + `buildCharCounter()`,
the same as `TextSectionWidget`.

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
- **Editing replaces the wrap, it doesn't wrap.** A `TextField` can't
  live in a float, so the in-place editor is a block-left + field-right
  `Row`. The block keeps its grid-tile size/position so there's no jump
  between display and edit.
- **`autofocus: true` is what raises the keyboard on single tap.** The
  editor `TextField` is only mounted while `_editing` is true; it
  autofocuses on mount. Don't drive focus through the mixin's `editing`
  override here — this widget owns `_editing` locally instead of taking
  an external `editingBlockId`/`textEditing` flag (the pager no longer
  passes one).
- **The text block is not an editor slot.** It's materialized fresh by
  `JournalRepository.materializeLayout`; only the float block lives in
  `SectionDraft.slots` / the layout template. Don't try to round-trip
  the text through the layout.

## When to update this file

- The float arrangement changes (e.g. float-right option, configurable
  block size), or the measure/split heuristic changes.
- The block-size formula diverges from a grid tile.
- The edit affordance changes (e.g. inline editing learns to wrap, or
  reverts to delegating to the expanded route).
