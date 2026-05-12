# lib/ui/blocks — Block widgets

The reusable widget layer for journal blocks. **`BlockGrid` is the only
widget in the app that lays out blocks** — it's used by the home preview,
the fullscreen editor, *and* the layout editor (WYSIWYG). Editing
`BlockGrid` affects all three; verify all three after structural changes.

## Files

- [block_grid.dart](block_grid.dart) — `BlockGrid`. 2-column
  `StaggeredGrid.count` of square 1×1 tiles inside a `SingleChildScrollView`.
  Props:
  - `blocks`, `mode` (`BlockMode.readOnly` | `BlockMode.editable`),
    `onBlockChanged` (per-block edit callback),
  - `cardTrailing(block, index)` — optional builder for the top-right
    affordance on each card (e.g. the remove-X in the layout editor),
  - `onReorder(from, to)` — when non-null, enables long-press DnD with
    ghost-preview at the drop position and a trailing "drop at end"
    target,
  - `padding` (default 16).
- [block_card.dart](block_card.dart) — `BlockCard`. The square chrome
  for one block: rounded `Container` on `scheme.surfaceContainerHigh`
  with an explicit `BoxShadow` (alpha 0.55 dark / 0.18 light, 14px blur,
  +4 Y offset). **Plain `Container`, not `Material(elevation: N)`** —
  Material elevation in M3 dark themes is mostly tint, which doesn't
  read against dimmed surfaces. Don't "simplify" back to elevation.
- [block_widget.dart](block_widget.dart) — `BlockWidget`. Dispatches on
  `data.type` and constructs the per-type widget. Adding a new
  `BlockType` requires adding a `case` here.
- [block_mode.dart](block_mode.dart) — `enum BlockMode { readOnly, editable }`.
  Concrete block widgets render differently per mode.
- [block_type_display.dart](block_type_display.dart) — `extension BlockTypeDisplay on BlockType`
  with `label` and `icon` (Phosphor duotone). Used by the add-block
  sheet and the DnD feedback chip. Add a case here for each new block
  type.
- [text_block/text_block_widget.dart](text_block/text_block_widget.dart) — see [text_block/CLAUDE.md](text_block/CLAUDE.md).
- [mood_tracker/mood_tracker_widget.dart](mood_tracker/mood_tracker_widget.dart) — see [mood_tracker/CLAUDE.md](mood_tracker/CLAUDE.md).

## Drag-and-drop (BlockGrid) — how it works

Insertion-based reorder: the user long-presses a tile, drags, and the
**ghost tile renders at the slot the dropped tile would land in** (not
the position currently being hovered). On accept, the source tile moves
*before* the hovered tile (insert-before semantics).

Key state in `_BlockGridState`:
- `_draggingSourceIndex` — index of the tile currently being dragged.
  While set, the source tile is **removed from the grid** entirely so
  the remaining tiles re-flow naturally. The drag continues in the
  `Overlay`; the source widget can be unmounted safely.
- `_hoveringTargetIndex` — index where the ghost should render. Range:
  `0..blocks.length` (inclusive — `blocks.length` means "drop at end",
  handled by a separate trailing `DragTarget`).
- `_isNoop(from, to)` — `from == to || from + 1 == to`. A drop on the
  source tile or immediately after it is a no-op; we both reject in
  `onWillAcceptWithDetails` and guard hover-state so the ghost never
  flashes in an invalid position.

The `LongPressDraggable.feedback` is a chip with the block's icon +
label (not a tile clone) — keeps the cursor follower lightweight.

## Gotchas

These are real bugs that were fixed during DnD bring-up. **Don't
reintroduce them.**

- **`setState` during build assertion**. A freshly-mounted `DragTarget`
  inserted under the user's finger can fire `onMove` synchronously
  during the build pass. Calling `setState` from there trips an
  assert. `_safeSetState` defers via `addPostFrameCallback` when
  `schedulerPhase == SchedulerPhase.persistentCallbacks`.
- **Closure-over-variable infinite recursion** in `DragTarget.builder`.
  If you compute `content` into a local var and reassign it later, the
  builder closes over the *variable*, so it returns the new value
  (often the `DragTarget` itself) and recurses. Always capture the
  inner value in `final` before passing it into a builder. The current
  code uses `final draggable = LongPressDraggable<int>(...)` then
  returns it from the builder — preserve that shape.
- **`SingleChildScrollView` sizes to content, not parent.** If you put
  a `BlockGrid` inside a screen and the surface tint doesn't reach the
  bottom of the screen, wrap the grid in `SizedBox.expand`
  (`JournalEntryEditorScreen` already does this for the editor surface).
- **Don't replace `_buildTrailingTarget`** with a wider invisible area
  — Flutter would steal scroll/tap events from the rest of the screen.
  A 32-tall trailing strip is enough to catch drops past the last tile.

## When to update this file

- The `BlockGrid` API (its props) changes — every caller (home preview,
  editor, layout editor) needs the new prop, document it.
- A new block type is added: list its concrete widget under Files, and
  add a CLAUDE.md inside `lib/ui/blocks/<new_type>/`.
- The DnD interaction model changes (e.g. swap-based instead of
  insert-based, multi-select drag). Update the "how it works" section
  and the gotchas list.
