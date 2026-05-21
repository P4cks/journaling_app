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

  with `label`, `icon` (HugeIcons stroke-rounded; typed `HugeIconData`), `description`, and `sampleData(id:)`.
  Also exposes two getters used by the double-tap edit-mode flow:
  - `usesEditMode` — true for blocks that participate in the new
    flow (text, prompt, todo, mood, weather-manual, customCarousel).
    Action blocks (photo, location, memory) and display blocks
    (quote, weather-api) return false; the grid does NOT attach the
    double-tap detector for those tiles and they keep their existing
    single-tap behavior.
  - `usesKeyboardOnEdit` — true for text / prompt / todo so the
    expanded route can choose a top-aligned placement (keyboard
    fits below) instead of centered.


- [widgets/collapsible_carousel_block.dart](widgets/collapsible_carousel_block.dart) —
  `CollapsibleCarouselBlock<T>`. Generic auto-expand / auto-collapse
  carousel shared between the mood and manual-weather blocks. Now
  driven by an external `editing` flag (the new double-tap-to-edit
  flow); internal tap-to-expand is gated on `editing == true`. See
  [widgets/CLAUDE.md](widgets/CLAUDE.md).
- [expanded/expanded_block_route.dart](expanded/expanded_block_route.dart) —
  `ExpandedBlockRoute` + private `_ExpandedBlockBody`. Translucent
  `PageRoute<void>` (`opaque: false`) that paints the previous route
  blurred under a `BackdropFilter` and renders the block expanded in
  the foreground. Keyboard-using blocks (text / prompt / todo) sit
  top-aligned so the keyboard fits below; other editable blocks sit
  centered. Tapping the backdrop pops the route; a debug toggle adds
  a "Done" button. See "Edit mode (double-tap)" below.
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
- **Tap wiggle**: *currently disabled.* The damped ±3° rotation that
  used to fire on every `onPointerDown` is preserved as commented-out
  scaffolding inside `_PostItBlockState` (see [post_it_block.dart](post_it_block.dart)).
  It was acting as edit-affordance feedback that no longer fits the
  new double-tap-to-edit model (a wiggle on every single tap implied
  "you tapped but nothing happened"). May be reinstated later — the
  comment block in `_PostItBlockState` lists the revival steps.
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

## Edit mode (double-tap)

Editing an editable block (text / prompt / todo / mood / weather /
customCarousel) takes a **double-tap** on the tile. Single-taps are
inert. Long-press still triggers reorder via `LongPressDraggable`,
independent of edit mode.

### State model

- `String? editingBlockId` lives on `_MainJournalScreenState` and is
  threaded through `JournalPager → _SectionsBody → BlockGrid →
  BlockWidget → concrete block`. Exactly one block can be in in-place
  edit mode at a time.
- The screen's existing `_editing` keyboard-visibility flag is
  unchanged — it still drives the AppBar's Done collapse and the
  pager's outer lock. The two flags coexist:
  - `_editingBlockId != null` means "this tile is the active in-place
    editor" — affordance is the scale + outline on `PostItBlock`.
  - `_editing == true` means "the keyboard is up". For text / prompt /
    todo blocks both are true while typing; for mood / weather only
    `_editingBlockId` is set.

### Double-tap dispatch

1. `BlockGrid._buildTile` wraps each editable tile in
   `GestureDetector(onDoubleTap: ...)` with
   `behavior: HitTestBehavior.translucent`. The detector is only
   attached for block types where `BlockTypeDisplay.usesEditMode` is
   true AND only while the tile is NOT the active editor — once
   editing, single taps inside the TextField should not wait for the
   double-tap timeout.
2. Text sections in `_SectionsBody` get an analogous detector wired
   to `onRequestTextSectionEdit` (separate callback from grid blocks
   so the screen can set `isTextSection: true` on the route push).
3. The screen's `_requestBlockEdit(block, {isTextSection})` dispatches
   based on `DebugSettings.expandBlockOnEdit`:
   - **ON** (default) → `Navigator.push(ExpandedBlockRoute(...))`.
     `_editingBlockId` stays null; the route owns the edit state.
   - **OFF** → `setState(() => _editingBlockId = block.id)`.

### Inert single-tap inside editable blocks

Concrete editable widgets (`TextBlockWidget`, `TextSectionWidget`,
`PromptBlockWidget`, `TodoBlockWidget`) wrap their interactive
sub-widgets in `AbsorbPointer(absorbing: !editing)`. While not
editing, single-taps that reach the inner widget are swallowed —
the TextField doesn't auto-focus, the carousel doesn't expand.
`CollapsibleCarouselBlock` similarly gates its internal
tap-to-expand on `editing == true`.

### Focusing on activation

`TextContentControllerMixin` (shared by `TextBlockWidget` /
`TextSectionWidget`) owns the `FocusNode`. When subclasses forward
`widget.editing` via the `editing` override, the mixin requests focus
in `didUpdateWidget` whenever the flag flips from false to true
(post-framed to avoid the in-build setState). Same pattern lives
inline in `PromptBlockWidget`. `TodoBlockWidget` doesn't auto-focus
a specific row — the AbsorbPointer drop is enough for the user to tap
the row they want to edit.

### The expanded route

`ExpandedBlockRoute` is a translucent `PageRoute<void>` (`opaque: false`)
that lets the previous route paint through. The body is a Stack of:
1. `BackdropFilter(ImageFilter.blur(σ ≈ 12 * t))` over a tinted color
   layer — t is the route animation value so the blur eases in.
2. A full-screen `GestureDetector(onTap: maybePop)` for the
   tap-outside-to-dismiss affordance. Saves are per-keystroke so a
   dismiss never loses content.
3. The expanded block: `PostItBlock(isEditing: true)` around a
   `BlockWidget(editing: true)`. Keyboard-using blocks sit
   top-aligned with a status-bar inset; others are centered. A no-op
   GestureDetector wraps the block so backdrop taps don't fire for
   gestures on it.
4. Optional "Done" button — only shown when
   `DebugSettings.showExpandedBlockDoneButton` is true (developer
   affordance; tap-outside is the user-facing dismissal).

The route is dismissed by tapping the backdrop, pressing the system
back button, or — in debug mode — the Done button. No Hero animation
is used; the route fades + scales in via the route animation value
read inside the body's `AnimatedBuilder`.

### In-place edit affordance (setting OFF)

`PostItBlock.isEditing` triggers:
- An `AnimatedScale` to 1.05 (composes with drag scale at 1.03 — drag
  wins via the `widget.isDragging ? 1.03 : (widget.isEditing ? 1.05 : 1.0)`
  cascade).
- A 2 px border in `colorScheme.primary` on the card's
  `AnimatedContainer` decoration. Animates in over 180 ms.

`TextSectionWidget` applies its own 2 px primary-color border via an
inner `AnimatedContainer` because it has no `PostItBlock` chrome.

### Action blocks (photo / location / memory)

These keep their existing single-tap behavior. They opt out of the new
flow via `BlockTypeDisplay.usesEditMode == false`. Routing them
through double-tap is a possible follow-up but adds plumbing for
"immediately fire action + exit edit mode" semantics that's out of
scope for this iteration.

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

