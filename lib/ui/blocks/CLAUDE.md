# lib/ui/blocks — Block widgets

The reusable widget layer for journal blocks. **`BlockGrid` is the only
widget in the app that lays out blocks** — it's used by the home preview,
the fullscreen editor, *and* the layout editor (WYSIWYG). Editing
`BlockGrid` affects all three; verify all three after structural changes.

## Files

- [block_grid.dart](block_grid.dart) — `BlockGrid`. 2-column
  `StaggeredGrid.count` of square 1×1 tiles inside a
  `SingleChildScrollView`.

  **Drag & drop has been fully refactored to a Notion-style system:**
  - The grid layout is **never mutated during drag** (no ghost tiles, no reflow).
  - A single full-area `DragTarget` handles pointer tracking.
  - The drop position is visualised via an **overlay insertion line**.
  - The dragged tile remains in place but is rendered with reduced opacity.

  Props:
  - `blocks`, `mode` (`BlockMode.readOnly` | `BlockMode.editable`),
    `onBlockChanged` (per-block edit callback),
  - `cardTrailing(block, index)` — optional builder for the top-right affordance,
  - `onReorder(from, to)` — enables long-press drag & drop (Notion-style),
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
  with `label`, `icon` (Phosphor duotone), `description`, and `sampleData(id:)`.

- [text_block/text_block_widget.dart](text_block/text_block_widget.dart)
- [mood_tracker/mood_tracker_widget.dart](mood_tracker/mood_tracker_widget.dart)
- [weather_manual/weather_manual_widget.dart](weather_manual/weather_manual_widget.dart)
- [prompt_block/prompt_block_widget.dart](prompt_block/prompt_block_widget.dart)

---

## Drag-and-drop (BlockGrid) — how it works

This is now a **stable-layout, overlay-driven reorder system** (similar to Notion).

### Core design principles

- **No grid mutation during drag**
  - Tiles are never inserted/removed/reordered while dragging.
  - Eliminates layout thrash, index drift, and staggered-grid edge cases.

- **Single global DragTarget**
  - The entire grid is wrapped in one `DragTarget`.
  - `onMove` receives pointer updates across the full area.

- **Overlay rendering**
  - A `CustomPainter` draws an insertion line between tiles.
  - Rendered in a `Stack`, so it does not affect layout.

- **Source tile remains in place**
  - Rendered with `Opacity(0.35)` while dragging.
  - Floating preview comes from `LongPressDraggable.feedback`.

---

### Key state in `_BlockGridState`

- `_draggingIndex`
  - Index of the tile being dragged.

- `_insertionIndex`
  - Logical drop position (`0 … blocks.length`)
  - Continuously updated from pointer position.

- `_tileKeys`
  - One `GlobalKey` per tile for layout measurement.

- `_gridKey`
  - Reference box for coordinate conversion.

---

### Insertion index algorithm

1. Convert pointer to grid-local coordinates.
2. Find row closest in Y.
3. Within that row, find nearest tile in X.
4. Insert:
   - Left half → before
   - Right half → after

---

### Insertion line rendering

- Computed via `_insertionLineInfo()`
- Drawn using `_InsertionLinePainter`
- Rules:
  - Between tiles → vertical line
  - Start of row → left edge
  - End → right of last tile
- Includes circular end caps

---

### Drag lifecycle

- `onDragStarted` → sets `_draggingIndex`
- `onMove` → updates `_insertionIndex`
- `onAccept` → calls `onReorder`
- `onDragEnd` → clears state

---

### Reorder semantics

Insertion-based:

```dart
final to = insertAt > from ? insertAt - 1 : insertAt;
