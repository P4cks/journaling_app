# lib/ui/blocks — Block widgets

The reusable widget layer for journal blocks. **`BlockGrid` lays out
1×1 blocks in a 2-column staggered grid.** It's used by the main
journal screen's swipe pager (inside each section of an entry) and
by the layout editor (WYSIWYG). Editing `BlockGrid` affects both
surfaces; verify both after structural changes.

Full-width text content lives in its own widget — [text_section/](text_section/)
— used by the section-aware journal pager for `SectionKind.text`
sections and stylistically distinct from the `text_block` 1×1 tile
that lives in block-grid sections.

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
  - `padding` (default 16),
  - `onJumpToDate(date)` — forwarded to the memory block.
  - `onInteractionLockChanged(blockId, locked)` — forwarded to blocks
    with horizontal carousels (mood, manual weather). `JournalPager`
    wires this through to disable its outer horizontal swipe while
    any inner carousel is expanded, so nested `PageView`s don't fight
    over the drag.
  - `scrollable` (default `true`) — when `true` the grid wraps its
    `StaggeredGrid` in a `SingleChildScrollView` (legacy behavior,
    suitable when `BlockGrid` is the body of a screen). When `false`
    the grid sizes itself to its content with no inner scroll view so
    it can be embedded inside an outer scrolling parent — used by the
    section-aware journal pager (`SectionKind.blockGrid` sections)
    and by the custom-layout editor (stacking multiple block-grid
    sections). Cross-grid drag is NOT supported — each grid's
    `DragTarget` is isolated.

- [post_it_block.dart](post_it_block.dart) — `PostItBlock`. The square
  chrome for one block. Replaces the old `BlockCard` and adds the
  playful post-it look layered on top of it:
  - **Outer transforms** (visual only — RenderBox stays axis-aligned,
    so insertion-index math in `BlockGrid` is unaffected):
    `Transform.translate(visuals.offset)` →
    `Transform.rotate(visuals.rotationDeg * π/180)` →
    `AnimatedScale(isDragging ? 1.03 : 1.0)`.
  - **Decoration**: rounded `Container` (radius 16, 14 in classic
    mode) with `color = colorFromHex(visuals.colorHex) ?? scheme.surfaceContainerHigh`
    and an `AnimatedContainer`-tweened `BoxShadow` that grows in
    blur + alpha when `isDragging`. **Plain `Container`, not
    `Material(elevation: N)`** — Material elevation in M3 dark themes
    is mostly tint and doesn't read against dimmed surfaces. Don't
    "simplify" back to elevation.
  - **Foreground propagation**: `DefaultTextStyle.merge` +
    `IconTheme.merge` wrap children with `contrastOn(bg)` so emoji /
    icons / text stay legible on whatever palette color the block
    drew.
  - **Classic mode**: reads `themeSettings.postItModeEnabled` (via
    `AppDependencies.of(context)`). When `false`, all transforms
    short-circuit to identity, color falls back to
    `surfaceContainerHigh`, and the corner radius reverts to 14 —
    visually identical to the pre-post-it `BlockCard`.

- [block_widget.dart](block_widget.dart) — `BlockWidget`. Dispatches on
  `data.type` and constructs the per-type widget. Adding a new
  `BlockType` requires adding a `case` here.

- [block_mode.dart](block_mode.dart) — `enum BlockMode { readOnly, editable }`.
  Concrete block widgets render differently per mode.

- [block_type_display.dart](block_type_display.dart) — `extension BlockTypeDisplay on BlockType`
  with `label`, `icon` (Phosphor duotone), `description`, and `sampleData(id:)`.

- [widgets/collapsible_carousel_block.dart](widgets/collapsible_carousel_block.dart) —
  `CollapsibleCarouselBlock<T>`. Generic tap-to-expand / auto-collapse
  carousel shared between the mood and manual-weather blocks. See
  [widgets/CLAUDE.md](widgets/CLAUDE.md).
- [text_block/text_block_widget.dart](text_block/text_block_widget.dart)
- [mood_tracker/mood_tracker_widget.dart](mood_tracker/mood_tracker_widget.dart)
- [weather_manual/weather_manual_widget.dart](weather_manual/weather_manual_widget.dart)
- [location_block/location_block_widget.dart](location_block/location_block_widget.dart) —
  `LocationBlockWidget`. flutter_map + OSM tiles; long-press drops a pin.
  See [location_block/CLAUDE.md](location_block/CLAUDE.md).
- [prompt_block/prompt_block_widget.dart](prompt_block/prompt_block_widget.dart)
- [todo_block/todo_block_widget.dart](todo_block/todo_block_widget.dart)
- [quote_block/quote_block_widget.dart](quote_block/quote_block_widget.dart)
- [memory_block/memory_block_widget.dart](memory_block/memory_block_widget.dart)
- [weather_api/weather_api_widget.dart](weather_api/weather_api_widget.dart)
- [photo_block/photo_block_widget.dart](photo_block/photo_block_widget.dart)
- [custom_carousel/custom_carousel_widget.dart](custom_carousel/custom_carousel_widget.dart) —
  `CustomCarouselWidget`. Resolves `definitionId` against the
  `BlockSettings` registry; renders the definition's title + a
  `CollapsibleCarouselBlock<CarouselItem>` over its items, or a
  "Deleted block" placeholder when the lookup fails. See
  [custom_carousel/CLAUDE.md](custom_carousel/CLAUDE.md).

---

## Motion on top of drag-and-drop (post-it era)

Layered on the stable-layout drag system below — none of these
animations affect the grid's RenderBoxes or insertion-index math:

- **Drag**: the source tile's `PostItBlock` receives `isDragging:
  true` while its index matches `_draggingIndex`. That triggers the
  `AnimatedScale` to 1.03 and the `AnimatedContainer` to grow the
  shadow (blur 14 → 24, alpha ×1.6). The `LongPressDraggable.feedback`
  is also a `PostItBlock` with `isDragging: true` for the same look
  on the floating preview.
- **Add**: each tile is wrapped in `flutter_animate`'s `Animate(...)`
  with a fade + back-easing scale, keyed by `ValueKey('animate-${block.id}')`.
  Effects only run on first mount, so re-orders don't replay them.
  Skipped when `postItModeEnabled` is false (classic mode stays
  still).
- **Delete**: when `didUpdateWidget` notices a block id has gone
  missing, the tile's last-known `Rect` is snapshotted into a
  `_PendingDelete` and rendered as an overlay ghost above the grid.
  The ghost runs `fade → 0` + `scale → 0.7` + `move y +16` (plus a
  small `rotate` when post-it mode is on) for ~320 ms, then removes
  itself in `Animate.onComplete`.
- **Swap (post-drop) is intentionally not animated.** Re-animating
  swapped tiles requires either remounting (loses TextField focus)
  or per-tile `AnimationController` plumbing keyed by block id —
  both have cross-cutting cost. The drop visual is the insertion
  line + the smooth shadow snap from `isDragging: false`; revisit
  if the result feels too abrupt.

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
```

---

## Keyboard dismissal — modal edit mode

While a TextField is focused (any block, or the title) the parent
screen enters a "modal editing" state managed by `MainJournalScreen`:

- The screen tracks `_editing` via `WidgetsBindingObserver.didChangeMetrics`
  (reading `platformDispatcher.views.first.viewInsets.bottom > 0`).
  **`MediaQuery.viewInsetsOf(context)` inside the Scaffold body
  returns zero** because Scaffold's `resizeToAvoidBottomInset`
  consumes the bottom insets before they reach descendants —
  detecting via the platform dispatcher is the workaround.
- When `_editing == true`:
  - The AppBar's `actions` collapse to a single `Done` `TextButton`
    that calls `FocusManager.instance.primaryFocus?.unfocus()` — the
    Statistics / Change-layout / Profile actions are removed.
  - `JournalPager.externalLock = true` swaps the `PageView` physics
    to `NeverScrollableScrollPhysics`, so horizontal swipe to adjacent
    entries is disabled.
  - The body-level `GestureDetector(unfocus)` is disabled (onTap:
    null) — the only way out of edit mode is to tap Done.
- When `_editing == false`, all of the above revert to normal.

This applies symmetrically to title edits and block edits — both
raise the keyboard and trigger the same flag. The return key on the
keyboard still inserts newlines in multi-line block TextFields.

AppBar actions (Statistics, ProfileMenuButton, Change-layout) also
call `FocusManager.instance.primaryFocus?.unfocus()` before
navigating AND once more on return — defending against Flutter's
automatic focus restoration when the previously-focused TextField
becomes visible again on pop. In the modal edit state these actions
aren't reachable anyway (they're replaced by Done), but the unfocus
calls remain in place for the non-editing flow.

